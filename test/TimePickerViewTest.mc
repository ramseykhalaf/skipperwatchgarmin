import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

(:test)
class TimePickerViewTest {

    (:test)
    function testSnapToTimeZero(logger as Logger) as Boolean {
        var result = TimePickerView.calculateTargetTimeToSnapCountdownSecondsToZero(11,22,33,0,5,0);
        return result[:hour] == 11 && 
               result[:minute] == 27 && 
               result[:second] == 33;
    }

    (:test)
    function testSnapToTimeRoundDown(logger as Logger) as Boolean {
        var result = TimePickerView.calculateTargetTimeToSnapCountdownSecondsToZero(11,22,33,0,5,10);
        return result[:hour] == 11 && 
               result[:minute] == 27 && 
               result[:second] == 33;
    }

    (:test)
    function testSnapToTimeRoundDown29(logger as Logger) as Boolean {
        var result = TimePickerView.calculateTargetTimeToSnapCountdownSecondsToZero(11,22,33,0,5,29);
        return result[:hour] == 11 && 
               result[:minute] == 27 && 
               result[:second] == 33;
    }


    (:test)
    function testSnapToTimeRoundUp30(logger as Logger) as Boolean {
        var result = TimePickerView.calculateTargetTimeToSnapCountdownSecondsToZero(11,22,33,0,4,30);
        return result[:hour] == 11 && 
               result[:minute] == 27 && 
               result[:second] == 33;
    }
}

