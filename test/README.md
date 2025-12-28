# Test Suite for SkipperWatch

This directory contains unit tests for the SkipperWatch Garmin Connect IQ application.

## Test Files

### TimePickerViewTest.mc

Tests for the `TimePickerView.snapToTime()` helper function, which handles snapping countdown times to the nearest minute.

**Test Cases:**

1. **testSnapToTimeRoundDown** - Tests rounding down when seconds < 30
2. **testSnapToTimeRoundUp** - Tests rounding up when seconds >= 30
3. **testSnapToTimeExactlyThirtySeconds** - Tests edge case when seconds = 30
4. **testSnapToTimeRoundUpCrossHour** - Tests rounding that crosses hour boundary (e.g., 10:59 → 11:00)
5. **testSnapToTimeRoundUpCrossMidnight** - Tests rounding that crosses midnight (23:59 → 00:00)
6. **testSnapToTimePastTime** - Tests snapping when selected time is in the past
7. **testSnapToTimeWithNonZeroCurrentSeconds** - Tests that snapped time matches current seconds
8. **testSnapToTimeSelectedSecondsZero** - Tests when selected time already has 0 seconds
9. **testSnapToTimeOneMinuteThirtySeconds** - Tests countdown of exactly 1:30
10. **testSnapToTimeFiftyNineSeconds** - Tests edge case with 59 seconds

## Running Tests

To run the tests using the Garmin Connect IQ SDK:

```bash
# Run all tests
monkeyc --unit-test -d simulator -f monkey.jungle

# Run tests for a specific device
monkeyc --unit-test -d fenix7 -f monkey.jungle
```

Alternatively, you can use the Garmin Connect IQ IDE:
1. Right-click on the project
2. Select "Run As" → "Connect IQ Unit Test"

## Test Philosophy

The `snapToTime()` function is a pure function that:
- Takes current time and selected target time as inputs
- Returns the "snapped" time (rounded to nearest minute)
- Has no side effects or dependencies on system state
- Is easily testable without mocking

This makes it ideal for comprehensive unit testing to ensure correct behavior across all edge cases.

