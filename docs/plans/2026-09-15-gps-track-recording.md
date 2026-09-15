# GPS Track Recording

## Goal
Record a GPS track for the whole time the app is open, and prompt to save or discard
it on exit. The saved track syncs to Garmin Connect as a normal Sailing activity.

## Investigation findings (fr245m, CIQ 3.3.1, SDK 8.4.0)

### Resolution ceiling
- **1 Hz is the maximum**, and it is a Connect IQ limit rather than a 245 limit. There is
  no sub-second position API on any device.
  - `Position.Info.position`: position is dead-reckoned "between GPS fix intervals
    (typically 1 second)".
  - `FitContributor` `MESG_TYPE_RECORD`: record data "is never written faster than once
    per second".
- The rate that actually lands in the FIT file follows the watch's
  **Settings > System > Data Recording** setting. `Smart` thins points; `Every Second`
  gives true 1 Hz. The app cannot change this, so the README should tell users to pick
  `Every Second` when track fidelity matters.

### Accuracy ceiling
- The 245 is **single-band (L1) only**. A probe run against the `fr245m` profile showed
  `Position has :hasConfigurationSupport` is **false** (that API needs CIQ 3.3.6; this
  profile is CIQ 3.3.1), so no `CONFIGURATION_*`, no SatIQ, no L1+L5.
- `Position has :CONSTELLATION_GLONASS` is **true**, so the one available accuracy knob
  is the older constellations API: `:constellations => [CONSTELLATION_GPS, CONSTELLATION_GLONASS]`.
  Real watch firmware may be newer than the SDK profile, so every capability must be
  `has`-guarded.
- Coordinates are stored as semicircles (int32), ~0.9 cm, so storage precision is never
  the limit. Real-world L1 accuracy is typically ~3-5 m. At 1 Hz and 6 kn (~3 m/s) that
  is a fix roughly every 3 m of track: enough to review a start approach, not enough to
  adjudicate an OCS.
- `Position.Info.accuracy` is only a 4-bucket enum (`QUALITY_POOR/USABLE/GOOD` plus
  `NOT_AVAILABLE`). There is no numeric HDOP or EPE.

### Recording APIs confirmed available
- `Toybox has :ActivityRecording` -> true, `Activity has :SPORT_SAILING` -> true (32).
- `Session.save()` and `Session.discard()` are both first-class APIs.
- `WatchUi.Menu2` / `Menu2InputDelegate` are present in the `fr245m` API.
- Adding `Positioning` and `Fit` permissions to the manifest builds clean.

### Deliberately deferred
- `:autoLap => {:type=>:lines, ...}` line-crossing auto-lap (start line detection).
- `FitContributor` developer fields (countdown as a per-second graph in Garmin Connect).
- `addLap()` at the gun.

These are all available on this device and can be layered on later without reworking
what follows.

## Design

### Start
Recording auto-starts silently when the main view is first shown (`TimePickerView.onShow()`,
alongside the redraw timer), so unit test runs never power the GPS. No extra screen, no
extra button press. A small fix-quality dot at the top of the main view shows GPS state.

### Exit
Pressing BACK from `:hours` mode currently returns `false`, which exits the app. When a
session is recording it instead pushes a native `Menu2`, matching the built-in activity
save screen (UP/DOWN cycle, START selects, BACK goes back):

- Title: elapsed time and distance, e.g. `42:10  4.20 km` (km or mi per device units)
- **Resume** -> pop back to the timer. Recording never pauses, so the track has no gap.
- **Save** -> `session.stop()`, `session.save()`, `System.exit()`
- **Discard** -> second `Menu2` titled `Discard?` with **No** (focused) / **Yes**
  - No or BACK -> pop back to the save menu
  - Yes -> `session.stop()`, `session.discard()`, `System.exit()`

`onStop()` is a non-interactive safety net (app killed, battery pull): it saves rather
than discards, so a recording is never silently lost.

### New files
| File | Purpose |
|------|---------|
| `source/TrackRecorder.mc` | Owns GPS + FIT session lifecycle; the only file that touches `Position` or `ActivityRecording` |
| `source/SaveMenu.mc` | Save/discard menus, their delegates, and title formatting |
| `source/GpsIndicatorDrawable.mc` | Fix-quality dot |

### Modified files
| File | Change |
|------|--------|
| `manifest.xml` | Add `Positioning` and `Fit` permissions |
| `source/skipperwatchApp.mc` | Create recorder, wire into view + delegate, save in `onStop()` |
| `source/TimePickerDelegate.mc` | `setRecorder()`; BACK from `:hours` opens the save menu when recording |
| `source/TimePickerView.mc` | Start the recorder on show; cache and update the GPS indicator |
| `resources/layouts/layout.xml` | Add the indicator drawable |
| `resources/strings/strings.xml` | Menu labels, session name |

`TimePickerDelegate` gets the recorder via a setter, not a constructor argument, so the
existing `TestableTimePickerDelegate` subclass in `test/` keeps working unchanged.

## Race screen

When the countdown crosses zero, `TimePickerView.onTimer()` pushes `RaceView`: damped
course over ground (COG, degrees true) on top, damped speed over ground (SOG, knots)
below. There is no heading: the 245 has no compass in this path, and
`Position.Info.heading` is actually COG despite its name. BACK pops back to the
countdown, e.g. for a general recall; pushing the target out re-arms the switch.

Only the crossing triggers it (`TimePickerDelegate.didRaceStart`), so returning to the
countdown after the start does not bounce straight back.

### Damping (`source/MotionFilter.mc`)
Exponential moving average, alpha = 1 - e^(-dt/tau), tau = 2.5 s. At 1 Hz that is alpha
~1/3, the classic 5-period EMA: 33% of a step after 1 s, 70% after 3 s, 95% after ~7.5 s.
Using real dt means a skipped fix is weighted correctly. Set tau = 5.0 for calmer, slower
numbers (95% after ~15 s).

Alternatives considered:
| Method | 1 s | 3 s | 5 s | Notes |
|---|---|---|---|---|
| Simple 5 s average | 20% | 60% | 100% | Equal weights |
| Linear weighted 5 s (5,4,3,2,1) | 33% | 80% | 100% | Hard cut-off at 5 s, needs a buffer |
| EMA tau 2.5 s (chosen) | 33% | 70% | 87% | One number of state, dt-aware |
| EMA tau 5 s | 18% | 45% | 63% | Sluggish out of tacks |

- COG is circular, so the velocity vector (east, north) is smoothed and COG is read
  back with atan2. Averaging 350 and 010 gives 000, not 180, and slow fixes carry
  little weight.
- SOG is smoothed as a scalar, so it does not sag through a tack.
- No COG (`---`) below 0.5 kn SOG, where it is noise.
- COG is true north. Magnetic would need a declination model.
- The filter runs from app start, so it is settled by the gun.

## Energy impact
`docs/plans/2025-01-18-energy-optimization.md` lists "No GPS, sensors, or network usage
(already good)" as a constraint. This feature inverts that: continuous GPS now dwarfs the
1 s redraw cost that plan was optimising. The 245 gets ~24 h GPS-only (~6 h GPS+music on
the Music), so a race day is comfortable, but that document is now out of date and says so.

## Verification
- `./run_tests.sh` - existing countdown tests plus new recorder-state tests
- `./build_sim.sh` and run in the simulator with simulated position data
