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
    
    private var _delegate as TimePickerDelegate?;
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
        
        // Create timer to update current time display every second
        _timer = new Timer.Timer();
    }

    function setDelegate(delegate as TimePickerDelegate) as Void {
        _delegate = delegate;
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
        if (_delegate == null) {
            return;
        }

        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var clockTime = System.getClockTime();
        
        // Calculate positions for Row 1 (top - current time)
        var row1Y = _row2Y - _countdownMinutesFontHeight/2 - ROW_SPACE - _clockFontHeight/2;
        
        // Draw Row 1: Current system time
        drawClockTime(dc, clockTime, _centerX, row1Y);
        
        // Draw Row 2: Countdown timer
        var timeDifference = _delegate.calculateCountdownSeconds(Time.now());
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
        var targetInfo = Gregorian.info(_delegate.getTargetMoment(), Time.FORMAT_SHORT);
        drawTargetTime(dc, targetInfo.hour, targetInfo.min, targetInfo.sec, _centerX, _row3Y);
        
        // Draw horizontal lines between rows at half ROW_SPACE, accounting for font height
        var lineY1 = _row2Y - _countdownMinutesFontHeight/2 - ROW_SPACE/2;
        var lineY2 = _row2Y + _countdownMinutesFontHeight/2 - ROW_SPACE/2;
        drawDividers(dc, timeDifference, lineY1, lineY2);
        
        // Draw white outline boxes for active field on top (custom drawing)
        drawSelectorHighlight(dc);
    }
    
    function drawSelectorHighlight(dc as Dc) as Void {
        if (_delegate == null) {
            return;
        }
        var mode = _delegate.getMode();
        var targetHighlightHeight = _targetFontHeight + (HIGHLIGHT_VERTICAL_SPACE * 2);
        var targetHighlightWidth = _targetDoubleDigitFontWidth + (HIGHLIGHT_HORIZONTAL_SPACE * 2);
        var highlightY = _row3Y - (targetHighlightHeight / 2);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        if (mode == :hours) {
            dc.drawRectangle(_hourX - (targetHighlightWidth / 2), highlightY, targetHighlightWidth, targetHighlightHeight);
        } else if (mode == :minutes) {
            dc.drawRectangle(_minuteX - (targetHighlightWidth / 2), highlightY, targetHighlightWidth, targetHighlightHeight);
        } else if (mode == :seconds) {
            dc.drawRectangle(_secondX - (targetHighlightWidth / 2), highlightY, targetHighlightWidth, targetHighlightHeight);
        } else if (mode == :countdown) {

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
}

