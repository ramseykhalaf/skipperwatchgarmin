#!/bin/bash

# Build for tests
java -Xms1g -Dfile.encoding=UTF-8 \
    -Dapple.awt.UIElement=true -jar "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.4.0-2025-12-03-5122605dc/bin/monkeybrains.jar" \
    -o bin/test.prg \
    -f monkey.jungle \
    -y $HOME/.garmin/developer_key \
    -d fr245m \
    -t \
    -w

# Run the tests
monkeydo bin/test.prg fr245m -t

