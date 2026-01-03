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

    function initialize(params as Dictionary) {
        Drawable.initialize(params);
        _xPercent = params.hasKey(:xPercent) ? params[:xPercent] : 50;
        _yPercent = params.hasKey(:yPercent) ? params[:yPercent] : 50;
        _widthPercent = params.hasKey(:widthPercent) ? params[:widthPercent] : 10;
        _heightPercent = params.hasKey(:heightPercent) ? params[:heightPercent] : 10;
        _penWidth = params.hasKey(:penWidth) ? params[:penWidth] : 2;
        _radius = params.hasKey(:radius) ? params[:radius] : 3;
        _visible = false;
    }

    function setVisible(visible as Boolean) as Void {
        _visible = visible;
    }

    function draw(dc as Graphics.Dc) as Void {
        if (!_visible) {
            return;
        }

        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();

        var width = (screenWidth * _widthPercent) / 100;
        var height = (screenHeight * _heightPercent) / 100;
        var x = (screenWidth * _xPercent) / 100 - (width / 2);
        var y = (screenHeight * _yPercent) / 100 - (height / 2);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(_penWidth);
        dc.drawRoundedRectangle(x, y, width, height, _radius);
        dc.setPenWidth(1);
    }
}

