#!/bin/sh
set -eu
release_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
release_temp=$(mktemp -d /tmp/calendar-play-checks.XXXXXX)
trap 'rm -rf "$release_temp"' EXIT
xcrun swiftc -parse-as-library -swift-version 5 -default-isolation MainActor -target arm64-apple-macos15.0 \
  "$release_root/Simple Calendar/Item.swift" \
  "$release_root/Simple Calendar/LocalCalendarEvents.swift" \
  "$release_root/Simple Calendar/EventDescriptionParser.swift" \
  "$release_root/Simple Calendar/EventExporter.swift" \
  "$release_root/Tools/ReleaseChecks/main.swift" -o "$release_temp/checks"
"$release_temp/checks"
