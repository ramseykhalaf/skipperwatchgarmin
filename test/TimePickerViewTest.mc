import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

(:test)
class TimePickerViewTest {

    (:test)
    function testSnapNegativeCountdownDoNothing(logger as Logger) as Boolean {
        var result = TimePickerView.calculateTargetTimeToSnapCountdownSecondsToZero(11, 22, 33, -300);
        return result[:hour] == 11 && 
               result[:minute] == 27 && 
               result[:second] == 33;
    }

    (:test)
    function testSnapNegativeCountdownRoundDown10(logger as Logger) as Boolean {
        var result = TimePickerView.calculateTargetTimeToSnapCountdownSecondsToZero(11, 22, 33, -310);
        return result[:hour] == 11 && 
               result[:minute] == 27 && 
               result[:second] == 33;
    }

    (:test)
    function testSnapNegativeCountdownRoundDown29(logger as Logger) as Boolean {
        var result = TimePickerView.calculateTargetTimeToSnapCountdownSecondsToZero(11, 22, 33, -329);
        return result[:hour] == 11 && 
               result[:minute] == 27 && 
               result[:second] == 33;
    }


    (:test)
    function testSnapNegativeCountdownRoundUp10(logger as Logger) as Boolean {
        var result = TimePickerView.calculateTargetTimeToSnapCountdownSecondsToZero(11, 22, 33, -290);
        return result[:hour] == 11 && 
               result[:minute] == 27 && 
               result[:second] == 33;
    }

    (:test)
    function testSnapNegativeCountdownRoundUp30(logger as Logger) as Boolean {
        var result = TimePickerView.calculateTargetTimeToSnapCountdownSecondsToZero(11, 22, 33, -270);
        return result[:hour] == 11 && 
               result[:minute] == 27 && 
               result[:second] == 33;
    }


    (:test)
    function testSnapPositiveCountdownRoundDown29(logger as Logger) as Boolean {
        var result = TimePickerView.calculateTargetTimeToSnapCountdownSecondsToZero(11, 22, 33, 329);
        return result[:hour] == 11 && 
               result[:minute] == 17 && 
               result[:second] == 33;
    }

    (:test)
    function testSnapPositiveCountdownRoundUp30(logger as Logger) as Boolean {
        var result = TimePickerView.calculateTargetTimeToSnapCountdownSecondsToZero(11, 22, 33, -270);
        return result[:hour] == 11 && 
               result[:minute] == 17 && 
               result[:second] == 33;
    }
}

