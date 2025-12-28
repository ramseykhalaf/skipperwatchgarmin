import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class TimePickerView extends WatchUi.View {
    private const ROW_SPACE = 15;
    private const DIGIT_COLON_SPACE = 4;
    private const LINE_WIDTH = 5;
    private const HIGHLIGHT_VERTICAL_SPACE = -2;
    private const HIGHLIGHT_HORIZONTAL_SPACE = 3;
    
    private var _selectedHour as Number;
    private var _selectedMinute as Number;
    private var _selectedSecond as Number;
    private var _mode as Symbol; // :hours, :minutes, :seconds, :countdown
    private var _timer as Timer.Timer;
    
    // Layout label references
    private var _currentTimeLabel as WatchUi.Text?;
    private var _hourLabel as WatchUi.Text?;
    private var _colon1Label as WatchUi.Text?;
    private var _minuteLabel as WatchUi.Text?;
    private var _colon2Label as WatchUi.Text?;
    private var _secondLabel as WatchUi.Text?;
    private var _countdownLabel as WatchUi.Text?;
    
    // Stored positions
    private var _width as Number;
    private var _fontHeight as Number;
    private var _fontWidth as Number;
    
    // Time picker positions
    private var _hourX as Number;
    private var _minuteX as Number;
    private var _secondX as Number;
    private var _timePickerY as Number;

    // Countdown positions
    private var _countdownX as Number;
    private var _countdownY as Number;
    private var _countdownStr as String;
    
    function initialize() {
        View.initialize();
        
        // Initialize position variables (will be set properly in onLayout)
        _hourX = 0;
        _minuteX = 0;
        _secondX = 0;
        _timePickerY = 0;

        _countdownX = 0;
        _countdownY = 0;
        
        _width = 0;
        _fontHeight = 0;
        _fontWidth = 0;

        _countdownStr = "";
        
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
        _fontWidth = dc.getTextWidthInPixels("00", Graphics.FONT_NUMBER_MEDIUM);
        var digitWidth = _fontWidth;
        var colonWidth = dc.getTextWidthInPixels(":", Graphics.FONT_NUMBER_MEDIUM);
        
        // Get screen dimensions
        _width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = _width / 2;
   
        // Calculate positions for Row 2 (middle - countdown)
        _countdownY = height / 2;
        
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

        // Calculate positions for Row 1 (top - current time)
        var row1X = centerX;
        var row1Y = _countdownY - ROW_SPACE - _fontHeight;

        // Calculate positions for Row 3 (bottom - time picker)
        _countdownX = centerX;
        _timePickerY = _countdownY + ROW_SPACE + _fontHeight;
        
        // Set locations for all labels
        if (_currentTimeLabel != null) {
            _currentTimeLabel.setLocation(row1X, row1Y);
        }
        
        if (_hourLabel != null) {
            _hourLabel.setLocation(hourX, _timePickerY);
        }
        
        if (_colon1Label != null) {
            _colon1Label.setLocation(colon1X, _timePickerY);
        }
        
        if (_minuteLabel != null) {
            _minuteLabel.setLocation(minutesX, _timePickerY);
        }
        
        if (_colon2Label != null) {
            _colon2Label.setLocation(colon2X, _timePickerY);
        }
        
        if (_secondLabel != null) {
            _secondLabel.setLocation(secondX, _timePickerY);
        }
        
        if (_countdownLabel != null) {
            _countdownLabel.setLocation(_countdownX, _countdownY);
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
        }
        
        if (_minuteLabel != null) {
            _minuteLabel.setText(_selectedMinute.format("%02d"));
        }
        
        if (_secondLabel != null) {
            _secondLabel.setText(_selectedSecond.format("%02d"));
        }
        
        // Update Row 3: Countdown timer
        var timeDifference = calculateCountdownSeconds(clockTime, _selectedHour, _selectedMinute, _selectedSecond);
        // Format the time difference
        var absDifference = timeDifference.abs();
        var hours = absDifference / 3600;
        var minutes = (absDifference % 3600) / 60;
        var seconds = absDifference % 60;
        
        _countdownStr = Lang.format("$1$$2$$3$$4$:$5$", [
            timeDifference < 0 ? "-" : "+",
            hours > 0 ? hours.format("%d") : "",
            hours > 0 ? ":" : "",
            minutes.format("%02d"),
            seconds.format("%02d")
        ]);

        if (_countdownLabel != null) {
            _countdownLabel.setText(_countdownStr);
        }
        
        // Render the layout first (draws labels)
        View.onUpdate(dc);
        
        // Set line color: red for countdown, green for counting up
        if (timeDifference < 0) {
            // Counting down - RED
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
        } else {
            // Counting up - GREEN
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
        }
        
        // Draw horizontal lines between rows at half ROW_SPACE, accounting for font height
        var lineY1 = _countdownY - (ROW_SPACE / 2) - (_fontHeight / 2) - (LINE_WIDTH / 2);
        var lineY2 = _countdownY + (ROW_SPACE / 2) + (_fontHeight / 2) - (LINE_WIDTH / 2);
        dc.fillRectangle(0, lineY1, _width, LINE_WIDTH);
        dc.fillRectangle(0, lineY2, _width, LINE_WIDTH);
        
        // Draw white outline boxes for active field on top (custom drawing)
        var highlightHeight = _fontHeight + (HIGHLIGHT_VERTICAL_SPACE * 2);
        var highlightWidth = _fontWidth + (HIGHLIGHT_HORIZONTAL_SPACE * 2);
        var highlightY = _timePickerY - (highlightHeight / 2);
        
        if (_mode == :hours && _hourLabel != null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawRectangle(_hourX - (highlightWidth / 2), highlightY, highlightWidth, highlightHeight);
        } else if (_mode == :minutes && _minuteLabel != null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawRectangle(_minuteX - (highlightWidth / 2), highlightY, highlightWidth, highlightHeight);
        } else if (_mode == :seconds && _secondLabel != null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawRectangle(_secondX - (highlightWidth / 2), highlightY, highlightWidth, highlightHeight);
        } else if (_mode == :countdown && _countdownLabel != null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var countdownWidth = dc.getTextWidthInPixels(_countdownStr, Graphics.FONT_NUMBER_MEDIUM) + (HIGHLIGHT_HORIZONTAL_SPACE * 2);
            var countdownHighlightY = _countdownY - (highlightHeight / 2);
            dc.drawRectangle(_countdownX - (countdownWidth / 2), countdownHighlightY, countdownWidth, highlightHeight);
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
    
    function incrementCountdown() as Void {
        // Increase the countdown by adding 1 second to the target time
        incrementSecond();
    }
    
    function decrementCountdown() as Void {
        // Decrease the countdown by subtracting 1 second from the target time
        decrementSecond();
    }
    
    function setCountdownSecondsToZero() as Void {
        // Snap to the nearest minute by rounding the countdown
        var clockTime = System.getClockTime();
        
        // Calculate current countdown
        var timeDifference = calculateCountdownSeconds(clockTime, _selectedHour, _selectedMinute, _selectedSecond);
        var absDifference = timeDifference.abs();
        var seconds = absDifference % 60;
        
        // If seconds >= 30, round up (add 1 minute to target time)
        // If seconds < 30, round down (keep current minute)
        if (seconds >= 30) {
            // Round up - add 1 minute to target time
            incrementMinute();
        }
        
        // Set selected seconds to current time's seconds to snap to whole minutes
        _selectedSecond = clockTime.sec;
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

    function snapToTime(
        currentHour as Number, currentMinute as Number, currentSecond as Number,
        countdownHour as Number, countdownMinute as Number, countdownSecond as Number) as Dictionary {
        return {
            :hour => 0,
            :minute => 0,
            :second => 0
        };
    }
}

