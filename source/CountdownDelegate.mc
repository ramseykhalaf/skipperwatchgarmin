import Toybox.Lang;
import Toybox.WatchUi;

class CountdownDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Boolean {
        // Return to time picker
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

