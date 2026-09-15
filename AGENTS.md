# SkipperWatch Garmin

A countdown app for sailing racing, designed for Garmin watches.

## Features

### 1. Fixed Start Time
The app allows users to pick a specific start time (hours, minutes, and seconds). Once set, the watch displays a real-time countdown to that exact moment.

### 2. Start Sequence Support
The app provides specialized features for syncing with race start sequences:
- **Seconds Sync:** Users can sync the countdown seconds to a start horn.
- **Minute Snapping:** When a horn sounds, the countdown can be snapped to the nearest minute to correct for any minor timing discrepancies.
- **Manual Nudging:** Users can nudge the countdown up or down in 1-second increments for fine-tuned adjustments during the sequence.

## User Interface
Currently, the app consists of a single primary screen (`TimePickerView`) that handles both time selection and countdown display.

## Development

### Useful Scripts
- `./run_tests.sh`: Builds and runs the test suite.
- `./build_sim.sh`: Builds `bin/skipperwatch.prg` for the simulator.
- `./build_device.sh`: Builds `bin/skipperwatch-fr245m.prg` for the physical watch (copy to `GARMIN/APPS/` over USB).
- `./export_beta.sh`: Exports `export/skipperwatch-beta.iq` for upload as a Connect IQ beta app.
- `./start_simulator.sh`: Starts the Garmin simulator.

### Architecture
- `skipperwatchApp.mc`: Application entry point.
- `TimePickerView.mc`: Main UI view handling the display of the current time, target time, and countdown.
- `TimePickerDelegate.mc`: Input handler for the main view, implementing the logic for time adjustment, snapping, and mode switching.

