#!/bin/bash

# Set up Java path
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# Get SDK path from config
SDK_PATH=$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")

# Add SDK bin to PATH
export PATH="$SDK_PATH/bin:$PATH"

# Change to project directory
cd "$(dirname "$0")"

# Create bin directory if it doesn't exist
mkdir -p bin

# Build the app
monkeyc -y ~/.garmin/developer_key -f monkey.jungle -o bin/skipperwatch.prg 

