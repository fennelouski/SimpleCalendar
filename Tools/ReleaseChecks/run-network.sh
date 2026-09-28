#!/bin/bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/calendar-network.XXXXXX")"
trap 'rm -rf "$work"' EXIT
xcrun swiftc -parse-as-library "$repo/Simple Calendar/PlatformTypes.swift" "$repo/Simple Calendar/CalendarAPIRequest.swift" "$repo/Simple Calendar/UnsplashAPI.swift" "$repo/Simple Calendar/ImageRepository.swift" "$repo/Tools/ReleaseChecks/network-checks.swift" -o "$work/network-checks"
"$work/network-checks"
python3 "$repo/Tools/ReleaseChecks/check-weather-decoding.py"
