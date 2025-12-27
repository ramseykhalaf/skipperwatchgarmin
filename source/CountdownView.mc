import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class CountdownView extends WatchUi.View {
    private var _targetSeconds as Number; // Target time in seconds since midnight
    private var _timer as Timer.Timer;
    private var _timeDifference as Number; // Negative = countdown, positive = elapsed

    function initialize(targetSeconds as Number) {
        View.initialize();
        _targetSeconds = targetSeconds;
        _timeDifference = 0;
        
        // Create timer that updates every second
        _timer = new Timer.Timer();
        _timer.start(method(:onTimer), 1000, true);
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
    
    function onExit() as Void {
        // Clean up timer when view is removed
        if (_timer != null) {
            _timer.stop();
        }
    }

    function onUpdate(dc as Dc) as Void {
        // Display current time at top
        var clockTime = System.getClockTime();
        var currentTimeStr = Lang.format("$1$:$2$:$3$", [
            clockTime.hour.format("%02d"),
            clockTime.min.format("%02d"),
            clockTime.sec.format("%02d")
        ]);
        
        // Calculate and display countdown/elapsed time
        var currentSeconds = clockTime.hour * 3600 + clockTime.min * 60 + clockTime.sec;
        
        // Calculate time difference
        // _targetSeconds can be > 86400 if target is tomorrow
        var targetSecondsToday = _targetSeconds % 86400;
        
        // Calculate: current - target
        // Negative = countdown (before start)
        // Positive = elapsed (after start)
        if (_targetSeconds > 86400) {
            // Target is tomorrow
            _timeDifference = currentSeconds - _targetSeconds;
        } else {
            // Target is today
            _timeDifference = currentSeconds - targetSecondsToday;
        }
        
        // Format the time difference
        var absDifference = _timeDifference.abs();
        var hours = absDifference / 3600;
        var minutes = (absDifference % 3600) / 60;
        var seconds = absDifference % 60;

        // Draw screen

        var width = dc.getWidth();
        var height = dc.getHeight();
               
        var centerX = width / 2;
        var centerY = height / 2;

        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 40, Graphics.FONT_NUMBER_MEDIUM, currentTimeStr, Graphics.TEXT_JUSTIFY_CENTER);
 
        // Draw rectangle - red for countdown, green for elapsed
        if (_timeDifference < 0) {
            // Countdown (before start) - RED
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
        } else {
            // Elapsed (after start) - GREEN
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
        }
        // Draw 5 pixel high rectangle centered at centerY
        dc.fillRectangle(0, centerY - 15, width, 15);

        var timeStr;
        var timeFont;
        var timeY;
        if (hours > 0) {
            timeStr = Lang.format("$1$$2$:$3$:$4$", [
                _timeDifference < 0 ? "-" : "+",
                hours.format("%d"),
                minutes.format("%02d"),
                seconds.format("%02d")
            ]);
            timeFont = Graphics.FONT_NUMBER_MEDIUM;
            timeY = centerY + 15;

        } else {
            timeStr = Lang.format("$1$$2$:$3$", [
                _timeDifference < 0 ? "-" : "+",
                minutes.format("%d"),
                seconds.format("%02d")
            ]);
            timeFont = Graphics.FONT_NUMBER_HOT;
            timeY = centerY - 5;
        }
        
        // Draw the countdown/elapsed time in large font
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, timeY, timeFont, timeStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function onTimer() as Void {
        WatchUi.requestUpdate();
    }
}

