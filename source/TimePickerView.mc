import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class TimePickerView extends WatchUi.View {
    private const ROW_SPACE = 15;
    private const DIGIT_COLON_SPACE = 2;
    private const LINE_screenWIDTH = 5;
    private const HIGHLIGHT_VERTICAL_SPACE = -5;
    private const HIGHLIGHT_HORIZONTAL_SPACE = 2;

    private const CLOCK_FONT_SIZE = Graphics.FONT_NUMBER_MEDIUM;
    private const COUNTDOWN_MINUTES_FONT_SIZE = Graphics.FONT_NUMBER_THAI_HOT;
    private const COUNTDOWN_HOURS_FONT_SIZE = Graphics.FONT_NUMBER_HOT;
    private const TARGET_FONT_SIZE = Graphics.FONT_NUMBER_MEDIUM;
    
    private var _targetHour as Number;
    private var _targetMinute as Number;
    private var _targetSecond as Number;
    private var _mode as Symbol; // :hours, :minutes, :seconds, :countdown
    private var _timer as Timer.Timer;
    
    // Stored positions
    private var _screenWidth as Number;
    private var _clockFontHeight as Number;
    private var _countdownFontHeight as Number;
    private var _countdownFontSize; // Graphics.FontReference - stored font constant
    private var _targetFontHeight as Number;
    private var _targetDoubleDigitFontWidth as Number;
    private var _targetColonFontWidth as Number;
    
    // Countdown font dimensions (stored for both font sizes to avoid recalculating on every update)
    private var _countdownHoursFontHeight as Number;
    private var _countdownMinutesFontHeight as Number;
    
    // Time picker positions
    private var _hourX as Number;
    private var _minuteX as Number;
    private var _secondX as Number;
    private var _targetTimeY as Number;

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
        _targetTimeY = 0;

        _countdownX = 0;
        _countdownY = 0;
        
        _screenWidth = 0;
        
        _clockFontHeight = 0;
        _countdownFontHeight = 0;
        _countdownFontSize = COUNTDOWN_MINUTES_FONT_SIZE;
        _targetFontHeight = 0;
        _targetDoubleDigitFontWidth = 0;
        _targetColonFontWidth = 0;
        _countdownHoursFontHeight = 0;
        _countdownMinutesFontHeight = 0;

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
        
        _targetHour = targetHour;
        _targetMinute = targetMinute;
        _targetSecond = 0;
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
        // Get font dimensions
        _clockFontHeight = dc.getFontHeight(CLOCK_FONT_SIZE);
        
        _countdownHoursFontHeight = dc.getFontHeight(COUNTDOWN_HOURS_FONT_SIZE);
        _countdownMinutesFontHeight = dc.getFontHeight(COUNTDOWN_MINUTES_FONT_SIZE);
        
        _targetFontHeight = dc.getFontHeight(TARGET_FONT_SIZE);
        _targetDoubleDigitFontWidth = dc.getTextWidthInPixels("00", Graphics.FONT_NUMBER_MEDIUM);
        _targetColonFontWidth = dc.getTextWidthInPixels(":", Graphics.FONT_NUMBER_MEDIUM);
        
        // Get screen dimensions
        _screenWidth = dc.getWidth();
        var height = dc.getHeight();
        var centerX = _screenWidth / 2;
   
        // Calculate positions for Row 2 (middle - countdown)
        _countdownY = height / 2;
        
        // Calculate x positions for time picker elements relative to center
        // Layout: hours : minutes : seconds
        // Minutes is at center, so we calculate offsets from center
        var minutesX = centerX;
        _minuteX = minutesX;
        
        // Colon 2 is to the right of minutes
        var colon2X = minutesX + (_targetDoubleDigitFontWidth / 2) + DIGIT_COLON_SPACE + (_targetColonFontWidth / 2);
        
        // Seconds is to the right of colon 2
        var secondX = colon2X + (_targetColonFontWidth / 2) + DIGIT_COLON_SPACE + (_targetDoubleDigitFontWidth / 2);
        _secondX = secondX;
        
        // Colon 1 is to the left of minutes
        var colon1X = minutesX - (_targetDoubleDigitFontWidth / 2) - DIGIT_COLON_SPACE - (_targetColonFontWidth / 2);
        
        // Hours is to the left of colon 1
        var hourX = colon1X - (_targetColonFontWidth / 2) - DIGIT_COLON_SPACE - (_targetDoubleDigitFontWidth / 2);
        _hourX = hourX;

        // Calculate positions for Row 3 (bottom - time picker)
        _countdownX = centerX;
        _targetTimeY = _countdownY + ROW_SPACE + _targetFontHeight;
    }

    function onUpdate(dc as Dc) as Void {
        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var clockTime = System.getClockTime();
        
        // Calculate positions for Row 1 (top - current time)
        var row1X = _screenWidth / 2;
        var row1Y = _countdownY - ROW_SPACE - _clockFontHeight;
        
        // Draw Row 1: Current system time
        drawClockTime(dc, clockTime, row1X, row1Y);
        
        // Update Row 2: Countdown timer
        var timeDifference = calculateCountdownSeconds(clockTime, _targetHour, _targetMinute, _targetSecond);
        // Set countdown font height and size once based on whether hours are present
        var absDifference = timeDifference.abs();
        var hours = absDifference / 3600;
        if (hours > 0) {
            _countdownFontHeight = _countdownHoursFontHeight;
            _countdownFontSize = COUNTDOWN_HOURS_FONT_SIZE;
        } else {
            _countdownFontHeight = _countdownMinutesFontHeight;
            _countdownFontSize = COUNTDOWN_MINUTES_FONT_SIZE;
        }
        drawCountdownTimer(dc, timeDifference, _countdownX, _countdownY);

        // Draw Row 3: Time picker
        var centerX = _screenWidth / 2;
        drawTargetTime(dc, _targetHour, _targetMinute, _targetSecond, centerX, _targetTimeY);
        
        
        // Draw horizontal lines between rows at half ROW_SPACE, accounting for font height
        var lineY1 = _countdownY - (ROW_SPACE / 2) - (_countdownFontHeight / 2) - (LINE_screenWIDTH / 2);
        var lineY2 = _countdownY + (ROW_SPACE / 2) + (_countdownFontHeight / 2) - (LINE_screenWIDTH / 2);
        drawDividers(dc, timeDifference, lineY1, lineY2);
        
        // Draw white outline boxes for active field on top (custom drawing)
        drawSelectorHighlight(dc);
    }
    
    function drawSelectorHighlight(dc as Dc) as Void {
        var targetHighlightHeight = _targetFontHeight + (HIGHLIGHT_VERTICAL_SPACE * 2);
        var targetHighlightWidth = _targetDoubleDigitFontWidth + (HIGHLIGHT_HORIZONTAL_SPACE * 2);
        var highlightY = _targetTimeY - (targetHighlightHeight / 2);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        if (_mode == :hours) {
            dc.drawRectangle(_hourX - (targetHighlightWidth / 2), highlightY, targetHighlightWidth, targetHighlightHeight);
        } else if (_mode == :minutes) {
            dc.drawRectangle(_minuteX - (targetHighlightWidth / 2), highlightY, targetHighlightWidth, targetHighlightHeight);
        } else if (_mode == :seconds) {
            dc.drawRectangle(_secondX - (targetHighlightWidth / 2), highlightY, targetHighlightWidth, targetHighlightHeight);
        } else if (_mode == :countdown) {

            var countdownHighlightHeight = _countdownFontHeight + (HIGHLIGHT_VERTICAL_SPACE * 2);
            var countdownHighlightWidth = dc.getTextWidthInPixels(_countdownStr, _countdownFontSize) + (HIGHLIGHT_HORIZONTAL_SPACE * 2);
            var countdownHighlightY = _countdownY - (countdownHighlightHeight / 2);
            dc.drawRectangle(_countdownX - (countdownHighlightWidth / 2), countdownHighlightY, countdownHighlightWidth, countdownHighlightHeight);
        }
    }
    
    function drawClockTime(dc as Dc, clockTime as System.ClockTime, x as Number, y as Number) as Void {
        var currentTimeStr = Lang.format("$1$:$2$:$3$", [
            clockTime.hour.format("%02d"),
            clockTime.min.format("%02d"),
            clockTime.sec.format("%02d")
        ]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_NUMBER_MEDIUM, currentTimeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    
    function drawCountdownTimer(dc as Dc, countdownSeconds as Number, x as Number, y as Number) as Void {
        // Format the time difference
        var absDifference = countdownSeconds.abs();
        var hours = absDifference / 3600;
        var minutes = (absDifference % 3600) / 60;
        var seconds = absDifference % 60;
        
        _countdownStr = Lang.format("$1$$2$$3$$4$:$5$", [
            countdownSeconds < 0 ? "-" : "+",
            hours > 0 ? hours.format("%d") : "",
            hours > 0 ? ":" : "",
            minutes.format(hours > 0 ? "%02d" : "%d"),
            seconds.format("%02d")
        ]);

        // Draw countdown timer using stored font size
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, _countdownFontSize, _countdownStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    
    function drawTargetTime(dc as Dc, targetHour as Number, targetMinute as Number, targetSecond as Number, x as Number, y as Number) as Void {
        // Calculate colon positions (needed for drawing)
        var digitWidth = _targetDoubleDigitFontWidth;
        var colonWidth = _targetColonFontWidth;
        var minutesX = x;
        var colon2X = minutesX + (digitWidth / 2) + DIGIT_COLON_SPACE + (colonWidth / 2);
        var colon1X = minutesX - (digitWidth / 2) - DIGIT_COLON_SPACE - (colonWidth / 2);
        
        // Calculate hour and second positions
        var secondX = colon2X + (colonWidth / 2) + DIGIT_COLON_SPACE + (digitWidth / 2);
        var hourX = colon1X - (colonWidth / 2) - DIGIT_COLON_SPACE - (digitWidth / 2);
        
        // Draw time picker
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hourX, y, Graphics.FONT_NUMBER_MEDIUM, targetHour.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(colon1X, y, Graphics.FONT_NUMBER_MEDIUM, ":", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(minutesX, y, Graphics.FONT_NUMBER_MEDIUM, targetMinute.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(colon2X, y, Graphics.FONT_NUMBER_MEDIUM, ":", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(secondX, y, Graphics.FONT_NUMBER_MEDIUM, targetSecond.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    
    function drawDividers(dc as Dc, timeDifference as Number, divider1Y as Number, divider2Y as Number) as Void {
        // Set line color: red for countdown, green for counting up
        if (timeDifference < 0) {
            // Counting down - RED
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
        } else {
            // Counting up - GREEN
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
        }
        
        // Draw horizontal lines between rows
        dc.fillRectangle(0, divider1Y, _screenWidth, LINE_screenWIDTH);
        dc.fillRectangle(0, divider2Y, _screenWidth, LINE_screenWIDTH);
    }
    
    function getSelectedHour() as Number {
        return _targetHour;
    }
    
    function getSelectedMinute() as Number {
        return _targetMinute;
    }
    
    function getSelectedSecond() as Number {
        return _targetSecond;
    }
    
    function getMode() as Symbol {
        return _mode;
    }
    
    function setMode(mode as Symbol) as Void {
        _mode = mode;
        WatchUi.requestUpdate();
    }
    
    function incrementHour() as Void {
        _targetHour = (_targetHour + 1) % 24;
        WatchUi.requestUpdate();
    }
    
    function decrementHour() as Void {
        _targetHour = (_targetHour - 1 + 24) % 24;
        WatchUi.requestUpdate();
    }
    
    function incrementMinute() as Void {
        _targetMinute = _targetMinute + 1;
        if (_targetMinute >= 60) {
            _targetMinute = 0;
            incrementHour();
        } else {
            WatchUi.requestUpdate();
        }
    }
    
    function decrementMinute() as Void {
        _targetMinute = _targetMinute - 1;
        if (_targetMinute < 0) {
            _targetMinute = 59;
            decrementHour();
        } else {
            WatchUi.requestUpdate();
        }
    }
    
    function incrementSecond() as Void {
        _targetSecond = _targetSecond + 1;
        if (_targetSecond >= 60) {
            _targetSecond = 0;
            incrementMinute();
        } else {
            WatchUi.requestUpdate();
        }
    }
    
    function decrementSecond() as Void {
        _targetSecond = _targetSecond - 1;
        if (_targetSecond < 0) {
            _targetSecond = 59;
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
        var countdownSeconds = calculateCountdownSeconds(clockTime, _targetHour, _targetMinute, _targetSecond);
        
        // Use the static helper to calculate the snapped target time
        var snappedTime = calculateTargetTimeToSnapCountdownSecondsToZero(
            clockTime.hour, clockTime.min, clockTime.sec, countdownSeconds);
        
        // Update target time to the snapped values
        _targetHour = snappedTime[:hour];
        _targetMinute = snappedTime[:minute];
        _targetSecond = snappedTime[:second];
        
        WatchUi.requestUpdate();
    }

    function calculateCountdownSeconds(clockTime as System.ClockTime, targetHour as Number, targetMinute as Number, targetSecond as Number) as Number {
        // Convert current time to seconds since midnight
        var currentSeconds = clockTime.hour * 3600 + clockTime.min * 60 + clockTime.sec;
        
        // Convert target time to seconds since midnight
        var targetSeconds = targetHour * 3600 + targetMinute * 60 + targetSecond;
        
        // Calculate time difference (current - target)
        // Positive = target in past (elapsed time), Negative = target in future (countdown)
        return currentSeconds - targetSeconds;
    }

    static function calculateTargetTimeToSnapCountdownSecondsToZero(
        clockHour as Number, clockMinute as Number, clockSecond as Number, countdownSeconds as Number) as Dictionary {
        
        // Convert current time to total seconds since midnight
        var currentTotalSeconds = clockHour * 3600 + clockMinute * 60 + clockSecond;
        
        // Extract the seconds component from countdown and round to nearest minute
        var absCountdownSeconds = countdownSeconds.abs();
        var countdownSecondComponent = absCountdownSeconds % 60;
        var roundUpMinute = (countdownSecondComponent >= 30) ? 1 : 0;
        
        // Calculate rounded countdown in total seconds
        var roundedCountdownMinutes = (absCountdownSeconds / 60) + roundUpMinute;
        var roundedCountdown = (countdownSeconds < 0 ? -1 : 1) * roundedCountdownMinutes * 60;
        
        // Calculate target time: currentTime - countdown
        // (negative countdown means target in future, so we add)
        var targetTotalSeconds = currentTotalSeconds - roundedCountdown;
        
        // Handle wrapping (ensure positive and within 24 hours)
        while (targetTotalSeconds < 0) {
            targetTotalSeconds += 86400; // 24 hours in seconds
        }
        targetTotalSeconds = targetTotalSeconds % 86400;
        
        // Convert back to hours, minutes, seconds
        var targetHour = targetTotalSeconds / 3600;
        var targetMinute = (targetTotalSeconds % 3600) / 60;
        var targetSecond = targetTotalSeconds % 60;
        
        return {
            :hour => targetHour,
            :minute => targetMinute,
            :second => targetSecond
        };
    }
}

