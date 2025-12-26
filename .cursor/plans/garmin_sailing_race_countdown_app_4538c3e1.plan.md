---
name: Garmin Sailing Race Countdown App
overview: Create a Garmin Connect IQ watch app for counting down to a sailing race start, with a time picker screen and a countdown screen that shows negative time (red) before start and elapsed time (green) after start.
todos:
  - id: setup_manifest
    content: Verify manifest.xml has correct app metadata, API level 3.3, and Forerunner 245 device target (already scaffolded)
    status: completed
  - id: update_app_class
    content: Update skipperwatchApp.mc to push TimePickerView on app launch instead of default view
    status: pending
  - id: create_time_picker_view
    content: Create TimePickerView.mc with current time display and hours/minutes picker UI
    status: pending
  - id: create_time_picker_delegate
    content: Create TimePickerDelegate.mc with up/down/start/back button handling for two-step time selection
    status: pending
  - id: create_countdown_view
    content: Create CountdownView.mc with current time display and countdown/elapsed time with color coding (red/green)
    status: pending
  - id: create_countdown_delegate
    content: Create CountdownDelegate.mc with back button handling to return to time picker
    status: pending
  - id: implement_timer_logic
    content: Implement timer calculation logic for countdown (negative/red) and elapsed time (positive/green)
    status: pending
  - id: update_strings_resources
    content: Update strings.xml with text resources for UI labels (scaffold already exists)
    status: pending
  - id: cleanup_scaffold_files
    content: Remove or ignore unused scaffold files (skipperwatchView.mc, skipperwatchDelegate.mc, skipperwatchMenuDelegate.mc, menu.xml, layout.xml)
    status: pending
---

# Garmin Sailing Race Countdown App

## Overview

A Garmin Connect IQ watch app that provides a countdown timer for sailing race starts. The app consists of two main screens: a time picker for selecting the race start time, and a countdown screen that displays the time remaining (before start) or elapsed time (after start).

## Architecture

The app follows the standard Garmin Connect IQ MVC pattern:

- **App Class**: Entry point and app lifecycle management
- **Time Picker View/Delegate**: Two-step time selection (hours → minutes)
- **Countdown View/Delegate**: Timer display with color-coded status
- **Timer Management**: Timer that runs while app is active

## File Structure

The scaffold has already created the basic structure. We'll build on top of it:

```
skipperwatch/
├── manifest.xml                    # ✅ Already scaffolded (API 3.3, Forerunner 245)
├── source/
│   ├── skipperwatchApp.mc         # ✅ Scaffolded - needs update to push TimePickerView
│   ├── skipperwatchView.mc        # ⚠️ Scaffolded - not used (will be replaced by TimePickerView/CountdownView)
│   ├── skipperwatchDelegate.mc    # ⚠️ Scaffolded - not used (will be replaced by TimePickerDelegate/CountdownDelegate)
│   ├── skipperwatchMenuDelegate.mc # ⚠️ Scaffolded - not used (no menu needed)
│   ├── TimePickerView.mc          # 🆕 To create - Time picker UI (hours/minutes selection)
│   ├── TimePickerDelegate.mc      # 🆕 To create - Input handling for time picker
│   ├── CountdownView.mc           # 🆕 To create - Countdown/elapsed time display
│   └── CountdownDelegate.mc       # 🆕 To create - Input handling for countdown screen
└── resources/
    ├── strings/
    │   └── strings.xml            # ✅ Scaffolded - needs update with app-specific strings
    ├── layouts/
    │   └── layout.xml             # ⚠️ Scaffolded - not used (custom drawing instead)
    └── menus/
        └── menu.xml               # ⚠️ Scaffolded - not used (no menu needed)
```

Legend: ✅ Already exists, 🆕 To create, ⚠️ Scaffolded but not needed



## Implementation Details

### 1. manifest.xml

- ✅ **Already scaffolded** - Verified configuration:
  - API level 3.3.0 (correct for Forerunner 245)
  - Target device: Forerunner 245 (fr245m)
  - Entry point: `skipperwatchApp`
  - App name from strings resource
- No changes needed - scaffold configuration is correct

### 2. skipperwatchApp.mc

- ✅ **Already scaffolded** - Basic structure exists
- **Update required**: Modify `getInitialView()` to push `TimePickerView` instead of `skipperwatchView`
- Initialize app state in memory (selected start time, not persisted)
- Handle app lifecycle (onStart, onStop) - scaffold already has empty methods
- Always start fresh at time picker screen when app launches

### 3. TimePickerView.mc

- Extends `WatchUi.View`
- Display current time at top using `System.getClockTime()` (format: HH:MM:SS)
- Two-step picker interface for selecting absolute target time (HH:MM):
- **Hours mode**: Show hours selector (0-23)
- Default: Current hour (or next hour if current time + 3 minutes crosses hour boundary)
- Display selected hour value
- **Minutes mode**: Show minutes selector (0-59)
- Default: Current minute + 3 (rounded up to next minute if needed)
- Example: If current time is 11:23:41, default shows 11:26 (hours=11, minutes=26)
- Visual indicators for current selection mode (hours vs minutes)
- Display selected target time in format HH:MM while picking

### 4. TimePickerDelegate.mc

- Extends `WatchUi.BehaviorDelegate`
- Handle button inputs:
- **Up button**: Increment current selection (hours or minutes)
- **Down button**: Decrement current selection
- **Start/Select button**: 
    - If in hours mode → switch to minutes mode
    - If in minutes mode → calculate absolute target time from selected hours and minutes, then push `CountdownView`
    - Example: Selected 11:26 → target time is 11:26:00 (today)
- **Back button**: 
    - If in minutes mode → return to hours mode
    - If in hours mode → exit app

### 5. CountdownView.mc

- Extends `WatchUi.View`
- Display current time at top using `System.getClockTime()` (format: HH:MM:SS)
- Example: 11:23:42
- Display countdown/elapsed time in large format below:
- **Before start (countdown)**: Red text with "-" prefix
    - Format: `-MM:SS` for durations under 1 hour (e.g., "-2:18" for 2 minutes 18 seconds)
    - Format: `-HH:MM:SS` for durations 1 hour or longer
    - Example: If current time is 11:23:42 and target is 11:26:00, display "-2:18"
- **After start (elapsed)**: Green text with "+" prefix
    - Format: `+MM:SS` for durations under 1 hour (e.g., "+5:23")
    - Format: `+HH:MM:SS` for durations 1 hour or longer
    - Update every second using `Timer.Timer` to recalculate and redraw

### 6. CountdownDelegate.mc

- Extends `WatchUi.BehaviorDelegate`
- Handle button inputs:
- **Back button**: Return to time picker (push new TimePickerView with preserved or default values)
- **Start/Select button**: Pause/resume (optional enhancement - can be left for future)

### 7. Timer Management

- Use `Timer.Timer` with 1-second interval
- Store target start time as absolute time (HH:MM) in memory (not persisted)
- Convert selected hours/minutes to absolute time (seconds since midnight or epoch)
- Example: User selects 11:26 → store as target time 11:26:00
- Calculate difference: `targetTime - currentTime` (in seconds)
- Negative values = countdown remaining (display in red with "-" prefix)
- Positive values = elapsed time since start (display in green with "+" prefix)
- Example: Current 11:23:42, Target 11:26:00 → difference = -138 seconds = "-2:18"
- Format display based on absolute value:
- If |difference| < 3600 seconds: display as MM:SS
- If |difference| >= 3600 seconds: display as HH:MM:SS
- Timer state is lost when app is closed - app always starts fresh at time picker

## Key Implementation Notes

- **API 3.3 Compatibility**: All features must use APIs available in Connect IQ API 3.3
- `System.getClockTime()` - available in 3.3
- `Timer.Timer` - available in 3.3
- `WatchUi.View`, `WatchUi.BehaviorDelegate` - available in 3.3
- `Graphics.COLOR_RED`, `Graphics.COLOR_GREEN` - available in 3.3
- **Time Calculation**: 
- Time picker selects absolute target time (HH:MM format)
- Default: Current time + 3 minutes (rounded to next minute)
- Convert selected HH:MM to absolute time (seconds since midnight or epoch)
- Calculate difference: targetTime - currentTime
- Format as MM:SS (if < 1 hour) or HH:MM:SS (if >= 1 hour)
- **Color Coding**: Use `Graphics.COLOR_RED` for countdown, `Graphics.COLOR_GREEN` for elapsed time
- **Default Time**: On app open, initialize time picker to current time + 3 minutes
- Example: Current time 11:23:41 → default shows 11:26 (hours=11, minutes=26)
- **State Management**: Store selected start time in memory only - no persistence. App always starts at time picker screen when launched.
- **UI Layout**: Use `dc.getWidth()` and `dc.getHeight()` for responsive layout (Forerunner 245: 240x240 display)

## Implementation Notes Based on Scaffold

- **Scaffold Files to Ignore**: The scaffold generated `skipperwatchView.mc`, `skipperwatchDelegate.mc`, `skipperwatchMenuDelegate.mc`, `menu.xml`, and `layout.xml`. These are not needed for the countdown app and can be left in place (they won't interfere) or removed for cleanliness.

- **Custom Drawing**: Instead of using layout resources, we'll use custom drawing in `onUpdate()` methods for full control over the UI layout and colors.

- **File Naming**: The scaffold uses lowercase naming (`skipperwatchApp.mc`), so we'll follow that convention for new files (`TimePickerView.mc`, `CountdownView.mc`, etc. - PascalCase for classes is standard in Monkey C).

## Testing Considerations

- Test time picker navigation (hours ↔ minutes)
- Verify countdown transitions from negative to positive at start time
- Test color changes (red → green) at start time
- Verify timer accuracy
- Test back button navigation from countdown to time picker