import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class skipperwatchApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var timePickerView = new TimePickerView();
        var timePickerDelegate = new TimePickerDelegate(timePickerView);
        timePickerView.setDelegate(timePickerDelegate);
        return [ timePickerView, timePickerDelegate ];
    }

}

function getApp() as skipperwatchApp {
    return Application.getApp() as skipperwatchApp;
}