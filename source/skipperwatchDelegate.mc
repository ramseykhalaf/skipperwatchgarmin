import Toybox.Lang;
import Toybox.WatchUi;

class skipperwatchDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new skipperwatchMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}