# Energy Optimization Plan for SkipperWatch

## Problem
The app currently runs a 1-second timer that triggers full screen redraws 60 times per minute, consuming significant battery on the Garmin watch.

## Key Constraints
- This is a **watch-app** (not a watch-face), so low-power APIs like `onPartialUpdate`, `onEnterSleep`, and `onExitSleep` are **not available**
- Countdown accuracy to the second is important for sailing race starts
- No GPS, sensors, or network usage (already good)

---

## Implementation Plan

### Phase 1: Cache Drawable References (High Impact, Low Risk)
**Files: `source/TimePickerView.mc`, `resources/layouts/layout.xml`**

Currently `findDrawableById()` is called **13 times per second** (lines 70-117 in `onUpdate()`). Cache all references once in `onLayout()`:

**In `layout.xml`** - add static text for target colons:
```xml
<label id="TargetColon1" ... text=":" />
<label id="TargetColon2" ... text=":" />
```

**In `TimePickerView.mc`** - add private member variables:
```monkeyc
private var _clockLabel;
private var _countdownLabel;
private var _targetHH, _targetMM, _targetSS;
private var _divider1, _divider2;
private var _highlightHH, _highlightMM, _highlightSS, _highlightCountdown;
```

In `onLayout()` after `setLayout()`:
- Cache all drawable references (no longer need `_targetColon1`, `_targetColon2` since they're static)

Update `onUpdate()`:
- Use cached references instead of `findDrawableById()`
- Remove lines 102 and 104 that set colon text

### Phase 2: Event-Driven Updates (High Impact, Low Risk)
**File: `source/TimePickerView.mc`**

Use existing events instead of polling in `onUpdate()`:

**Event-driven updates** (no polling needed):
- Highlight visibility updates via existing mode change events
- Target time label updates via existing target moment change events

**Logic-based updates** (computed from existing values in `onUpdate()`):
- Divider color: Set based on `timeDifference < 0` (already computed for countdown)
- Countdown font size: Set based on `hours > 0` (already computed for countdown)

No state tracking variables needed - the drawable/label setters are cheap when values haven't changed.

### Phase 3: Split Time Displays into Separate Labels (High Impact, Medium Risk)
**Files: `source/TimePickerView.mc`, `resources/layouts/layout.xml`**

Split clock time and countdown into separate label components (like target time already has) to enable granular updates and eliminate `Lang.format()` calls.

**New layout labels needed:**

Clock time (5 labels):
- `ClockHH`, `ClockColon1`, `ClockMM`, `ClockColon2`, `ClockSS`

Countdown (6 labels):
- `CountdownSign` (+/-)
- `CountdownHH`, `CountdownColon1` (hidden when hours=0)
- `CountdownMM`, `CountdownColon2`, `CountdownSS`

**Pre-computed string lookups:**
```monkeyc
private static var PADDED_HOURS = ["00", "01", ..., "23"];
private static var PADDED_60 = ["00", "01", ..., "59"];
private static var UNPADDED_60 = ["0", "1", ..., "59"];
```

**Update logic in `onUpdate()`:**
- Clock: Always update all 3 number labels using lookups (colons are static)
- Countdown:
  - Update sign label (`+` or `-`)
  - If hours > 0: show `CountdownHH` and `CountdownColon1`, use `PADDED_60[minutes]`
  - If hours = 0: hide `CountdownHH` and `CountdownColon1`, use `UNPADDED_60[minutes]`
  - Always update `CountdownSS` using `PADDED_60[seconds]`

**Granular update optimization:**
- Track `_lastClockMin`, `_lastClockHour` - only update when changed
- Track `_lastCountdownHours` - only toggle hour visibility when crossing 0 boundary

### Phase 4: Cache Drawable Coordinates (Medium Impact, Low Risk)
**Files: `source/HighlightDrawable.mc`, `source/DividerDrawable.mc`**

**HighlightDrawable.mc** (lines 34-40) performs 10 arithmetic operations + 2 method calls per draw:
```monkeyc
// Add cached values
private var _cachedX, _cachedY, _cachedWidth, _cachedHeight;
private var _lastScreenWidth = 0, _lastScreenHeight = 0;
```

**DividerDrawable.mc** (lines 22-26) performs 5 arithmetic operations + 2 method calls per draw:
```monkeyc
// Add cached values
private var _cachedY;
private var _lastScreenWidth = 0, _lastScreenHeight = 0;
```

In `draw()` for both:
- Check if screen dimensions match cached values
- Recalculate only when dimensions change (rare/never on watches)
- Use cached values otherwise

---

## Files to Modify

| File | Changes |
|------|---------|
| `resources/layouts/layout.xml` | Add 11 new labels (5 for clock, 6 for countdown) |
| `source/TimePickerView.mc` | Cache ~24 drawables, add string lookup arrays, split time display logic |
| `source/HighlightDrawable.mc` | Add 6 cached coordinate vars |
| `source/DividerDrawable.mc` | Add 3 cached coordinate vars |

---

## Estimated Battery Savings

| Optimization | Estimated Savings |
|--------------|-------------------|
| Cache drawable references | 15-20% |
| Event-driven updates | 20-30% |
| Split time displays + string lookups | 10-15% |
| Cache drawable coordinates | 5-10% |
| **Combined** | **40-55%** |

---

## What We're NOT Doing (and why)

1. **Inactivity-based timer slowdown** - Would make countdown stale near race start, unacceptable for sailing
2. **Partial screen updates with `dc.setClip()`** - High effort, requires abandoning XML layout system
3. **Watch-face low-power APIs** - Not available for watch-apps

---

## Verification

1. Build and run: `./build.sh && ./run_tests.sh`
2. Test on simulator:
   - Verify countdown updates every second
   - Verify mode switching updates highlights immediately
   - Verify divider colors change at countdown=0 boundary
   - Verify target time updates when adjusted
3. If available, test on physical device and compare battery drain
