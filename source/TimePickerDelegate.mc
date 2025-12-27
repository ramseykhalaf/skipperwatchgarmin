import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class TimePickerDelegate extends WatchUi.BehaviorDelegate {
    private var _view as TimePickerView;

    function initialize(view as TimePickerView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        var currentMode = _view.getMode();
        if (currentMode == :hours) {
            // Switch to minutes mode
            _view.setMode(:minutes);
        } else if (currentMode == :minutes) {
            // Switch to seconds mode
            _view.setMode(:seconds);
        } else if (currentMode == :seconds) {
            // Switch to sync mode
            _view.setMode(:sync);
        } else {
            // In sync mode, do nothing (or handle sync mode behavior later)
            // For now, just stay in sync mode
        }
        return true;
    }

    function onBack() as Boolean {
        var currentMode = _view.getMode();
        if (currentMode == :hours) {
            // Exit app
            return false;
        } else if (currentMode == :minutes) {
            // Return to hours mode
            _view.setMode(:hours);
            return true;
        } else if (currentMode == :seconds) {
            // Return to minutes mode
            _view.setMode(:minutes);
            return true;
        } else {
            // Return to seconds mode from sync mode
            _view.setMode(:seconds);
            return true;
        }
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        var currentMode = _view.getMode();
        if (key == WatchUi.KEY_UP) {
            if (currentMode == :hours) {
                _view.incrementHour();
            } else if (currentMode == :minutes) {
                _view.incrementMinute();
            } else if (currentMode == :seconds) {
                _view.incrementSecond();
            }
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            if (currentMode == :hours) {
                _view.decrementHour();
            } else if (currentMode == :minutes) {
                _view.decrementMinute();
            } else if (currentMode == :seconds) {
                _view.decrementSecond();
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
        var currentMode = _view.getMode();
        if (currentMode == :hours) {
            _view.incrementHour();
        } else if (currentMode == :minutes) {
            _view.incrementMinute();
        } else if (currentMode == :seconds) {
            _view.incrementSecond();
        }
        return true;
    }

    function onDown() as Boolean {
        var currentMode = _view.getMode();
        if (currentMode == :hours) {
            _view.decrementHour();
        } else if (currentMode == :minutes) {
            _view.decrementMinute();
        } else if (currentMode == :seconds) {
            _view.decrementSecond();
        }
        return true;
    }
}

