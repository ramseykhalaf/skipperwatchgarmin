import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class HighlightDrawable extends WatchUi.Drawable {
    private var _xPercent as Number;
    private var _yPercent as Number;
    private var _widthPercent as Number;
    private var _heightPercent as Number;
    private var _penWidth as Number;
    private var _radius as Number;
    private var _visible as Boolean;

    // Cached pixel coordinates
    private var _cachedX as Number;
    private var _cachedY as Number;
    private var _cachedWidth as Number;
    private var _cachedHeight as Number;
    private var _coordinatesCached as Boolean;

    function initialize(params as Dictionary) {
        Drawable.initialize(params);
        _xPercent = params.hasKey(:xPercent) ? params[:xPercent] : 50;
        _yPercent = params.hasKey(:yPercent) ? params[:yPercent] : 50;
        _widthPercent = params.hasKey(:widthPercent) ? params[:widthPercent] : 10;
        _heightPercent = params.hasKey(:heightPercent) ? params[:heightPercent] : 10;
        _penWidth = params.hasKey(:penWidth) ? params[:penWidth] : 2;
        _radius = params.hasKey(:radius) ? params[:radius] : 3;
        _visible = false;

        // Initialize cached values
        _cachedX = 0;
        _cachedY = 0;
        _cachedWidth = 0;
        _cachedHeight = 0;
        _coordinatesCached = false;
    }

    function setVisible(visible as Boolean) as Void {
        _visible = visible;
    }

    function draw(dc as Graphics.Dc) as Void {
        if (!_visible) {
            return;
        }

        if (!_coordinatesCached) {
            var screenWidth = dc.getWidth();
            var screenHeight = dc.getHeight();
            _cachedWidth = (screenWidth * _widthPercent) / 100;
            _cachedHeight = (screenHeight * _heightPercent) / 100;
            _cachedX = (screenWidth * _xPercent) / 100 - (_cachedWidth / 2);
            _cachedY = (screenHeight * _yPercent) / 100 - (_cachedHeight / 2);
            _coordinatesCached = true;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(_penWidth);
        dc.drawRoundedRectangle(_cachedX, _cachedY, _cachedWidth, _cachedHeight, _radius);
        dc.setPenWidth(1);
    }
}

