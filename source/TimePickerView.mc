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
    
    private var _delegate as TimePickerDelegate?;
    private var _timer as Timer.Timer;
    
    // Stored font dimensions
    private var _countdownFontSize; // Graphics.FontReference - stored font constant
    
    private var _countdownStr as String;
    
    function initialize() {
        View.initialize();
        
        _countdownFontSize = COUNTDOWN_MINUTES_FONT_SIZE;

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
            _countdownFontSize = COUNTDOWN_HOURS_FONT_SIZE;
        } else {
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

        // Update highlights visibility
        var mode = _delegate.getMode();
        (View.findDrawableById("HighlightHH") as HighlightDrawable).setVisible(mode == :hours);
        (View.findDrawableById("HighlightMM") as HighlightDrawable).setVisible(mode == :minutes);
        (View.findDrawableById("HighlightSS") as HighlightDrawable).setVisible(mode == :seconds);
        (View.findDrawableById("HighlightCountdown") as HighlightDrawable).setVisible(mode == :countdown);

        // Call the parent onUpdate to draw the layout
        View.onUpdate(dc);
    }
}

