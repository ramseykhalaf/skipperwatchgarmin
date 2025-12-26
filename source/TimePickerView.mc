import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class TimePickerView extends WatchUi.View {
    private var _selectedHour as Number;
    private var _selectedMinute as Number;
    private var _isHoursMode as Boolean;

    function initialize() {
        View.initialize();
        
        // Initialize to current time + 3 minutes
        var clockTime = System.getClockTime();
        var currentHour = clockTime.hour;
        var currentMinute = clockTime.min;
        
        // Add 3 minutes, rounding up to next minute if needed
        var targetMinute = currentMinute + 3;
        var targetHour = currentHour;
        
        if (targetMinute >= 60) {
            targetMinute = targetMinute - 60;
            targetHour = (targetHour + 1) % 24;
        }
        
        _selectedHour = targetHour;
        _selectedMinute = targetMinute;
        _isHoursMode = true;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        // Display current time at top
        var clockTime = System.getClockTime();
        var currentTimeStr = Lang.format("$1$:$2$:$3$", [
            clockTime.hour.format("%02d"),
            clockTime.min.format("%02d"),
            clockTime.sec.format("%02d")
        ]);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 10, Graphics.FONT_SMALL, currentTimeStr, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Display selected target time
        var targetTimeStr = Lang.format("$1$:$2$", [
            _selectedHour.format("%02d"),
            _selectedMinute.format("%02d")
        ]);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height / 2 - 20, Graphics.FONT_MEDIUM, targetTimeStr, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Display mode indicator and current selection
        var modeText = _isHoursMode ? "Hours" : "Minutes";
        var valueText = _isHoursMode ? _selectedHour.toString() : _selectedMinute.toString();
        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height / 2 + 20, Graphics.FONT_SMALL, modeText, Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height / 2 + 40, Graphics.FONT_LARGE, valueText, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw up/down indicators
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height / 2 + 70, Graphics.FONT_XTINY, "Up/Down: Change", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height / 2 + 85, Graphics.FONT_XTINY, "Select: Next", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    function getSelectedHour() as Number {
        return _selectedHour;
    }
    
    function getSelectedMinute() as Number {
        return _selectedMinute;
    }
    
    function isHoursMode() as Boolean {
        return _isHoursMode;
    }
    
    function setHoursMode(isHours as Boolean) as Void {
        _isHoursMode = isHours;
        WatchUi.requestUpdate();
    }
    
    function incrementHour() as Void {
        _selectedHour = (_selectedHour + 1) % 24;
        WatchUi.requestUpdate();
    }
    
    function decrementHour() as Void {
        _selectedHour = (_selectedHour - 1 + 24) % 24;
        WatchUi.requestUpdate();
    }
    
    function incrementMinute() as Void {
        _selectedMinute = (_selectedMinute + 1) % 60;
        WatchUi.requestUpdate();
    }
    
    function decrementMinute() as Void {
        _selectedMinute = (_selectedMinute - 1 + 60) % 60;
        WatchUi.requestUpdate();
    }
}

