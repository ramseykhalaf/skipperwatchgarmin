import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Timer;
import Toybox.WatchUi;

class TimePickerView extends WatchUi.View {
    private const HIGHLIGHT_VERTICAL_SPACE = 0;
    private const HIGHLIGHT_HORIZONTAL_SPACE = 0;

    private const COUNTDOWN_MINUTES_FONT_SIZE = Graphics.FONT_NUMBER_THAI_HOT;
    private const COUNTDOWN_HOURS_FONT_SIZE = Graphics.FONT_NUMBER_HOT;
    private const TARGET_FONT_SIZE = Graphics.FONT_NUMBER_MEDIUM;
    
    private var _delegate as TimePickerDelegate?;
    private var _timer as Timer.Timer;
    
    // Stored positions
    private var _countdownFontHeight as Number;
    private var _countdownFontSize; // Graphics.FontReference - stored font constant
    private var _targetFontHeight as Number;
    private var _targetDoubleDigitFontWidth as Number;
    
    // Countdown font dimensions (stored for both font sizes to avoid recalculating on every update)
    private var _countdownHoursFontHeight as Number;
    private var _countdownMinutesFontHeight as Number;
    
    // Time picker positions
    private var _targetHourX as Number;
    private var _targetMinuteX as Number;
    private var _targetSecondX as Number;
    private var _targetY as Number;

    // Countdown positions
    private var _countdownX as Number;
    private var _countdownY as Number;
    private var _countdownStr as String;
    
    function initialize() {
        View.initialize();
        
        // Initialize position variables (will be set properly in onLayout)
        _targetHourX = 0;
        _targetMinuteX = 0;
        _targetSecondX = 0;
        _targetY = 0;

        _countdownX = 0;
        _countdownY = 0;
        
        _countdownFontHeight = 0;
        _countdownFontSize = COUNTDOWN_MINUTES_FONT_SIZE;
        _targetFontHeight = 0;
        _targetDoubleDigitFontWidth = 0;
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
        _countdownHoursFontHeight = dc.getFontHeight(COUNTDOWN_HOURS_FONT_SIZE);
        _countdownMinutesFontHeight = dc.getFontHeight(COUNTDOWN_MINUTES_FONT_SIZE);
        
        _targetFontHeight = dc.getFontHeight(TARGET_FONT_SIZE);
        _targetDoubleDigitFontWidth = dc.getTextWidthInPixels("00", Graphics.FONT_NUMBER_MEDIUM);
        
        // Update stored positions by querying the layout elements
        var countdownLabel = View.findDrawableById("CountdownLabel") as WatchUi.Text;
        if (countdownLabel != null) {
            _countdownX = countdownLabel.locX;
            _countdownY = countdownLabel.locY;
        }

        var targetHH = View.findDrawableById("TargetHH") as WatchUi.Text;
        if (targetHH != null) {
            _targetHourX = targetHH.locX;
            _targetY = targetHH.locY;
        }

        var targetMM = View.findDrawableById("TargetMM") as WatchUi.Text;
        if (targetMM != null) {
            _targetMinuteX = targetMM.locX;
        }

        var targetSS = View.findDrawableById("TargetSS") as WatchUi.Text;
        if (targetSS != null) {
            _targetSecondX = targetSS.locX;
        }
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

        // Update Target Labels
        var targetInfo = Gregorian.info(_delegate.getTargetMoment(), Time.FORMAT_SHORT);
        (View.findDrawableById("TargetHH") as WatchUi.Text).setText(targetInfo.hour.format("%02d"));
        (View.findDrawableById("TargetColon1") as WatchUi.Text).setText(":");
        (View.findDrawableById("TargetMM") as WatchUi.Text).setText(targetInfo.min.format("%02d"));
        (View.findDrawableById("TargetColon2") as WatchUi.Text).setText(":");
        (View.findDrawableById("TargetSS") as WatchUi.Text).setText(targetInfo.sec.format("%02d"));

        // Update divider colors based on countdown state
        var dividerColor = timeDifference < 0 ? Graphics.COLOR_RED : Graphics.COLOR_GREEN;
        (View.findDrawableById("Divider1") as DividerDrawable).setColor(dividerColor);
        (View.findDrawableById("Divider2") as DividerDrawable).setColor(dividerColor);

        // Call the parent onUpdate to draw the layout
        View.onUpdate(dc);
        
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
        var highlightY = _targetY - (targetHighlightHeight / 2);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        if (mode == :hours) {
            dc.drawRectangle(_targetHourX - (targetHighlightWidth / 2), highlightY, targetHighlightWidth, targetHighlightHeight);
        } else if (mode == :minutes) {
            dc.drawRectangle(_targetMinuteX - (targetHighlightWidth / 2), highlightY, targetHighlightWidth, targetHighlightHeight);
        } else if (mode == :seconds) {
            dc.drawRectangle(_targetSecondX - (targetHighlightWidth / 2), highlightY, targetHighlightWidth, targetHighlightHeight);
        } else if (mode == :countdown) {

            var countdownHighlightHeight = _countdownFontHeight + (HIGHLIGHT_VERTICAL_SPACE * 2);
            var countdownHighlightWidth = dc.getTextWidthInPixels(_countdownStr, _countdownFontSize) + (HIGHLIGHT_HORIZONTAL_SPACE * 2);
            var countdownHighlightY = _countdownY - (countdownHighlightHeight / 2);
            dc.drawRectangle(_countdownX - (countdownHighlightWidth / 2), countdownHighlightY, countdownHighlightWidth, countdownHighlightHeight);
        }
    }
}

