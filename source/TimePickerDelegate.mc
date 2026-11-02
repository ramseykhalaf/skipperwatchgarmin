import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class TimePickerDelegate extends WatchUi.BehaviorDelegate {
    private var _targetMoment as Time.Moment;
    private var _mode as Symbol; // :idle (just viewing), :hours, :minutes, :seconds
    private var _recorder as TrackRecorder?;
    private var _view as TimePickerView?;

    function initialize() {
        BehaviorDelegate.initialize();

        // Initialize to current time + 3 minutes, rounded to nearest minute
        var now = getCurrentTime();
        var threeMinutes = new Time.Duration(180); // 3 minutes in seconds
        _targetMoment = now.add(threeMinutes);
        
        // Use local helper to initialize target time info
        var targetInfo = Gregorian.info(_targetMoment, Time.FORMAT_SHORT);
        _targetMoment = setTargetMomentToTimeOfDay(_targetMoment, targetInfo.hour, targetInfo.min, 0);
        
        _mode = :idle;
    }

    function setRecorder(recorder as TrackRecorder?) as Void {
        _recorder = recorder;
    }

    function setView(view as TimePickerView) as Void {
        _view = view;
    }

    function getCurrentTime() as Time.Moment {
        return Time.now();
    }

    function getTargetMoment() as Time.Moment {
        return _targetMoment;
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
    
    function setCountdownSecondsToZero() as Void {
        var clockTime = System.getClockTime();
        var countdownSeconds = calculateCountdownSeconds(getCurrentTime());
        var snappedTime = calculateTargetTimeToSnapCountdownSecondsToZero(
            clockTime.hour, clockTime.min, clockTime.sec, countdownSeconds);
        _targetMoment = setTargetMomentToTimeOfDay(_targetMoment, snappedTime[:hour], snappedTime[:minute], snappedTime[:second]);
        WatchUi.requestUpdate();
    }

    function calculateCountdownSeconds(currentMoment as Time.Moment) as Number {
        return currentMoment.compare(_targetMoment);
    }

    static function setTargetMomentToTimeOfDay(moment as Time.Moment, hour as Number, minute as Number, second as Number) as Time.Moment {
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        var duration = new Time.Duration(
            (hour - info.hour) * 3600 +
            (minute - info.min) * 60 +
            (second - info.sec)
        );
        return moment.add(duration);
    }

    static function calculateTargetTimeToSnapCountdownSecondsToZero(
        clockHour as Number, clockMinute as Number, clockSecond as Number, countdownSeconds as Number) as Dictionary {
        
        var currentTotalSeconds = clockHour * 3600 + clockMinute * 60 + clockSecond;
        var absCountdownSeconds = countdownSeconds.abs();
        var countdownSecondComponent = absCountdownSeconds % 60;
        var roundUpMinute = (countdownSecondComponent >= 30) ? 1 : 0;
        
        var roundedCountdownMinutes = (absCountdownSeconds / 60) + roundUpMinute;
        var roundedCountdown = (countdownSeconds < 0 ? -1 : 1) * roundedCountdownMinutes * 60;
        
        var targetTotalSeconds = currentTotalSeconds - roundedCountdown;
        
        while (targetTotalSeconds < 0) {
            targetTotalSeconds += 86400;
        }
        targetTotalSeconds = targetTotalSeconds % 86400;
        
        var targetHour = targetTotalSeconds / 3600;
        var targetMinute = (targetTotalSeconds % 3600) / 60;
        var targetSecond = targetTotalSeconds % 60;
        
        return {
            :hour => targetHour,
            :minute => targetMinute,
            :second => targetSecond
        };
    }

    // Seconds after the gun at which the countdown screen hands over to the
    // race (COG/SOG) screen on its own, whatever is selected.
    const RACE_SCREEN_DELAY_SECONDS = 10;

    // True on the tick where the countdown passes RACE_SCREEN_DELAY_SECONDS
    // after the gun. Only the crossing counts, so returning to the countdown
    // screen later in the race does not bounce straight back to the race
    // screen, but pushing the target out for a recall arms it again.
    static function didRaceStart(previousCountdownSeconds as Number?, countdownSeconds as Number) as Boolean {
        return (previousCountdownSeconds != null)
            && (previousCountdownSeconds < RACE_SCREEN_DELAY_SECONDS)
            && (countdownSeconds >= RACE_SCREEN_DELAY_SECONDS);
    }

    // START steps into the timer: nothing -> hours -> minutes -> seconds. On
    // seconds, START snaps the countdown to the nearest whole minute.
    function onSelect() as Boolean {
        if (_mode == :idle) {
            setMode(:hours);
        } else if (_mode == :hours) {
            setMode(:minutes);
        } else if (_mode == :minutes) {
            setMode(:seconds);
        } else if (_mode == :seconds) {
            setCountdownSecondsToZero();
        }
        return true;
    }

    // Backing out with nothing selected exits the app, which is the moment a
    // recorded track has to be saved or thrown away.
    function shouldPromptToSaveTrack() as Boolean {
        var recorder = _recorder;
        return (_mode == :idle) && (recorder != null) && recorder.hasSession();
    }

    // BACK steps out of the timer: seconds -> minutes -> hours -> nothing.
    // With nothing selected it exits, via the save menu while recording.
    function onBack() as Boolean {
        if (_mode == :seconds) {
            setMode(:minutes);
            return true;
        } else if (_mode == :minutes) {
            setMode(:hours);
            return true;
        } else if (_mode == :hours) {
            setMode(:idle);
            return true;
        }
        if (shouldPromptToSaveTrack()) {
            // Save and Discard exit the app; Resume returns here.
            SaveMenu.push(_recorder as TrackRecorder);
            return true;
        }
        return false;
    }

    // UP adjusts the selected field, or with nothing selected switches to the
    // race screen.
    function handleUp() as Boolean {
        if (_mode == :hours) {
            incrementHour();
        } else if (_mode == :minutes) {
            incrementMinute();
        } else if (_mode == :seconds) {
            incrementSecond();
        } else {
            showRaceScreen(WatchUi.SLIDE_DOWN);
        }
        return true;
    }

    function handleDown() as Boolean {
        if (_mode == :hours) {
            decrementHour();
        } else if (_mode == :minutes) {
            decrementMinute();
        } else if (_mode == :seconds) {
            decrementSecond();
        } else {
            showRaceScreen(WatchUi.SLIDE_UP);
        }
        return true;
    }

    // Swap the countdown screen for the race screen. Clears the selection,
    // so coming back shows the timer with nothing selected.
    function showRaceScreen(transition as WatchUi.SlideType) as Void {
        _mode = :idle;
        var view = _view;
        var recorder = _recorder;
        if (view == null || recorder == null) {
            return;
        }
        WatchUi.switchToView(new RaceView(recorder), new RaceDelegate(view, self), transition);
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP) {
            return handleUp();
        } else if (key == WatchUi.KEY_DOWN) {
            return handleDown();
        } else if (key == WatchUi.KEY_ENTER) {
            return onSelect();
        } else if (key == WatchUi.KEY_ESC) {
            return onBack();
        }
        return false;
    }

    function onPreviousPage() as Boolean {
        return handleUp();
    }

    function onNextPage() as Boolean {
        return handleDown();
    }
}

// Input for the race screen: UP, DOWN or BACK all return to the countdown
// screen (BACK does not exit, so a stray press mid-race is harmless).
class RaceDelegate extends WatchUi.BehaviorDelegate {
    private var _timerView as TimePickerView;
    private var _timerDelegate as TimePickerDelegate;

    function initialize(timerView as TimePickerView, timerDelegate as TimePickerDelegate) {
        BehaviorDelegate.initialize();
        _timerView = timerView;
        _timerDelegate = timerDelegate;
    }

    function showTimer(transition as WatchUi.SlideType) as Boolean {
        _timerDelegate.setMode(:idle);
        WatchUi.switchToView(_timerView, _timerDelegate, transition);
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP) {
            return showTimer(WatchUi.SLIDE_DOWN);
        } else if (key == WatchUi.KEY_DOWN) {
            return showTimer(WatchUi.SLIDE_UP);
        } else if (key == WatchUi.KEY_ESC) {
            return showTimer(WatchUi.SLIDE_DOWN);
        }
        return false;
    }

    function onPreviousPage() as Boolean {
        return showTimer(WatchUi.SLIDE_DOWN);
    }

    function onNextPage() as Boolean {
        return showTimer(WatchUi.SLIDE_UP);
    }

    function onBack() as Boolean {
        return showTimer(WatchUi.SLIDE_DOWN);
    }
}
