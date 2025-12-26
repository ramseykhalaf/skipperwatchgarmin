#!/bin/bash

# Set up Java path
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# Get SDK path from config
SDK_PATH=$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")

# Add SDK bin to PATH
export PATH="$SDK_PATH/bin:$PATH"

# Change to project directory
cd "$(dirname "$0")"

# Launch ConnectIQ simulator
open "$SDK_PATH/bin/ConnectIQ.app"

# Wait for simulator to start
sleep 3

# If a device ID is provided as argument, load the app
if [ -n "$1" ]; then
    DEVICE_ID="$1"
else
    DEVICE_ID="fr245m"
fi

# Load the app on the simulator
monkeydo bin/skipperwatch.prg "$DEVICE_ID"

