import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class skipperwatchApp extends Application.AppBase {

    private var _recorder as TrackRecorder?;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up.
    // The recorder is created here but started by TimePickerView.onShow(), so
    // the GPS radio comes on with the screen that reports it - and stays off in
    // unit test runs, where no view is ever shown.
    function onStart(state as Dictionary?) as Void {
        _recorder = new TrackRecorder();
    }

    // onStop() is called when your application is exiting.
    // The normal exit path saves or discards via SaveMenu and then calls
    // System.exit(), so reaching here with a live session means the
    // app was killed. Save rather than discard, so a track is never lost.
    function onStop(state as Dictionary?) as Void {
        var recorder = _recorder;
        if (recorder != null && recorder.hasSession()) {
            recorder.save();
        }
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var timePickerView = new TimePickerView();
        var timePickerDelegate = new TimePickerDelegate();
        timePickerView.setDelegate(timePickerDelegate);
        timePickerView.setRecorder(_recorder);
        timePickerDelegate.setRecorder(_recorder);
        return [ timePickerView, timePickerDelegate ];
    }

}

function getApp() as skipperwatchApp {
    return Application.getApp() as skipperwatchApp;
}
