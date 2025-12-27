import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class TimePickerView extends WatchUi.View {
    private var _selectedHour as Number;
    private var _selectedMinute as Number;
    private var _isHoursMode as Boolean;
    private var _timer as Timer.Timer;

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
        
        // Create timer to update current time display every second
        _timer = new Timer.Timer();
    }
    
    function onShow() as Void {
        // Start timer when view is shown
        if (_timer != null) {
            _timer.start(method(:onTimer), 1000, true);
        }
    }
    
    function onHide() as Void {
        // Stop timer when view is hidden
        if (_timer != null) {
            _timer.stop();
        }
    }
    
    function onTimer() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var width = dc.getWidth();
        var height = dc.getHeight();
               
        // Display hours and minutes side by side
        var centerX = width / 2;
        var centerY = height / 2;
        var hourX = centerX - 12;
        var minuteX = centerX + 12;
        
        // Display current time at top
        var clockTime = System.getClockTime();
        var currentTimeStr = Lang.format("$1$:$2$:$3$", [
            clockTime.hour.format("%02d"),
            clockTime.min.format("%02d"),
            clockTime.sec.format("%02d")
        ]);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 40, Graphics.FONT_NUMBER_MEDIUM, currentTimeStr, Graphics.TEXT_JUSTIFY_CENTER);
 
        // Draw line
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, centerY - 15, width, 15);


        // Draw hours
        var hourColor = _isHoursMode ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;
        dc.setColor(hourColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hourX, centerY - 5, Graphics.FONT_NUMBER_HOT, _selectedHour.format("%02d"), Graphics.TEXT_JUSTIFY_RIGHT);
        
        // Draw colon separator
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY - 5, Graphics.FONT_NUMBER_HOT, ":", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw minutes
        var minuteColor = _isHoursMode ? Graphics.COLOR_WHITE : Graphics.COLOR_YELLOW;
        dc.setColor(minuteColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(minuteX, centerY - 5, Graphics.FONT_NUMBER_HOT, _selectedMinute.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT);
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

