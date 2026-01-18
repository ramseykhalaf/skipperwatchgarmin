import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class DividerDrawable extends WatchUi.Drawable {
    private var _color as Number;
    private var _height as Number;
    private var _yPercent as Number;

    // Cached pixel coordinates
    private var _cachedY as Number;
    private var _cachedScreenWidth as Number;
    private var _coordinatesCached as Boolean;

    function initialize(params as Dictionary) {
        Drawable.initialize(params);
        _color = Graphics.COLOR_RED;
        _height = params.hasKey(:height) ? params[:height] : 6;
        _yPercent = params.hasKey(:yPercent) ? params[:yPercent] : 50;

        // Initialize cached values
        _cachedY = 0;
        _cachedScreenWidth = 0;
        _coordinatesCached = false;
    }

    function setColor(color as Number) as Void {
        _color = color;
    }

    function draw(dc as Graphics.Dc) as Void {
        if (!_coordinatesCached) {
            var screenHeight = dc.getHeight();
            _cachedY = (screenHeight * _yPercent) / 100 - _height / 2;
            _cachedScreenWidth = dc.getWidth();
            _coordinatesCached = true;
        }

        dc.setColor(_color, _color);
        dc.fillRectangle(0, _cachedY, _cachedScreenWidth, _height);
    }
}
