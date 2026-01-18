import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Timer;
import Toybox.WatchUi;

class TimePickerView extends WatchUi.View {
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

    // Pre-computed negative signed string lookups for countdown minutes (0-59)
    private static var NEGATIVE_SIGNED_60 as Array<String> = [
        "-0", "-1", "-2", "-3", "-4", "-5", "-6", "-7", "-8", "-9",
        "-10", "-11", "-12", "-13", "-14", "-15", "-16", "-17", "-18", "-19",
        "-20", "-21", "-22", "-23", "-24", "-25", "-26", "-27", "-28", "-29",
        "-30", "-31", "-32", "-33", "-34", "-35", "-36", "-37", "-38", "-39",
        "-40", "-41", "-42", "-43", "-44", "-45", "-46", "-47", "-48", "-49",
        "-50", "-51", "-52", "-53", "-54", "-55", "-56", "-57", "-58", "-59"
    ];

    // Pre-computed positive signed string lookups for countdown minutes (0-59)
    private static var POSITIVE_SIGNED_60 as Array<String> = [
        "+0", "+1", "+2", "+3", "+4", "+5", "+6", "+7", "+8", "+9",
        "+10", "+11", "+12", "+13", "+14", "+15", "+16", "+17", "+18", "+19",
        "+20", "+21", "+22", "+23", "+24", "+25", "+26", "+27", "+28", "+29",
        "+30", "+31", "+32", "+33", "+34", "+35", "+36", "+37", "+38", "+39",
        "+40", "+41", "+42", "+43", "+44", "+45", "+46", "+47", "+48", "+49",
        "+50", "+51", "+52", "+53", "+54", "+55", "+56", "+57", "+58", "+59"
    ];

    private var _delegate as TimePickerDelegate?;
    private var _timer as Timer.Timer;

    // Cached drawable references - Clock
    private var _clockHH;
    private var _clockMM;
    private var _clockSS;

    // Cached drawable references - Countdown with hours row
    private var _countdownHoursHH;
    private var _countdownHoursMM;
    private var _countdownHoursSS;

    // Cached drawable references - Countdown without hours row
    private var _countdownMinutesMM;
    private var _countdownMinutesSS;

    // Cached drawable references - Countdown colons
    private var _countdownHoursColon1;
    private var _countdownHoursColon2;
    private var _countdownMinutesColon;

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

    // Track which countdown row is visible
    private var _hoursRowVisible as Boolean = false;

    function initialize() {
        View.initialize();
        _hoursRowVisible = false;

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

        // Cache drawable references - Countdown with hours row
        _countdownHoursHH = View.findDrawableById("CountdownHoursHH") as WatchUi.Text;
        _countdownHoursMM = View.findDrawableById("CountdownHoursMM") as WatchUi.Text;
        _countdownHoursSS = View.findDrawableById("CountdownHoursSS") as WatchUi.Text;

        // Cache drawable references - Countdown without hours row
        _countdownMinutesMM = View.findDrawableById("CountdownMinutesMM") as WatchUi.Text;
        _countdownMinutesSS = View.findDrawableById("CountdownMinutesSS") as WatchUi.Text;

        // Cache drawable references - Countdown colons
        _countdownHoursColon1 = View.findDrawableById("CountdownHoursColon1") as WatchUi.Text;
        _countdownHoursColon2 = View.findDrawableById("CountdownHoursColon2") as WatchUi.Text;
        _countdownMinutesColon = View.findDrawableById("CountdownMinutesColon") as WatchUi.Text;

        // Initialize countdown row visibility (mins row visible by default)
        _countdownHoursHH.setVisible(false);
        _countdownHoursMM.setVisible(false);
        _countdownHoursSS.setVisible(false);
        _countdownHoursColon1.setVisible(false);
        _countdownHoursColon2.setVisible(false);
        _hoursRowVisible = false;

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

        // Update countdown - use two overlapping rows, toggle visibility
        var sign = timeDifference < 0 ? "-" : "+";
        var hoursPresent = hours > 0;

        if (hoursPresent) {
            // Show hours row, hide mins row
            var hoursIndex = hours < 60 ? hours : 59;
            _countdownHoursHH.setText(timeDifference < 0 ? NEGATIVE_SIGNED_60[hoursIndex] : POSITIVE_SIGNED_60[hoursIndex]);
            _countdownHoursMM.setText(PADDED_60[minutes]);
            _countdownHoursSS.setText(PADDED_60[seconds]);

            if (!_hoursRowVisible) {
                _countdownHoursHH.setVisible(true);
                _countdownHoursMM.setVisible(true);
                _countdownHoursSS.setVisible(true);
                _countdownHoursColon1.setVisible(true);
                _countdownHoursColon2.setVisible(true);
                _countdownMinutesMM.setVisible(false);
                _countdownMinutesSS.setVisible(false);
                _countdownMinutesColon.setVisible(false);
                _hoursRowVisible = true;
            }
        } else {
            // Show mins row, hide hours row
            _countdownMinutesMM.setText(timeDifference < 0 ? NEGATIVE_SIGNED_60[minutes] : POSITIVE_SIGNED_60[minutes]);
            _countdownMinutesSS.setText(PADDED_60[seconds]);

            if (_hoursRowVisible) {
                _countdownHoursHH.setVisible(false);
                _countdownHoursMM.setVisible(false);
                _countdownHoursSS.setVisible(false);
                _countdownHoursColon1.setVisible(false);
                _countdownHoursColon2.setVisible(false);
                _countdownMinutesMM.setVisible(true);
                _countdownMinutesSS.setVisible(true);
                _countdownMinutesColon.setVisible(true);
                _hoursRowVisible = false;
            }
        }

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

