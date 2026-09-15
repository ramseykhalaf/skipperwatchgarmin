import Toybox.Lang;
import Toybox.Math;

// Damps GPS speed over ground (SOG) and course over ground (COG) with an
// exponential moving average. There is no compass involved: COG is the direction
// the boat is actually moving, which differs from where the bow points by any
// leeway or current.
//
// The weight given to each new fix is alpha = 1 - e^(-dt / tau), so a skipped
// fix is handled correctly rather than assuming a fixed 1 Hz. With tau = 2.5 s
// and 1 Hz fixes alpha is ~1/3, the classic "5-period" EMA: a step change is
// 33% through after 1 s, 70% after 3 s and 95% after ~7.5 s.
//
// COG is circular, so it cannot be averaged directly (350 and 010 would
// average to 180). Instead the velocity vector is smoothed and COG read back
// from it. That also means slow, noisy fixes barely move COG.
// SOG is smoothed as a plain scalar: the vector's length would sag through a
// tack as opposing vectors cancel.
class MotionFilter {
    // Larger is calmer but lags more out of a tack. 5.0 gives alpha ~0.18.
    static const TIME_CONSTANT_SECONDS = 2.5;

    // After a gap this long the old state is stale; restart from the next fix.
    static const MAX_GAP_SECONDS = 10.0;

    // Below this COG is noise, so none is shown.
    static const MIN_COG_SOG_KNOTS = 0.5;

    static const KNOTS_PER_MPS = 1.943844;

    private var _hasValue as Boolean = false;
    private var _sogMps as Float = 0.0;
    private var _east as Float = 0.0;
    private var _north as Float = 0.0;

    function initialize() {
    }

    // sogMps in metres per second and cogRadians true-north referenced, as
    // delivered by Position.Info.speed and Position.Info.heading (which, despite
    // its name, is course over ground).
    function update(sogMps as Float, cogRadians as Float, dtSeconds as Float) as Void {
        var east = sogMps * Math.sin(cogRadians);
        var north = sogMps * Math.cos(cogRadians);

        if (!_hasValue || dtSeconds > MAX_GAP_SECONDS || dtSeconds <= 0) {
            _sogMps = sogMps;
            _east = east;
            _north = north;
            _hasValue = true;
            return;
        }

        var alpha = 1.0 - Math.pow(Math.E, -dtSeconds / TIME_CONSTANT_SECONDS);
        _sogMps += alpha * (sogMps - _sogMps);
        _east += alpha * (east - _east);
        _north += alpha * (north - _north);
    }

    function reset() as Void {
        _hasValue = false;
    }

    function getSogKnots() as Float? {
        return _hasValue ? (_sogMps * KNOTS_PER_MPS).toFloat() : null;
    }

    // Whole degrees true, 0-359, or null when there is no reliable course.
    function getCogDegrees() as Number? {
        if (!_hasValue || _sogMps * KNOTS_PER_MPS < MIN_COG_SOG_KNOTS) {
            return null;
        }
        var degrees = Math.round(Math.toDegrees(Math.atan2(_east, _north))).toNumber();
        return ((degrees % 360) + 360) % 360;
    }
}
