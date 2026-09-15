import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

// Owns the GPS and FIT session lifecycle. This is the only place that touches
// Toybox.Position or Toybox.ActivityRecording.
//
// Resolution note: 1 Hz is the ceiling for both position fixes and FIT record
// messages on Connect IQ. How many of those fixes reach the FIT file depends on
// the watch's Settings > System > Data Recording setting (Smart thins points,
// Every Second does not) and cannot be changed from here.
class TrackRecorder {
    // Values of the deprecated Position.CONSTELLATION_* enum (API 3.2.0).
    private const GNSS_GPS = 0 as Position.Constellation;
    private const GNSS_GLONASS = 1 as Position.Constellation;

    private var _session as ActivityRecording.Session?;
    private var _quality as Position.Quality = Position.QUALITY_NOT_AVAILABLE;
    private var _startedAt as Time.Moment?;
    private var _motion as MotionFilter = new MotionFilter();
    private var _lastFixMs as Number?;

    function initialize() {
    }

    // Turn on the GPS and begin recording.
    //
    // The countdown is the point of the app, so a GPS or recording failure must
    // never stop it opening: exceptions are caught and the GPS dot simply stays
    // red. Only Lang exceptions can be caught in Monkey C - a missing symbol
    // crashes the app outright - so every firmware-dependent API is also
    // guarded with `has`.
    function start() as Void {
        if (_session != null) {
            return;
        }

        try {
            enableGps();
        } catch (e) {
            System.println("GPS unavailable: " + e.getErrorMessage());
        }

        if (!(Toybox has :ActivityRecording)) {
            return;
        }

        var sport = Activity.SPORT_GENERIC;
        if (Activity has :SPORT_SAILING) {
            sport = Activity.SPORT_SAILING;
        }

        try {
            var session = ActivityRecording.createSession({
                :name => WatchUi.loadResource(Rez.Strings.SessionName) as String,
                :sport => sport
            });
            session.start();
            _session = session;
            _startedAt = Time.now();
        } catch (e) {
            System.println("Recording unavailable: " + e.getErrorMessage());
            _session = null;
        }
    }

    // Request continuous fixes using the best solution the firmware offers.
    //
    // Fix rate is 1 Hz regardless - that is an API-wide ceiling, not a device
    // one - so this only affects accuracy. The 245 is single-band (L1) hardware,
    // so the multi-band and SatIQ configurations will report unsupported no
    // matter what Connect IQ version the watch runs; GPS+GLONASS is the ceiling.
    // The SDK profile for fr245m is CIQ 3.3.1 and lacks hasConfigurationSupport
    // (added in 3.3.6), but real 245 firmware can be newer, so both paths run
    // on the watch even though the simulator only ever takes the fallback.
    private function enableGps() as Void {
        var configuration = bestSupportedConfiguration();
        if (configuration != null) {
            try {
                Position.enableLocationEvents({
                    :acquisitionType => Position.LOCATION_CONTINUOUS,
                    :configuration => configuration
                }, method(:onPosition));
                return;
            } catch (e) {
                // Fall through to the older constellations API.
            }
        }

        // The Constellation enum is deprecated in favour of :configuration, but
        // it is the only multi-GNSS option on CIQ 3.3.1 firmware. Its documented
        // values are used directly so the build stays warning-free.
        try {
            if (Position has :CONSTELLATION_GLONASS) {
                Position.enableLocationEvents({
                    :acquisitionType => Position.LOCATION_CONTINUOUS,
                    :constellations => [GNSS_GPS, GNSS_GLONASS]
                }, method(:onPosition));
                return;
            }
        } catch (e) {
            // Device rejected the combination; fall through to plain GPS.
        }
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    // Best to worst. Everything above GPS+GLONASS needs hardware the 245 does
    // not have, but asking costs nothing and pays off on a better watch.
    //
    // Each constant is checked with `has` before it is touched: firmware that
    // has hasConfigurationSupport need not define every CONFIGURATION_* value,
    // and referencing a missing one is an uncatchable crash.
    private function bestSupportedConfiguration() as Position.Configuration? {
        if (!(Position has :hasConfigurationSupport)) {
            return null;
        }
        try {
            if ((Position has :CONFIGURATION_SAT_IQ)
                    && Position.hasConfigurationSupport(Position.CONFIGURATION_SAT_IQ)) {
                return Position.CONFIGURATION_SAT_IQ;
            }
            if ((Position has :CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5)
                    && Position.hasConfigurationSupport(Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5)) {
                return Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5;
            }
            if ((Position has :CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1)
                    && Position.hasConfigurationSupport(Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1)) {
                return Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1;
            }
            if ((Position has :CONFIGURATION_GPS_GLONASS)
                    && Position.hasConfigurationSupport(Position.CONFIGURATION_GPS_GLONASS)) {
                return Position.CONFIGURATION_GPS_GLONASS;
            }
            if ((Position has :CONFIGURATION_GPS_GALILEO)
                    && Position.hasConfigurationSupport(Position.CONFIGURATION_GPS_GALILEO)) {
                return Position.CONFIGURATION_GPS_GALILEO;
            }
            if ((Position has :CONFIGURATION_GPS)
                    && Position.hasConfigurationSupport(Position.CONFIGURATION_GPS)) {
                return Position.CONFIGURATION_GPS;
            }
        } catch (e) {
            // Treat a rejected query as no configuration support.
        }
        return null;
    }

    function onPosition(info as Position.Info) as Void {
        if (info.accuracy != null) {
            _quality = info.accuracy;
        }

        // SOG and COG come from the GPS chip's Doppler solution, which is far
        // steadier than differencing successive positions. Position.Info calls
        // COG "heading", but there is no compass in it.
        var sog = info.speed;
        var cog = info.heading;
        if (sog != null && cog != null) {
            var nowMs = System.getTimer();
            var lastFixMs = _lastFixMs;
            var dtSeconds = (lastFixMs == null) ? 0.0 : (nowMs - lastFixMs) / 1000.0;
            _motion.update(sog, cog, dtSeconds);
            _lastFixMs = nowMs;
        }
    }

    // Damped SOG and COG, warmed up from app start so they are settled
    // by the gun.
    function getMotion() as MotionFilter {
        return _motion;
    }

    // A Position.QUALITY_* value. Only four buckets are available; there is no
    // numeric HDOP or EPE on Connect IQ.
    function getQuality() as Position.Quality {
        return _quality;
    }

    function getElapsedSeconds() as Number {
        var startedAt = _startedAt;
        return (startedAt == null) ? 0 : Time.now().compare(startedAt);
    }

    // Distance covered according to the FIT recorder, or null before it knows.
    function getDistanceMeters() as Float? {
        var info = Activity.getActivityInfo();
        return (info == null) ? null : info.elapsedDistance;
    }

    function isRecording() as Boolean {
        return (_session != null) && _session.isRecording();
    }

    // Has a session that is still holding recorded data, whether or not the
    // timer is currently running.
    function hasSession() as Boolean {
        return _session != null;
    }

    function save() as Void {
        finish(true);
    }

    function discard() as Void {
        finish(false);
    }

    private function finish(keep as Boolean) as Void {
        var session = _session;
        if (session != null) {
            if (session.isRecording()) {
                session.stop();
            }
            if (keep) {
                session.save();
            } else {
                session.discard();
            }
            _session = null;
            _startedAt = null;
        }
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        _quality = Position.QUALITY_NOT_AVAILABLE;
        _motion.reset();
        _lastFixMs = null;
    }
}
