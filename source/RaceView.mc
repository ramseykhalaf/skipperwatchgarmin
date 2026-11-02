import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Damped course over ground (COG) on top, damped speed over ground (SOG) below.
// Reached from the countdown screen with UP/DOWN when nothing is selected, and
// shown automatically 10 seconds after the gun. UP, DOWN or BACK return to the
// countdown screen, e.g. for a general recall.
class RaceView extends WatchUi.View {
    private var _recorder as TrackRecorder;
    private var _timer as Timer.Timer;

    // Cached drawable references
    private var _cogValue;
    private var _sogValue;
    private var _gpsIndicator;

    function initialize(recorder as TrackRecorder) {
        View.initialize();
        _recorder = recorder;
        _timer = new Timer.Timer();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.RaceLayout(dc));

        _cogValue = View.findDrawableById("CogValue") as WatchUi.Text;
        _sogValue = View.findDrawableById("SogValue") as WatchUi.Text;
        _gpsIndicator = View.findDrawableById("GpsIndicator") as GpsIndicatorDrawable;

        // Green, matching the countdown screen's dividers once the race is on.
        (View.findDrawableById("Divider") as DividerDrawable).setColor(Graphics.COLOR_GREEN);
    }

    function onShow() as Void {
        _timer.start(method(:onTimer), 1000, true);
    }

    function onHide() as Void {
        _timer.stop();
    }

    function onTimer() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var motion = _recorder.getMotion();
        _cogValue.setText(formatCog(motion.getCogDegrees()));
        _sogValue.setText(formatSog(motion.getSogKnots()));
        _gpsIndicator.setQuality(_recorder.getQuality());

        View.onUpdate(dc);
    }

    // "045", or "---" with no reliable course.
    static function formatCog(degrees as Number?) as String {
        return (degrees == null) ? "---" : degrees.format("%03d");
    }

    // "6.4", or "-.-" before the first fix.
    static function formatSog(knots as Float?) as String {
        return (knots == null) ? "-.-" : knots.format("%.1f");
    }
}
