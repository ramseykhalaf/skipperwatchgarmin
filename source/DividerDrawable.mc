import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class DividerDrawable extends WatchUi.Drawable {
    private var _color as Number;
    private var _height as Number;
    private var _yPercent as Number;

    function initialize(params as Dictionary) {
        Drawable.initialize(params);
        _color = Graphics.COLOR_RED;
        _height = params.hasKey(:height) ? params[:height] : 6;
        _yPercent = params.hasKey(:yPercent) ? params[:yPercent] : 50;
    }

    function setColor(color as Number) as Void {
        _color = color;
    }

    function draw(dc as Graphics.Dc) as Void {
        var screenHeight = dc.getHeight();
        var y = (screenHeight * _yPercent) / 100;
        
        dc.setColor(_color, _color);
        dc.fillRectangle(0, y - _height/2, dc.getWidth(), _height);
    }
}
