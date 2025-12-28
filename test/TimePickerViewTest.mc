import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

(:test)
class TimePickerViewTest {

    (:test)
    function testSnapToTimeZero(logger as Logger) as Boolean {
        var result = TimePickerView.snapToTime(
            11,22,33,
            0,5,0);
        return result[:hour] == 11 && 
               result[:minute] == 27 && 
               result[:second] == 33;        
    }
}

