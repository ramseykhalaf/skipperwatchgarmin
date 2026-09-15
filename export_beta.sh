#!/bin/bash
# Build a Connect IQ beta package (.iq) for uploading to the developer dashboard.
#
# Beta apps must use a different app id from the production app, so this writes
# a copy of manifest.xml with BETA_APP_ID swapped in and the name changed to
# skipperwatch-beta. Keep the id fixed: uploads with the same id update the same
# beta app. manifest.xml itself keeps the production id and name.

set -e
cd "$(dirname "$0")"

BETA_APP_ID="95cd91e0-5298-467c-8b1f-b96ef1a5f1e3"

mkdir -p bin export
sed -E \
    -e "s/(<iq:application id=\")[^\"]+/\1${BETA_APP_ID}/" \
    -e 's/name="@Strings.AppName"/name="@Strings.AppNameBeta"/' \
    manifest.xml > bin/manifest-beta.xml

java -Xms1g -Dfile.encoding=UTF-8 \
    -Dapple.awt.UIElement=true -jar "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.4.0-2025-12-03-5122605dc/bin/monkeybrains.jar" \
    -e \
    -r \
    -o export/skipperwatch-beta.iq \
    -f beta.jungle \
    -y $HOME/.garmin/developer_key \
    -w

echo "Upload export/skipperwatch-beta.iq at https://apps.garmin.com/developer/upload and tick 'Beta App'."
