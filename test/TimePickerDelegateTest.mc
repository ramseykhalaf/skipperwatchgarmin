import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
import Toybox.Time;
import Toybox.Time.Gregorian;

(:test)
class TestableTimePickerDelegate extends TimePickerDelegate {
    private var _mockTime as Time.Moment;

    function initialize(mockTime as Time.Moment) {
        _mockTime = mockTime;
        TimePickerDelegate.initialize();
    }

    function getCurrentTime() as Time.Moment {
        return _mockTime;
    }
}

(:test)
class TimePickerDelegateTest {

    (:test)
    function testInitializationRounding(logger as Logger) as Boolean {
        // Create 11:22:33
        var options = {
            :year   => 2024,
            :month  => 1,
            :day    => 1,
            :hour   => 11,
            :minute => 22,
            :second => 33
        };
        var mockNow = Gregorian.moment(options);

        var delegate = new TestableTimePickerDelegate(mockNow);
        var targetMoment = delegate.getTargetMoment();
        var info = Gregorian.info(targetMoment, Time.FORMAT_SHORT);

        // Expect 11:22:33 + 3m = 11:25:33, rounded to 11:25:00
        return info.hour == 11 && info.min == 25 && info.sec == 0;
    }

    (:test)
    function testSnapNegativeCountdownDoNothing(logger as Logger) as Boolean {
        var result = TimePickerDelegate.calculateTargetTimeToSnapCountdownSecondsToZero(11, 22, 33, -300);
        return result[:hour] == 11 && 
               result[:minute] == 27 && 
               result[:second] == 33;
    }

    (:test)
    function testSnapNegativeCountdownRoundDown29(logger as Logger) as Boolean {
        var result = TimePickerDelegate.calculateTargetTimeToSnapCountdownSecondsToZero(11, 22, 33, -329);
        return result[:hour] == 11 && 
               result[:minute] == 27 && 
               result[:second] == 33;
    }

    (:test)
    function testSnapNegativeCountdownRoundUp30(logger as Logger) as Boolean {
        var result = TimePickerDelegate.calculateTargetTimeToSnapCountdownSecondsToZero(11, 22, 33, -270);
        return result[:hour] == 11 && 
               result[:minute] == 27 && 
               result[:second] == 33;
    }

    (:test)
    function testSnapPositiveCountdownRoundDown29(logger as Logger) as Boolean {
        var result = TimePickerDelegate.calculateTargetTimeToSnapCountdownSecondsToZero(11, 22, 33, 329);
        return result[:hour] == 11 && 
               result[:minute] == 17 && 
               result[:second] == 33;
    }

    (:test)
    function testSnapPositiveCountdownRoundUp30(logger as Logger) as Boolean {
        var result = TimePickerDelegate.calculateTargetTimeToSnapCountdownSecondsToZero(11, 22, 33, 270);
        return result[:hour] == 11 && 
               result[:minute] == 17 && 
               result[:second] == 33;
    }
}

