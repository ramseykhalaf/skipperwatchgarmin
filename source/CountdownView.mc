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
        
        // Calculate and display countdown/elapsed time
        var clockTimeNow = System.getClockTime();
        var currentSeconds = clockTimeNow.hour * 3600 + clockTimeNow.min * 60 + clockTimeNow.sec;
        
        // Calculate time difference
        // _targetSeconds can be > 86400 if target is tomorrow
        var targetSecondsToday = _targetSeconds % 86400;
        
        if (_targetSeconds > 86400) {
            // Target is tomorrow
            _timeDifference = _targetSeconds - currentSeconds;
        } else {
            // Target is today
            _timeDifference = targetSecondsToday - currentSeconds;
        }
        
        // Format the time difference
        var absDifference = _timeDifference.abs();
        var hours = absDifference / 3600;
        var minutes = (absDifference % 3600) / 60;
        var seconds = absDifference % 60;
        
        var timeStr;
        if (hours > 0) {
            timeStr = Lang.format("$1$$2$:$3$:$4$", [
                _timeDifference < 0 ? "-" : "+",
                hours.format("%d"),
                minutes.format("%02d"),
                seconds.format("%02d")
            ]);
        } else {
            timeStr = Lang.format("$1$$2$:$3$", [
                _timeDifference < 0 ? "-" : "+",
                minutes.format("%d"),
                seconds.format("%02d")
            ]);
        }
        
        // Set color based on countdown vs elapsed
        if (_timeDifference < 0) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        }
        
        // Draw the countdown/elapsed time in large font
        dc.drawText(width / 2, height / 2, Graphics.FONT_NUMBER_HOT, timeStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function onTimer() as Void {
        WatchUi.requestUpdate();
    }
}

