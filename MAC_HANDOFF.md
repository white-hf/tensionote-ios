# Tensionote iOS Mac Handoff

This document captures the next required steps when moving the iOS repository to a macOS machine.

## Goal

Finish iOS runtime validation, produce an Xcode build, and prepare the app for App Store submission after the coding phase completed on Windows.

## Current Status

- Core V1 flow is implemented:
  - Home quick entry
  - Detailed entry
  - History
  - Trend
  - Record detail, edit, delete
  - Reminders
  - Report export
  - Email/share flow
  - Settings and localized documents
- Supported languages:
  - English
  - Simplified Chinese
  - Hindi
- Current gap:
  - Real Xcode build and simulator/device validation has not been completed on this machine.

## Required Mac Tools

- Xcode
- Xcode command line tools
- XcodeGen

## Project Generation

From the repo root:

```bash
cd ios
xcodegen generate
open Tensionote.xcodeproj
```

If the generated project name differs, open the generated `.xcodeproj` file produced by XcodeGen.

## First Validation Pass

1. Build the project in Xcode.
2. Resolve any SwiftUI / Charts / resource wiring issues that only appear in a real Apple toolchain.
3. Verify localization loading for:
   - English
   - Simplified Chinese
   - Hindi
4. Verify the following flows in Simulator:
   - Home quick entry save
   - Detailed entry save
   - Edit and delete from detail
   - 2-week trend chart and selected-row highlight
   - Reminder add, edit, delete
   - Report export
   - Mail/share presentation fallback

## Real Device Validation

Use at least one physical iPhone before App Store submission.

Check:

- Reminder notification permission request
- Reminder notification denied state
- Open Settings deep link
- Local notification delivery
- Report export file generation
- Mail composer behavior
- Small-screen layout and long localized strings

## iOS Release Preparation

- Replace development signing with production team signing.
- Set final bundle identifier if needed.
- Set final version and build number.
- Add final app icons and launch assets in the generated Xcode project if additional iOS-specific artwork is required.
- Prepare App Store screenshots and localized listing copy.
- Add a public privacy policy URL.

## Known Areas To Recheck In Xcode

- `ios/Tensionote/Features/Trend/TrendView.swift`
  - Chart rendering
  - Selected record highlight spacing
- `ios/Tensionote/Features/Record/RecordDetailView.swift`
  - Detail summary layout on compact widths
  - Edit sheet recreation after record updates
- `ios/Tensionote/Features/Reminder/ReminderView.swift`
  - Permission state transitions
- `ios/Tensionote/Features/Report/ReportView.swift`
  - Share sheet vs Mail composer attachment flow
- `ios/project.yml`
  - Resource inclusion
  - Localization declaration

## Suggested Next Output On Mac

- Successful simulator build
- Successful physical-device validation pass
- Archive build
- App Store submission checklist
