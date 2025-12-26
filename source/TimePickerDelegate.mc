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
        if (_view.isHoursMode()) {
            // Switch to minutes mode
            _view.setHoursMode(false);
        } else {
            // Calculate target time and push countdown view
            var targetHour = _view.getSelectedHour();
            var targetMinute = _view.getSelectedMinute();
            
            // Calculate target time in seconds since midnight
            var clockTime = System.getClockTime();
            var targetSeconds = targetHour * 3600 + targetMinute * 60;
            
            // Get current time in seconds since midnight
            var currentSeconds = clockTime.hour * 3600 + clockTime.min * 60 + clockTime.sec;
            
            // If target time is earlier today, assume it's for tomorrow
            if (targetSeconds <= currentSeconds) {
                targetSeconds += 86400; // Add 24 hours
            }
            
            WatchUi.pushView(new CountdownView(targetSeconds), new CountdownDelegate(), WatchUi.SLIDE_LEFT);
        }
        return true;
    }

    function onBack() as Boolean {
        if (_view.isHoursMode()) {
            // Exit app
            return false;
        } else {
            // Return to hours mode
            _view.setHoursMode(true);
            return true;
        }
    }

    function onUp() as Boolean {
        if (_view.isHoursMode()) {
            _view.incrementHour();
        } else {
            _view.incrementMinute();
        }
        return true;
    }

    function onDown() as Boolean {
        if (_view.isHoursMode()) {
            _view.decrementHour();
        } else {
            _view.decrementMinute();
        }
        return true;
    }
}

