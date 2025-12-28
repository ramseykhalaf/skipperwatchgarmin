import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

(:test)
class TimePickerViewTest {
    
    // Test snapToTime when seconds < 30 (should round down)
    (:test)
    function testSnapToTimeRoundDown(logger as Logger) as Boolean {
        // Current time: 10:30:00
        // Selected time: 10:35:15 (countdown of 5:15)
        // Seconds component: 15 (< 30, should round down)
        // Expected: snap to 10:35:00 (keep minute, match current seconds)
        var result = TimePickerView.snapToTime(
            10, 30, 0,  // current time
            10, 35, 15  // selected time
        );
        
        logger.debug("testSnapToTimeRoundDown: " + 
            result[:hour] + ":" + result[:minute] + ":" + result[:second]);
        
        return result[:hour] == 10 && 
               result[:minute] == 35 && 
               result[:second] == 0;
    }
    
    // Test snapToTime when seconds >= 30 (should round up)
    (:test)
    function testSnapToTimeRoundUp(logger as Logger) as Boolean {
        // Current time: 10:30:00
        // Selected time: 10:35:40 (countdown of 5:40)
        // Seconds component: 40 (>= 30, should round up)
        // Expected: snap to 10:36:00 (add 1 minute, match current seconds)
        var result = TimePickerView.snapToTime(
            10, 30, 0,  // current time
            10, 35, 40  // selected time
        );
        
        logger.debug("testSnapToTimeRoundUp: " + 
            result[:hour] + ":" + result[:minute] + ":" + result[:second]);
        
        return result[:hour] == 10 && 
               result[:minute] == 36 && 
               result[:second] == 0;
    }
    
    // Test snapToTime when seconds = 30 exactly (should round up)
    (:test)
    function testSnapToTimeExactlyThirtySeconds(logger as Logger) as Boolean {
        // Current time: 10:30:00
        // Selected time: 10:35:30 (countdown of 5:30)
        // Seconds component: 30 (>= 30, should round up)
        // Expected: snap to 10:36:00
        var result = TimePickerView.snapToTime(
            10, 30, 0,  // current time
            10, 35, 30  // selected time
        );
        
        logger.debug("testSnapToTimeExactlyThirtySeconds: " + 
            result[:hour] + ":" + result[:minute] + ":" + result[:second]);
        
        return result[:hour] == 10 && 
               result[:minute] == 36 && 
               result[:second] == 0;
    }
    
    // Test snapToTime when rounding up crosses hour boundary
    (:test)
    function testSnapToTimeRoundUpCrossHour(logger as Logger) as Boolean {
        // Current time: 10:30:00
        // Selected time: 10:59:45 (countdown of 29:45)
        // Seconds component: 45 (>= 30, should round up)
        // Expected: snap to 11:00:00 (crosses hour boundary)
        var result = TimePickerView.snapToTime(
            10, 30, 0,  // current time
            10, 59, 45  // selected time
        );
        
        logger.debug("testSnapToTimeRoundUpCrossHour: " + 
            result[:hour] + ":" + result[:minute] + ":" + result[:second]);
        
        return result[:hour] == 11 && 
               result[:minute] == 0 && 
               result[:second] == 0;
    }
    
    // Test snapToTime when rounding up crosses midnight (23:59 -> 00:00)
    (:test)
    function testSnapToTimeRoundUpCrossMidnight(logger as Logger) as Boolean {
        // Current time: 10:30:00
        // Selected time: 23:59:45
        // Seconds component: 45 (>= 30, should round up)
        // Expected: snap to 00:00:00 (crosses midnight)
        var result = TimePickerView.snapToTime(
            10, 30, 0,  // current time
            23, 59, 45  // selected time
        );
        
        logger.debug("testSnapToTimeRoundUpCrossMidnight: " + 
            result[:hour] + ":" + result[:minute] + ":" + result[:second]);
        
        return result[:hour] == 0 && 
               result[:minute] == 0 && 
               result[:second] == 0;
    }
    
    // Test snapToTime when selected time is in the past
    (:test)
    function testSnapToTimePastTime(logger as Logger) as Boolean {
        // Current time: 10:30:00
        // Selected time: 10:25:15 (5:15 ago)
        // Seconds component: 15 (< 30, should round down)
        // Expected: snap to 10:25:00
        var result = TimePickerView.snapToTime(
            10, 30, 0,  // current time
            10, 25, 15  // selected time (in the past)
        );
        
        logger.debug("testSnapToTimePastTime: " + 
            result[:hour] + ":" + result[:minute] + ":" + result[:second]);
        
        return result[:hour] == 10 && 
               result[:minute] == 25 && 
               result[:second] == 0;
    }
    
    // Test snapToTime with current seconds != 0
    (:test)
    function testSnapToTimeWithNonZeroCurrentSeconds(logger as Logger) as Boolean {
        // Current time: 10:30:27
        // Selected time: 10:35:42 (countdown of 5:15)
        // Seconds component: 15 (< 30, should round down)
        // Expected: snap to 10:35:27 (match current seconds of 27)
        var result = TimePickerView.snapToTime(
            10, 30, 27, // current time with 27 seconds
            10, 35, 42  // selected time
        );
        
        logger.debug("testSnapToTimeWithNonZeroCurrentSeconds: " + 
            result[:hour] + ":" + result[:minute] + ":" + result[:second]);
        
        return result[:hour] == 10 && 
               result[:minute] == 35 && 
               result[:second] == 27;  // Should match current seconds
    }
    
    // Test snapToTime when selected seconds = 0
    (:test)
    function testSnapToTimeSelectedSecondsZero(logger as Logger) as Boolean {
        // Current time: 10:30:00
        // Selected time: 10:35:00 (countdown of 5:00)
        // Seconds component: 0 (< 30, should round down)
        // Expected: snap to 10:35:00
        var result = TimePickerView.snapToTime(
            10, 30, 0,  // current time
            10, 35, 0   // selected time already at 0 seconds
        );
        
        logger.debug("testSnapToTimeSelectedSecondsZero: " + 
            result[:hour] + ":" + result[:minute] + ":" + result[:second]);
        
        return result[:hour] == 10 && 
               result[:minute] == 35 && 
               result[:second] == 0;
    }
    
    // Test snapToTime when countdown is exactly 1 minute and 30 seconds
    (:test)
    function testSnapToTimeOneMinuteThirtySeconds(logger as Logger) as Boolean {
        // Current time: 10:30:00
        // Selected time: 10:31:30 (countdown of 1:30)
        // Seconds component: 30 (>= 30, should round up)
        // Expected: snap to 10:32:00
        var result = TimePickerView.snapToTime(
            10, 30, 0,  // current time
            10, 31, 30  // selected time
        );
        
        logger.debug("testSnapToTimeOneMinuteThirtySeconds: " + 
            result[:hour] + ":" + result[:minute] + ":" + result[:second]);
        
        return result[:hour] == 10 && 
               result[:minute] == 32 && 
               result[:second] == 0;
    }
    
    // Test snapToTime with seconds = 59 (should round up)
    (:test)
    function testSnapToTimeFiftyNineSeconds(logger as Logger) as Boolean {
        // Current time: 10:30:00
        // Selected time: 10:35:59 (countdown of 5:59)
        // Seconds component: 59 (>= 30, should round up)
        // Expected: snap to 10:36:00
        var result = TimePickerView.snapToTime(
            10, 30, 0,  // current time
            10, 35, 59  // selected time
        );
        
        logger.debug("testSnapToTimeFiftyNineSeconds: " + 
            result[:hour] + ":" + result[:minute] + ":" + result[:second]);
        
        return result[:hour] == 10 && 
               result[:minute] == 36 && 
               result[:second] == 0;
    }
}

