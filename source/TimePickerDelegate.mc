import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class TimePickerDelegate extends WatchUi.BehaviorDelegate {
    private var _targetMoment as Time.Moment;
    private var _mode as Symbol; // :hours, :minutes, :seconds, :countdown

    function initialize() {
        BehaviorDelegate.initialize();

        // Initialize to current time + 3 minutes, rounded to nearest minute
        var now = getCurrentTime();
        var threeMinutes = new Time.Duration(180); // 3 minutes in seconds
        _targetMoment = now.add(threeMinutes);
        
        // Use local helper to initialize target time info
        var targetInfo = Gregorian.info(_targetMoment, Time.FORMAT_SHORT);
        _targetMoment = setTargetMomentToTimeOfDay(_targetMoment, targetInfo.hour, targetInfo.min, 0);
        
        _mode = :minutes;
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
    
    function incrementCountdown() as Void {
        incrementSecond();
    }
    
    function decrementCountdown() as Void {
        decrementSecond();
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

    function onSelect() as Boolean {
        if (_mode == :hours) {
            setMode(:minutes);
        } else if (_mode == :minutes) {
            setMode(:seconds);
        } else if (_mode == :seconds) {
            setMode(:countdown);
        } else {
            setCountdownSecondsToZero();
        }
        return true;
    }

    function onBack() as Boolean {
        if (_mode == :hours) {
            return false;
        } else if (_mode == :minutes) {
            setMode(:hours);
            return true;
        } else if (_mode == :seconds) {
            setMode(:minutes);
            return true;
        } else {
            setMode(:seconds);
            return true;
        }
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP) {
            if (_mode == :hours) {
                incrementHour();
            } else if (_mode == :minutes) {
                incrementMinute();
            } else if (_mode == :seconds) {
                incrementSecond();
            } else if (_mode == :countdown) {
                incrementCountdown();
            }
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            if (_mode == :hours) {
                decrementHour();
            } else if (_mode == :minutes) {
                decrementMinute();
            } else if (_mode == :seconds) {
                decrementSecond();
            } else if (_mode == :countdown) {
                decrementCountdown();
            }
            return true;
        } else if (key == WatchUi.KEY_ENTER) {
            return onSelect();
        } else if (key == WatchUi.KEY_ESC) {
            return onBack();
        }
        return false;
    }

    function onUp() as Boolean {
        if (_mode == :hours) {
            incrementHour();
        } else if (_mode == :minutes) {
            incrementMinute();
        } else if (_mode == :seconds) {
            incrementSecond();
        }
        return true;
    }

    function onDown() as Boolean {
        if (_mode == :hours) {
            decrementHour();
        } else if (_mode == :minutes) {
            decrementMinute();
        } else if (_mode == :seconds) {
            decrementSecond();
        }
        return true;
    }
}

