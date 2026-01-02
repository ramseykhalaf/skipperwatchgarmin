import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Timer;
import Toybox.WatchUi;

class TimePickerView extends WatchUi.View {
    private const ROW_SPACE = 0;
    private const DIGIT_COLON_SPACE = 2;
    private const LINE_WIDTH = 6;
    private const HIGHLIGHT_VERTICAL_SPACE = 0;
    private const HIGHLIGHT_HORIZONTAL_SPACE = 0;

    private const CLOCK_FONT_SIZE = Graphics.FONT_NUMBER_MEDIUM;
    private const COUNTDOWN_MINUTES_FONT_SIZE = Graphics.FONT_NUMBER_THAI_HOT;
    private const COUNTDOWN_HOURS_FONT_SIZE = Graphics.FONT_NUMBER_HOT;
    private const TARGET_FONT_SIZE = Graphics.FONT_NUMBER_MEDIUM;
    
    // Target time properties
    private var _targetMoment as Time.Moment;
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
    private var _row3Y as Number;

    // Countdown positions
    private var _centerX as Number;
    private var _row2X as Number;
    private var _row2Y as Number;
    private var _countdownStr as String;
    
    function initialize() {
        View.initialize();
        
        // Initialize position variables (will be set properly in onLayout)
        _hourX = 0;
        _minuteX = 0;
        _secondX = 0;
        _row3Y = 0;

        _centerX = 0;
        _row2X = 0;
        _row2Y = 0;
        
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
        var now = Time.now();
        var threeMinutes = new Time.Duration(180); // 3 minutes in seconds
        _targetMoment = now.add(threeMinutes);
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
        _centerX = _screenWidth / 2;
   
        // Calculate positions for Row 2
        _row2Y = height / 2;
        _row2X = _centerX;
        
        // Calculate x positions for time picker elements relative to center
        // Layout: hours : minutes : seconds
        // Minutes is at center, so we calculate offsets from center
        var minutesX = _centerX;
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

        _row3Y = _row2Y + _countdownMinutesFontHeight/2 + ROW_SPACE + _targetFontHeight/2;
    }

    function onUpdate(dc as Dc) as Void {
        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var clockTime = System.getClockTime();
        
        // Calculate positions for Row 1 (top - current time)
        var row1Y = _row2Y - _countdownMinutesFontHeight/2 - ROW_SPACE - _clockFontHeight/2;
        
        // Draw Row 1: Current system time
        drawClockTime(dc, clockTime, _centerX, row1Y);
        
        // Draw Row 2: Countdown timer
        var timeDifference = calculateCountdownSeconds(clockTime);
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
        drawCountdownTimer(dc, timeDifference, _row2X, _row2Y);

        // Draw Row 3: Time picker
        var targetInfo = getTargetTimeInfo();
        drawTargetTime(dc, targetInfo[:hour], targetInfo[:minute], targetInfo[:second], _centerX, _row3Y);
        
        // Draw horizontal lines between rows at half ROW_SPACE, accounting for font height
        var lineY1 = _row2Y - _countdownMinutesFontHeight/2 - ROW_SPACE/2;
        var lineY2 = _row2Y + _countdownMinutesFontHeight/2 - ROW_SPACE/2;
        drawDividers(dc, timeDifference, lineY1, lineY2);
        
        // Draw white outline boxes for active field on top (custom drawing)
        drawSelectorHighlight(dc);
    }
    
    function drawSelectorHighlight(dc as Dc) as Void {
        var targetHighlightHeight = _targetFontHeight + (HIGHLIGHT_VERTICAL_SPACE * 2);
        var targetHighlightWidth = _targetDoubleDigitFontWidth + (HIGHLIGHT_HORIZONTAL_SPACE * 2);
        var highlightY = _row3Y - (targetHighlightHeight / 2);

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
            var countdownHighlightY = _row2Y - (countdownHighlightHeight / 2);
            dc.drawRectangle(_row2X - (countdownHighlightWidth / 2), countdownHighlightY, countdownHighlightWidth, countdownHighlightHeight);
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
        dc.fillRectangle(0, divider1Y - LINE_WIDTH/2, _screenWidth, LINE_WIDTH);
        dc.fillRectangle(0, divider2Y - LINE_WIDTH/2, _screenWidth, LINE_WIDTH);
    }
    
    function getSelectedHour() as Number {
        return getTargetTimeInfo()[:hour];
    }
    
    function getSelectedMinute() as Number {
        return getTargetTimeInfo()[:minute];
    }
    
    function getSelectedSecond() as Number {
        return getTargetTimeInfo()[:second];
    }
    
    // Helper function to extract time components from target moment
    private function getTargetTimeInfo() as Dictionary {
        var info = Gregorian.info(_targetMoment, Time.FORMAT_SHORT);
        return {
            :hour => info.hour,
            :minute => info.min,
            :second => info.sec
        };
    }
    
    function getMode() as Symbol {
        return _mode;
    }
    
    function setMode(mode as Symbol) as Void {
        _mode = mode;
        WatchUi.requestUpdate();
    }
    
    function incrementHour() as Void {
        var oneHour = new Time.Duration(3600);
        _targetMoment = _targetMoment.add(oneHour);
        WatchUi.requestUpdate();
    }
    
    function decrementHour() as Void {
        var oneHour = new Time.Duration(3600);
        _targetMoment = _targetMoment.subtract(oneHour);
        WatchUi.requestUpdate();
    }
    
    function incrementMinute() as Void {
        var oneMinute = new Time.Duration(60);
        _targetMoment = _targetMoment.add(oneMinute);
        WatchUi.requestUpdate();
    }
    
    function decrementMinute() as Void {
        var oneMinute = new Time.Duration(60);
        _targetMoment = _targetMoment.subtract(oneMinute);
        WatchUi.requestUpdate();
    }
    
    function incrementSecond() as Void {
        var oneSecond = new Time.Duration(1);
        _targetMoment = _targetMoment.add(oneSecond);
        WatchUi.requestUpdate();
    }
    
    function decrementSecond() as Void {
        var oneSecond = new Time.Duration(1);
        _targetMoment = _targetMoment.subtract(oneSecond);
        WatchUi.requestUpdate();
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
        var now = Time.now();
        
        // Calculate current countdown
        var countdownSeconds = calculateCountdownSeconds(clockTime);
        
        // Use the static helper to calculate the snapped target time
        var snappedTime = calculateTargetTimeToSnapCountdownSecondsToZero(
            clockTime.hour, clockTime.min, clockTime.sec, countdownSeconds);
        
        // Update target moment by setting it to today at the snapped time
        setTargetMomentToTimeOfDay(snappedTime[:hour], snappedTime[:minute], snappedTime[:second]);
        
        WatchUi.requestUpdate();
    }
    
    // Helper function to set target moment to a specific time of day (handles day wrapping)
    private function setTargetMomentToTimeOfDay(hour as Number, minute as Number, second as Number) as Void {
        var now = Time.now();
        var nowInfo = Gregorian.info(now, Time.FORMAT_SHORT);
        
        // Get current target time components to calculate adjustment
        var currentTargetInfo = getTargetTimeInfo();
        
        // Calculate the difference in seconds between current target time and desired time
        var currentTargetSeconds = currentTargetInfo[:hour] * 3600 + currentTargetInfo[:minute] * 60 + currentTargetInfo[:second];
        var desiredSeconds = hour * 3600 + minute * 60 + second;
        var adjustmentSeconds = desiredSeconds - currentTargetSeconds;
        
        // Apply adjustment
        var adjustedMoment = _targetMoment.add(new Time.Duration(adjustmentSeconds));
        
        // Handle day wrapping: if the adjusted moment is in the past, add one day
        // This handles cases where the target time has wrapped to the next day
        if (adjustedMoment.lessThan(now)) {
            var oneDay = new Time.Duration(86400);
            adjustedMoment = adjustedMoment.add(oneDay);
        }
        
        _targetMoment = adjustedMoment;
    }

    function calculateCountdownSeconds(clockTime as System.ClockTime) as Number {
        var now = Time.now();
        var comparison = _targetMoment.compare(now);
        // If target < now (past), comparison is negative, return positive (elapsed)
        // If target > now (future), comparison is positive, return negative (countdown)
        return comparison;
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

