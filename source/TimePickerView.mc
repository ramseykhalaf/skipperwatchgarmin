import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class TimePickerView extends WatchUi.View {
    private const ROW_SPACE = 10;
    private const DIGIT_COLON_SPACE = 5;
    private const LINE_WIDTH = 5;
    
    private var _selectedHour as Number;
    private var _selectedMinute as Number;
    private var _selectedSecond as Number;
    private var _mode as Symbol; // :hours, :minutes, :seconds, :sync
    private var _timer as Timer.Timer;
    
    // Layout label references
    private var _currentTimeLabel as WatchUi.Text?;
    private var _hourLabel as WatchUi.Text?;
    private var _colon1Label as WatchUi.Text?;
    private var _minuteLabel as WatchUi.Text?;
    private var _colon2Label as WatchUi.Text?;
    private var _secondLabel as WatchUi.Text?;
    private var _countdownLabel as WatchUi.Text?;
    
    // Stored positions for highlight rectangles
    private var _hourX as Number;
    private var _minuteX as Number;
    private var _secondX as Number;
    private var _row2Y as Number;
    private var _centerY as Number;
    private var _width as Number;
    private var _fontHeight as Number;

    function initialize() {
        View.initialize();
        
        // Initialize position variables (will be set properly in onLayout)
        _hourX = 0;
        _minuteX = 0;
        _secondX = 0;
        _row2Y = 0;
        _centerY = 0;
        _width = 0;
        _fontHeight = 0;
        
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
        _selectedSecond = 0;
        _mode = :minutes;
        
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
    
    // Helper function to calculate countdown seconds
    // Returns: positive if target is in the past (elapsed time)
    //          negative if target is in the future (countdown)
    function calculateCountdownSeconds(clockTime as System.ClockTime, targetHour as Number, targetMinute as Number, targetSecond as Number) as Number {
        // Convert current time to seconds since midnight
        var currentSeconds = clockTime.hour * 3600 + clockTime.min * 60 + clockTime.sec;
        
        // Convert target time to seconds since midnight
        var targetSeconds = targetHour * 3600 + targetMinute * 60 + targetSecond;
        
        // Calculate time difference (current - target)
        // Positive = target in past (elapsed time), Negative = target in future (countdown)
        return currentSeconds - targetSeconds;
    }
    
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.TimePickerLayout(dc));
        
        // Get references to layout labels
        _currentTimeLabel = findDrawableById("currentTimeLabel") as WatchUi.Text;
        _hourLabel = findDrawableById("hourLabel") as WatchUi.Text;
        _colon1Label = findDrawableById("colon1Label") as WatchUi.Text;
        _minuteLabel = findDrawableById("minuteLabel") as WatchUi.Text;
        _colon2Label = findDrawableById("colon2Label") as WatchUi.Text;
        _secondLabel = findDrawableById("secondLabel") as WatchUi.Text;
        _countdownLabel = findDrawableById("countdownLabel") as WatchUi.Text;
        
        // Get font dimensions
        _fontHeight = dc.getFontHeight(Graphics.FONT_NUMBER_MEDIUM);
        var digitWidth = dc.getTextWidthInPixels("00", Graphics.FONT_NUMBER_MEDIUM);
        var colonWidth = dc.getTextWidthInPixels(":", Graphics.FONT_NUMBER_MEDIUM);
        
        // Get screen dimensions
        _width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = _width / 2;
        _centerY = height / 2;
        
        // Calculate positions for Row 1 (top - current time)
        var row1X = centerX;
        var row1Y = _centerY - ROW_SPACE - _fontHeight;
        
        // Calculate positions for Row 2 (middle - time picker)
        _row2Y = _centerY;
        
        // Calculate x positions for time picker elements relative to center
        // Layout: hours : minutes : seconds
        // Minutes is at center, so we calculate offsets from center
        var minutesX = centerX;
        _minuteX = minutesX;
        
        // Colon 2 is to the right of minutes
        var colon2X = minutesX + (digitWidth / 2) + DIGIT_COLON_SPACE + (colonWidth / 2);
        
        // Seconds is to the right of colon 2
        var secondX = colon2X + (colonWidth / 2) + DIGIT_COLON_SPACE + (digitWidth / 2);
        _secondX = secondX;
        
        // Colon 1 is to the left of minutes
        var colon1X = minutesX - (digitWidth / 2) - DIGIT_COLON_SPACE - (colonWidth / 2);
        
        // Hours is to the left of colon 1
        var hourX = colon1X - (colonWidth / 2) - DIGIT_COLON_SPACE - (digitWidth / 2);
        _hourX = hourX;
        
        // Calculate positions for Row 3 (bottom - countdown)
        var row3X = centerX;
        var row3Y = _centerY + ROW_SPACE + _fontHeight;
        
        // Set locations for all labels
        if (_currentTimeLabel != null) {
            _currentTimeLabel.setLocation(row1X, row1Y);
        }
        
        if (_hourLabel != null) {
            _hourLabel.setLocation(hourX, _row2Y);
        }
        
        if (_colon1Label != null) {
            _colon1Label.setLocation(colon1X, _row2Y);
        }
        
        if (_minuteLabel != null) {
            _minuteLabel.setLocation(minutesX, _row2Y);
        }
        
        if (_colon2Label != null) {
            _colon2Label.setLocation(colon2X, _row2Y);
        }
        
        if (_secondLabel != null) {
            _secondLabel.setLocation(secondX, _row2Y);
        }
        
        if (_countdownLabel != null) {
            _countdownLabel.setLocation(row3X, row3Y);
        }
    }

    function onUpdate(dc as Dc) as Void {
        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var clockTime = System.getClockTime();
        
        // Update Row 1: Current system time
        if (_currentTimeLabel != null) {
            var currentTimeStr = Lang.format("$1$:$2$:$3$", [
                clockTime.hour.format("%02d"),
                clockTime.min.format("%02d"),
                clockTime.sec.format("%02d")
            ]);
            _currentTimeLabel.setText(currentTimeStr);
        }
        
        // Update Row 2: Time picker labels
        if (_hourLabel != null) {
            _hourLabel.setText(_selectedHour.format("%02d"));
            _hourLabel.setColor(_mode == :hours ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE);
        }
        
        if (_minuteLabel != null) {
            _minuteLabel.setText(_selectedMinute.format("%02d"));
            _minuteLabel.setColor(_mode == :minutes ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE);
        }
        
        if (_secondLabel != null) {
            _secondLabel.setText(_selectedSecond.format("%02d"));
            _secondLabel.setColor(_mode == :seconds ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE);
        }
        
        // Update Row 3: Countdown timer
        if (_countdownLabel != null) {
            // Calculate target time in seconds since midnight
            var targetSeconds = _selectedHour * 3600 + _selectedMinute * 60 + _selectedSecond;
            
            // Get current time in seconds since midnight
            var currentSeconds = clockTime.hour * 3600 + clockTime.min * 60 + clockTime.sec;
            
            // If target time is earlier today, check if difference is less than 12 hours
            // If less than 12 hours, display as positive (elapsed time)
            // If 12 hours or more, assume it's for tomorrow (countdown)
            if (targetSeconds <= currentSeconds) {
                var diff = currentSeconds - targetSeconds;
                if (diff >= 43200) { // 12 hours in seconds
                    targetSeconds += 86400; // Add 24 hours (treat as tomorrow)
                }
                // Otherwise, leave targetSeconds as is, so it displays as positive elapsed time
            }
            
            // Calculate time difference (current - target)
            // Negative = countdown (before start), Positive = elapsed (after start)
            var timeDifference = currentSeconds - targetSeconds;
            
            // Format the time difference
            var absDifference = timeDifference.abs();
            var hours = absDifference / 3600;
            var minutes = (absDifference % 3600) / 60;
            var seconds = absDifference % 60;
            
            var timeStr;
            if (hours > 0) {
                timeStr = Lang.format("$1$$2$:$3$:$4$", [
                    timeDifference < 0 ? "-" : "+",
                    hours.format("%d"),
                    minutes.format("%02d"),
                    seconds.format("%02d")
                ]);
            } else {
                timeStr = Lang.format("$1$$2$:$3$", [
                    timeDifference < 0 ? "-" : "+",
                    minutes.format("%d"),
                    seconds.format("%02d")
                ]);
            }
            
            _countdownLabel.setText(timeStr);
        }
        
        // Render the layout first (draws labels)
        View.onUpdate(dc);
        
        // Calculate time difference to determine line color (using same logic as countdown label)
        var targetSecondsForLines = _selectedHour * 3600 + _selectedMinute * 60 + _selectedSecond;
        var currentSecondsForLines = clockTime.hour * 3600 + clockTime.min * 60 + clockTime.sec;
        
        // If target time is earlier today, check if difference is less than 12 hours
        if (targetSecondsForLines <= currentSecondsForLines) {
            var diff = currentSecondsForLines - targetSecondsForLines;
            if (diff >= 43200) { // 12 hours in seconds
                targetSecondsForLines += 86400; // Add 24 hours (treat as tomorrow)
            }
        }
        
        var timeDifferenceForLines = currentSecondsForLines - targetSecondsForLines;
        
        // Set line color: red for countdown, green for counting up
        if (timeDifferenceForLines < 0) {
            // Counting down - RED
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
        } else {
            // Counting up - GREEN
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
        }
        
        // Draw horizontal lines between rows at half ROW_SPACE, accounting for font height
        var lineY1 = _centerY - (ROW_SPACE / 2) - (_fontHeight / 2) - (LINE_WIDTH / 2);
        var lineY2 = _centerY + (ROW_SPACE / 2) + (_fontHeight / 2) - (LINE_WIDTH / 2);
        dc.fillRectangle(0, lineY1, _width, LINE_WIDTH);
        dc.fillRectangle(0, lineY2, _width, LINE_WIDTH);
        
        // Draw yellow highlight rectangles for active field on top (custom drawing)
        var highlightHeight = _fontHeight;
        var highlightWidth = 45;
        var highlightY = _row2Y - (highlightHeight / 2);
        
        if (_mode == :hours && _hourLabel != null) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_YELLOW);
            dc.fillRectangle(_hourX - (highlightWidth / 2), highlightY, highlightWidth, highlightHeight);
            // Redraw the hour label on top of the highlight
            _hourLabel.draw(dc);
        } else if (_mode == :minutes && _minuteLabel != null) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_YELLOW);
            dc.fillRectangle(_minuteX - (highlightWidth / 2), highlightY, highlightWidth, highlightHeight);
            // Redraw the minute label on top of the highlight
            _minuteLabel.draw(dc);
        } else if (_mode == :seconds && _secondLabel != null) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_YELLOW);
            dc.fillRectangle(_secondX - (highlightWidth / 2), highlightY, highlightWidth, highlightHeight);
            // Redraw the second label on top of the highlight
            _secondLabel.draw(dc);
        }
    }
    
    function getSelectedHour() as Number {
        return _selectedHour;
    }
    
    function getSelectedMinute() as Number {
        return _selectedMinute;
    }
    
    function getSelectedSecond() as Number {
        return _selectedSecond;
    }
    
    function getMode() as Symbol {
        return _mode;
    }
    
    function setMode(mode as Symbol) as Void {
        _mode = mode;
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
        _selectedMinute = _selectedMinute + 1;
        if (_selectedMinute >= 60) {
            _selectedMinute = 0;
            incrementHour();
        } else {
            WatchUi.requestUpdate();
        }
    }
    
    function decrementMinute() as Void {
        _selectedMinute = _selectedMinute - 1;
        if (_selectedMinute < 0) {
            _selectedMinute = 59;
            decrementHour();
        } else {
            WatchUi.requestUpdate();
        }
    }
    
    function incrementSecond() as Void {
        _selectedSecond = _selectedSecond + 1;
        if (_selectedSecond >= 60) {
            _selectedSecond = 0;
            incrementMinute();
        } else {
            WatchUi.requestUpdate();
        }
    }
    
    function decrementSecond() as Void {
        _selectedSecond = _selectedSecond - 1;
        if (_selectedSecond < 0) {
            _selectedSecond = 59;
            decrementMinute();
        } else {
            WatchUi.requestUpdate();
        }
    }
}

