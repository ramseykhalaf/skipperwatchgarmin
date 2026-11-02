import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Reports a live session without touching ActivityRecording, so the exit
// decision can be tested without a real FIT session.
(:test)
class FakeTrackRecorder extends TrackRecorder {
    private var _hasSession as Boolean;

    function initialize(hasSession as Boolean) {
        TrackRecorder.initialize();
        _hasSession = hasSession;
    }

    function hasSession() as Boolean {
        return _hasSession;
    }
}

// Static helper on a separate class: a bare (:test) function would be collected
// and run as a test in its own right, and (:test) entry points are invoked
// without an instance, so the call has to be class-qualified.
(:test)
class TrackRecordingFixtures {
    static function makeDelegate(recorder as TrackRecorder?) as TestableTimePickerDelegate {
        var mockNow = Gregorian.moment({
            :year => 2024, :month => 1, :day => 1,
            :hour => 11, :minute => 22, :second => 33
        });
        var delegate = new TestableTimePickerDelegate(mockNow);
        delegate.setRecorder(recorder);
        return delegate;
    }
}

(:test)
class TrackRecordingTest {

    // Exiting with a recorded track must not silently throw it away.
    (:test)
    function testPromptsWhenExitingWithASession(logger as Logger) as Boolean {
        var delegate = TrackRecordingFixtures.makeDelegate(new FakeTrackRecorder(true));
        delegate.setMode(:idle);
        return delegate.shouldPromptToSaveTrack();
    }

    // Backing out of the inner modes just steps back a level; nothing to save yet.
    (:test)
    function testNoPromptFromInnerModes(logger as Logger) as Boolean {
        var delegate = TrackRecordingFixtures.makeDelegate(new FakeTrackRecorder(true));

        delegate.setMode(:hours);
        if (delegate.shouldPromptToSaveTrack()) {
            return false;
        }

        delegate.setMode(:minutes);
        if (delegate.shouldPromptToSaveTrack()) {
            return false;
        }

        delegate.setMode(:seconds);
        return !delegate.shouldPromptToSaveTrack();
    }

    // A device without FIT support, or a session that failed to start, exits directly.
    (:test)
    function testNoPromptWithoutASession(logger as Logger) as Boolean {
        var delegate = TrackRecordingFixtures.makeDelegate(new FakeTrackRecorder(false));
        delegate.setMode(:idle);
        return !delegate.shouldPromptToSaveTrack();
    }

    (:test)
    function testNoPromptWithoutARecorder(logger as Logger) as Boolean {
        var delegate = TrackRecordingFixtures.makeDelegate(null);
        delegate.setMode(:idle);
        return !delegate.shouldPromptToSaveTrack();
    }
}

(:test)
class SaveMenuTitleTest {

    (:test)
    function testUnderAnHourOmitsHours(logger as Logger) as Boolean {
        var title = SaveMenu.formatTitle(2530, 4200.0, false);
        logger.debug(title);
        return title.equals("42:10  4.20 km");
    }

    (:test)
    function testOverAnHourShowsHours(logger as Logger) as Boolean {
        var title = SaveMenu.formatTitle(3725, 12345.0, false);
        logger.debug(title);
        return title.equals("1:02:05  12.35 km");
    }

    (:test)
    function testStatuteUnits(logger as Logger) as Boolean {
        var title = SaveMenu.formatTitle(65, 1609.344, true);
        logger.debug(title);
        return title.equals("1:05  1.00 mi");
    }

    (:test)
    function testUnknownDistance(logger as Logger) as Boolean {
        var title = SaveMenu.formatTitle(0, null, false);
        logger.debug(title);
        return title.equals("0:00  --");
    }
}
