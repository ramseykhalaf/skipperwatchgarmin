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
        setLayout(Rez.Layouts.MainLayout(dc));

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
   
        // Calculate positions for Row 2 (50%)
        _row2Y = height / 2;
        _row2X = _centerX;
        
        // Calculate positions for Row 3 (80%)
        _row3Y = (height * 0.8).toNumber();
        
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
    }

    function onUpdate(dc as Dc) as Void {
        if (_delegate == null) {
            return;
        }

        // Update Clock Label
        var clockTime = System.getClockTime();
        var currentTimeStr = Lang.format("$1$:$2$:$3$", [
            clockTime.hour.format("%02d"),
            clockTime.min.format("%02d"),
            clockTime.sec.format("%02d")
        ]);
        var clockLabel = View.findDrawableById("ClockLabel") as WatchUi.Text;
        clockLabel.setText(currentTimeStr);
        
        // Update Countdown Label
        var timeDifference = _delegate.calculateCountdownSeconds(Time.now());
        var absDifference = timeDifference.abs();
        var hours = absDifference / 3600;
        var minutes = (absDifference % 3600) / 60;
        var seconds = absDifference % 60;
        
        _countdownStr = Lang.format("$1$$2$$3$$4$:$5$", [
            timeDifference < 0 ? "-" : "+",
            hours > 0 ? hours.format("%d") : "",
            hours > 0 ? ":" : "",
            minutes.format(hours > 0 ? "%02d" : "%d"),
            seconds.format("%02d")
        ]);

        var countdownLabel = View.findDrawableById("CountdownLabel") as WatchUi.Text;
        countdownLabel.setText(_countdownStr);
        
        // Set countdown font height and size once based on whether hours are present
        if (hours > 0) {
            _countdownFontHeight = _countdownHoursFontHeight;
            _countdownFontSize = COUNTDOWN_HOURS_FONT_SIZE;
        } else {
            _countdownFontHeight = _countdownMinutesFontHeight;
            _countdownFontSize = COUNTDOWN_MINUTES_FONT_SIZE;
        }
        countdownLabel.setFont(_countdownFontSize);

        // Update Target Label
        var targetInfo = Gregorian.info(_delegate.getTargetMoment(), Time.FORMAT_SHORT);
        var targetTimeStr = Lang.format("$1$:$2$:$3$", [
            targetInfo.hour.format("%02d"),
            targetInfo.min.format("%02d"),
            targetInfo.sec.format("%02d")
        ]);
        var targetLabel = View.findDrawableById("TargetLabel") as WatchUi.Text;
        targetLabel.setText(targetTimeStr);

        // Call the parent onUpdate to draw the layout
        View.onUpdate(dc);
        
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

