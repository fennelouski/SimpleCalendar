#!/bin/bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/calendar-api.XXXXXX")"
trap 'rm -rf "$work"' EXIT
xcrun swiftc -parse-as-library "$repo/Simple Calendar/CalendarAPIRequest.swift" "$repo/Simple Calendar/UnsplashAPI.swift" "$repo/Simple Calendar/EventDescriptionParser.swift" "$repo/Tools/ReleaseChecks/api-request-checks.swift" -o "$work/api-checks"
"$work/api-checks" "$@"
