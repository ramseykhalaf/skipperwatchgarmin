import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Timer;
import Toybox.WatchUi;

class TimePickerView extends WatchUi.View {
    private const COUNTDOWN_MINUTES_FONT_SIZE = Graphics.FONT_NUMBER_THAI_HOT;
    private const COUNTDOWN_HOURS_FONT_SIZE = Graphics.FONT_NUMBER_HOT;

    // Pre-computed string lookups for minutes/seconds/hours (0-59, hours use 0-23)
    private static var PADDED_60 as Array<String> = [
        "00", "01", "02", "03", "04", "05", "06", "07", "08", "09",
        "10", "11", "12", "13", "14", "15", "16", "17", "18", "19",
        "20", "21", "22", "23", "24", "25", "26", "27", "28", "29",
        "30", "31", "32", "33", "34", "35", "36", "37", "38", "39",
        "40", "41", "42", "43", "44", "45", "46", "47", "48", "49",
        "50", "51", "52", "53", "54", "55", "56", "57", "58", "59"
    ];

    // Pre-computed unpadded string lookups for countdown minutes (0-59)
    private static var UNPADDED_60 as Array<String> = [
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "10", "11", "12", "13", "14", "15", "16", "17", "18", "19",
        "20", "21", "22", "23", "24", "25", "26", "27", "28", "29",
        "30", "31", "32", "33", "34", "35", "36", "37", "38", "39",
        "40", "41", "42", "43", "44", "45", "46", "47", "48", "49",
        "50", "51", "52", "53", "54", "55", "56", "57", "58", "59"
    ];

    private var _delegate as TimePickerDelegate?;
    private var _timer as Timer.Timer;

    // Stored font dimensions
    private var _countdownFontSize; // Graphics.FontReference - stored font constant

    // Cached drawable references - Clock
    private var _clockHH;
    private var _clockMM;
    private var _clockSS;

    // Cached drawable references - Countdown
    private var _countdownSign;
    private var _countdownHH;
    private var _countdownColon1;
    private var _countdownMM;
    private var _countdownSS;

    // Cached drawable references - Target
    private var _targetHH;
    private var _targetMM;
    private var _targetSS;

    // Cached drawable references - Dividers and Highlights
    private var _divider1;
    private var _divider2;
    private var _highlightHH;
    private var _highlightMM;
    private var _highlightSS;
    private var _highlightCountdown;

    function initialize() {
        View.initialize();

        _countdownFontSize = COUNTDOWN_MINUTES_FONT_SIZE;

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

        // Cache drawable references - Clock
        _clockHH = View.findDrawableById("ClockHH") as WatchUi.Text;
        _clockMM = View.findDrawableById("ClockMM") as WatchUi.Text;
        _clockSS = View.findDrawableById("ClockSS") as WatchUi.Text;

        // Cache drawable references - Countdown
        _countdownSign = View.findDrawableById("CountdownSign") as WatchUi.Text;
        _countdownHH = View.findDrawableById("CountdownHH") as WatchUi.Text;
        _countdownColon1 = View.findDrawableById("CountdownColon1") as WatchUi.Text;
        _countdownMM = View.findDrawableById("CountdownMM") as WatchUi.Text;
        _countdownSS = View.findDrawableById("CountdownSS") as WatchUi.Text;

        // Cache drawable references - Target
        _targetHH = View.findDrawableById("TargetHH") as WatchUi.Text;
        _targetMM = View.findDrawableById("TargetMM") as WatchUi.Text;
        _targetSS = View.findDrawableById("TargetSS") as WatchUi.Text;

        // Cache drawable references - Dividers and Highlights
        _divider1 = View.findDrawableById("Divider1") as DividerDrawable;
        _divider2 = View.findDrawableById("Divider2") as DividerDrawable;
        _highlightHH = View.findDrawableById("HighlightHH") as HighlightDrawable;
        _highlightMM = View.findDrawableById("HighlightMM") as HighlightDrawable;
        _highlightSS = View.findDrawableById("HighlightSS") as HighlightDrawable;
        _highlightCountdown = View.findDrawableById("HighlightCountdown") as HighlightDrawable;
    }

    function onUpdate(dc as Dc) as Void {
        if (_delegate == null) {
            return;
        }

        // Update Clock Labels using string lookups
        var clockTime = System.getClockTime();
        _clockHH.setText(PADDED_60[clockTime.hour]);
        _clockMM.setText(PADDED_60[clockTime.min]);
        _clockSS.setText(PADDED_60[clockTime.sec]);

        // Update Countdown Labels
        var timeDifference = _delegate.calculateCountdownSeconds(Time.now());
        var absDifference = timeDifference.abs();
        var hours = absDifference / 3600;
        var minutes = (absDifference % 3600) / 60;
        var seconds = absDifference % 60;

        // Update countdown sign
        _countdownSign.setText(timeDifference < 0 ? "-" : "+");

        // Update countdown hours (show/hide based on whether hours > 0)
        if (hours > 0) {
            _countdownHH.setText(hours.format("%d"));
            _countdownColon1.setText(":");
            _countdownMM.setText(PADDED_60[minutes]);
            _countdownFontSize = COUNTDOWN_HOURS_FONT_SIZE;
        } else {
            _countdownHH.setText("");
            _countdownColon1.setText("");
            _countdownMM.setText(UNPADDED_60[minutes]);
            _countdownFontSize = COUNTDOWN_MINUTES_FONT_SIZE;
        }
        _countdownSS.setText(PADDED_60[seconds]);

        // Set countdown font size based on whether hours are present
        _countdownSign.setFont(_countdownFontSize);
        _countdownHH.setFont(_countdownFontSize);
        _countdownColon1.setFont(_countdownFontSize);
        _countdownMM.setFont(_countdownFontSize);
        _countdownSS.setFont(_countdownFontSize);

        // Update Target Labels using string lookups
        var targetInfo = Gregorian.info(_delegate.getTargetMoment(), Time.FORMAT_SHORT);
        _targetHH.setText(PADDED_60[targetInfo.hour]);
        _targetMM.setText(PADDED_60[targetInfo.min]);
        _targetSS.setText(PADDED_60[targetInfo.sec]);

        // Update divider colors based on countdown state
        var dividerColor = timeDifference < 0 ? Graphics.COLOR_RED : Graphics.COLOR_GREEN;
        _divider1.setColor(dividerColor);
        _divider2.setColor(dividerColor);

        // Update highlights visibility
        var mode = _delegate.getMode();
        _highlightHH.setVisible(mode == :hours);
        _highlightMM.setVisible(mode == :minutes);
        _highlightSS.setVisible(mode == :seconds);
        _highlightCountdown.setVisible(mode == :seconds);

        // Call the parent onUpdate to draw the layout
        View.onUpdate(dc);
    }
}

