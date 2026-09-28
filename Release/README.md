# Calendar Play release preparation

The release listing is Apple ID 6755897754, bundle `com.nathanfennel.Simple-Calendar`, team EJLR2RPSV2. Only tvOS is currently registered in App Store Connect; the project also contains iOS, Mac and visionOS source. Version 1.4 build 2 preserves the public tvOS 26.2 minimum. The unused legacy entitlements file is not an assertion of enabled capabilities. Existing tvOS profiles contain no iCloud entitlement. Local event persistence uses the existing SwiftData store; do not delete or replace it during recovery.

## Native changes

TV event creation, edits, templates and quick-add now call a shared durable save path. A failed save keeps the input form open. Read failures are visible and retryable; startup does not switch stores or create an in-memory replacement. Updates preserve event IDs and image metadata. Remote calendar refresh retains locally saved events. Day and agenda views include overlapping overnight events. TV date controls now adjust dates and times, and deletion asks for confirmation.

AI parsing is a deliberate action behind device-local consent, with a named OpenAI disclosure. The request uses the owned production API and includes text, selected date and IANA time zone. Malformed responses, unsafe generated emoji, invalid dates and failed responses are rejected. Cancellation and request identity prevent stale results from replacing the draft. The user reviews and saves the result; recurrence is explicitly recorded as notes for one event.

Calendar export preserves local all-day dates, declares DATE values, escapes text and IDs, folds UTF-8 lines, uses CRLF and safe temporary filenames. See RFC 5545: https://www.rfc-editor.org/rfc/rfc5545 .

## Validation

Run `Tools/ReleaseChecks/run.sh`. Seven scenario groups use the production SwiftData model/store, parser and calendar exporter. They cover real SQLite reopen and failed writes, validation, DST and overnight intervals, malformed AI output, calendar export and durable deletion. Synthetic test data is isolated in a temporary directory. These checks are not native UI or live service tests.

Integrated unsigned tvOS and iOS Release builds passed. Run `Tools/ReleaseChecks/run-network.sh` for 22 network and durable image assertions plus three weather decoder checks. Optional photos, event-based photo queries, network location and maps/weather start disabled; revocation cancels app requests and invalidates queued results. Historical information uses its existing feature toggle, off in fresh settings. Selected images and their required provider credits are saved durably; failed writes preserve the previous image. Real local backend checks against configured OpenAI and Unsplash passed; deployed parity must still be verified. The Mac is locked; actual native UI, remote focus, dark mode, accessibility, live service flows, screenshots, signed archive/export and App Store submission remain unverified.

## Deployment and submission

This repository also contains a hosted API. Read root AGENTS.md and the workspace deployment policy before any push or release. Keep the existing production site working and verify the same committed backend revision on AWS and Vercel before recording a release. Do not treat the historical test suite's synthetic fallback as proof of a working live API.

Canonical policy and support paths are planned under `https://nathanfennel.com/calendar-play/`; verify publication before saving those URLs in ASC. Review the current Data Not Collected public label against actual optional OpenAI, Unsplash, weather and IP-location handling. Capture screenshots from the final current TV build, select the uploaded processed build, enable automatic release and complete final submission. No submission is complete until ASC shows Waiting for Review or In Review.
