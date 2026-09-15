import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// The end-of-session menu, shown when backing out of the app while a track is
// recording. Uses native Menu2 so UP/DOWN cycle options, START selects and
// BACK returns, exactly like the built-in activity save screen.
//
//   <elapsed time>  <distance>
//   - Resume   back to the timer, still recording
//   - Save     save the track and quit
//   - Discard  -> "Discard?" No / Yes (No focused)
class SaveMenu {

    static function push(recorder as TrackRecorder) as Void {
        var statute = System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE;
        var menu = new WatchUi.Menu2({
            :title => formatTitle(recorder.getElapsedSeconds(), recorder.getDistanceMeters(), statute)
        });
        menu.addItem(new WatchUi.MenuItem(loadString(Rez.Strings.MenuResume), null, :resume, null));
        menu.addItem(new WatchUi.MenuItem(loadString(Rez.Strings.MenuSave), null, :save, null));
        menu.addItem(new WatchUi.MenuItem(loadString(Rez.Strings.MenuDiscard), null, :discard, null));
        WatchUi.pushView(menu, new SaveMenuDelegate(recorder), WatchUi.SLIDE_UP);
    }

    static function pushDiscard(recorder as TrackRecorder) as Void {
        // No comes first so it has focus: a stray START press keeps the track.
        var menu = new WatchUi.Menu2({ :title => loadString(Rez.Strings.DiscardTitle), :focus => 0 });
        menu.addItem(new WatchUi.MenuItem(loadString(Rez.Strings.MenuNo), null, :no, null));
        menu.addItem(new WatchUi.MenuItem(loadString(Rez.Strings.MenuYes), null, :yes, null));
        WatchUi.pushView(menu, new DiscardMenuDelegate(recorder), WatchUi.SLIDE_LEFT);
    }

    // "42:10  4.20 km", or "1:02:05  --" before any distance is known.
    static function formatTitle(elapsedSeconds as Number, distanceMeters as Float?, statute as Boolean) as String {
        var hours = elapsedSeconds / 3600;
        var minutes = (elapsedSeconds % 3600) / 60;
        var seconds = elapsedSeconds % 60;

        var time;
        if (hours > 0) {
            time = hours + ":" + minutes.format("%02d") + ":" + seconds.format("%02d");
        } else {
            time = minutes + ":" + seconds.format("%02d");
        }

        var distance = "--";
        if (distanceMeters != null) {
            if (statute) {
                distance = (distanceMeters / 1609.344).format("%.2f") + " mi";
            } else {
                distance = (distanceMeters / 1000.0).format("%.2f") + " km";
            }
        }

        return time + "  " + distance;
    }

    private static function loadString(id as ResourceId) as String {
        return WatchUi.loadResource(id) as String;
    }
}

class SaveMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _recorder as TrackRecorder;

    function initialize(recorder as TrackRecorder) {
        Menu2InputDelegate.initialize();
        _recorder = recorder;
    }

    // BACK uses the default behaviour: pop back to the timer, same as Resume.
    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :resume) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :save) {
            _recorder.save();
            System.exit();
        } else if (id == :discard) {
            SaveMenu.pushDiscard(_recorder);
        }
    }
}

class DiscardMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _recorder as TrackRecorder;

    function initialize(recorder as TrackRecorder) {
        Menu2InputDelegate.initialize();
        _recorder = recorder;
    }

    // BACK uses the default behaviour: pop back to the save menu, same as No.
    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :yes) {
            _recorder.discard();
            System.exit();
        } else {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}
