#!/bin/bash
# Build a release .prg for the physical watch, to copy into GARMIN/APPS/ over USB.

java -Xms1g -Dfile.encoding=UTF-8 \
    -Dapple.awt.UIElement=true -jar "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.4.0-2025-12-03-5122605dc/bin/monkeybrains.jar" \
    -o bin/skipperwatch-fr245m.prg \
    -f monkey.jungle \
    -y $HOME/.garmin/developer_key \
    -d fr245m \
    -r \
    -w
