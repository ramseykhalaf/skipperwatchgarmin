import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.WatchUi;

// A small dot showing GPS fix quality while a track is recording. Connect IQ
// only exposes four quality buckets, so four colours say everything there is
// to say: red no fix, orange poor, yellow usable, green good.
class GpsIndicatorDrawable extends WatchUi.Drawable {
    private var _quality as Position.Quality;
    private var _radius as Number;
    private var _xPercent as Number;
    private var _yPercent as Number;

    // Cached pixel coordinates
    private var _cachedX as Number;
    private var _cachedY as Number;
    private var _coordinatesCached as Boolean;

    function initialize(params as Dictionary) {
        Drawable.initialize(params);
        _quality = Position.QUALITY_NOT_AVAILABLE;
        _radius = params.hasKey(:radius) ? params[:radius] : 5;
        _xPercent = params.hasKey(:xPercent) ? params[:xPercent] : 50;
        _yPercent = params.hasKey(:yPercent) ? params[:yPercent] : 8;

        _cachedX = 0;
        _cachedY = 0;
        _coordinatesCached = false;
    }

    function setQuality(quality as Position.Quality) as Void {
        _quality = quality;
    }

    function draw(dc as Graphics.Dc) as Void {
        if (!_coordinatesCached) {
            _cachedX = (dc.getWidth() * _xPercent) / 100;
            _cachedY = (dc.getHeight() * _yPercent) / 100;
            _coordinatesCached = true;
        }

        var color = Graphics.COLOR_RED;
        if (_quality == Position.QUALITY_GOOD) {
            color = Graphics.COLOR_GREEN;
        } else if (_quality == Position.QUALITY_USABLE) {
            color = Graphics.COLOR_YELLOW;
        } else if (_quality == Position.QUALITY_POOR) {
            color = Graphics.COLOR_ORANGE;
        }

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_cachedX, _cachedY, _radius);
    }
}
