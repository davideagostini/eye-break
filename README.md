# Eye Break

Eye Break is a small native macOS menu bar app that reminds you to rest your eyes and step away from the screen at regular intervals.

The app is intentionally quiet: it lives in the menu bar, counts only while you are actively using the Mac, and shows a full-screen break overlay when it is time to pause.

## What It Does

- Reminds you to take short eye breaks.
- Reminds you to take longer stand breaks.
- Shows a full-screen overlay on every connected display.
- Lets you skip or snooze a break.
- Lets you pause reminders for 30 minutes or 1 hour.
- Tracks simple daily stats.
- Can start automatically at login.
- Can be distributed as a `.dmg`.

## Default Schedule

Eye Break uses two independent timers:

| Break | Default interval | Default duration |
| --- | ---: | ---: |
| Eye break | 20 min | 20 sec |
| Stand break | 60 min | 90 sec |

The stand break has priority. When a stand break starts, both the eye-break timer and the stand-break timer are reset after completion or skip.

## Active-Time Tracking

The timers count only while the Mac appears active.

If there is no keyboard or mouse input for about 60 seconds, Eye Break stops adding time until you interact with the computer again. This avoids counting time while the Mac is idle, locked, or effectively unused.

## Menu Bar Controls

The menu bar item provides:

- `Enabled`: turn reminders on or off.
- `Stop Current Break`: close an active break overlay.
- `Pause for 30 min`: pause reminders temporarily.
- `Pause for 1 hour`: pause reminders temporarily.
- `Resume`: clear a manual pause or snooze.
- `Show Eye Break Now`: test the eye-break overlay.
- `Test Stand Break Now`: test the stand-break overlay.
- `Settings...`: configure intervals, durations, snooze, and launch at login.
- `Today's Stats...`: open the stats window.
- `Version`: shows the app version and build number.
- `Quit Eye Break`: quit the app.

## Settings

The settings window lets you configure:

| Setting | Default | Range |
| --- | ---: | ---: |
| Eye break interval | 20 min | 1-240 min |
| Eye break duration | 20 sec | 5-600 sec |
| Stand break interval | 60 min | 5-480 min |
| Stand break duration | 90 sec | 10-900 sec |
| Snooze duration | 5 min | 1-60 min |
| Start at login | Off | On/Off |

Settings are stored with `UserDefaults`.

## Stats

Eye Break stores lightweight daily stats:

- Computer active time.
- Expected breaks based on active time and current schedule.
- Completed breaks.
- Skipped breaks.
- Snoozed breaks.
- Last 7 days table.

Stats are stored locally at:

```text
~/Library/Application Support/EyeBreak/stats.json
```

## Versioning

The app version lives in:

```text
VERSION
```

During build, `scripts/build.sh` copies `Info.plist` into the build directory and writes:

- `CFBundleShortVersionString` from `VERSION`.
- `CFBundleVersion` from `BUILD_NUMBER`, or `1` when not provided.

The menu displays the resulting version as:

```text
Version <version> (<build>)
```

For example:

```text
Version 0.1.0 (1)
```

## Build Locally

Requirements:

- macOS.
- Xcode Command Line Tools.

Build the app bundle:

```sh
./scripts/build.sh
```

The app is created at:

```text
build/EyeBreak.app
```

Run it:

```sh
open build/EyeBreak.app
```

## Build a DMG

Build a distributable DMG:

```sh
./scripts/build_dmg.sh
```

The DMG is created at:

```text
dist/EyeBreak-<version>.dmg
```

Example:

```text
dist/EyeBreak-0.1.0.dmg
```

The DMG contains:

- `EyeBreak.app`
- an `Applications` shortcut

## GitHub Actions

The workflow at:

```text
.github/workflows/build-dmg.yml
```

builds the DMG on every push to `main`.

The workflow:

1. Checks out the repository.
2. Runs `scripts/build_dmg.sh`.
3. Uses the GitHub run number as `BUILD_NUMBER`.
4. Uploads the generated DMG as a workflow artifact.

The generated artifact is available from the GitHub Actions run page.

## Creating the GitHub Repository

After creating an empty GitHub repository, connect this local project:

```sh
git remote add origin git@github.com:<owner>/<repo>.git
git push -u origin main
```

After the push, GitHub Actions will build the DMG automatically.

## Project Structure

```text
.
├── Info.plist
├── VERSION
├── Sources/EyeBreak
│   ├── AppDelegate.swift
│   ├── BreakOverlayController.swift
│   ├── BreakScheduler.swift
│   ├── LoginItemManager.swift
│   ├── Models.swift
│   ├── OverlayViews.swift
│   ├── SettingsWindowController.swift
│   ├── StatsStore.swift
│   ├── StatsWindowController.swift
│   └── main.swift
├── scripts
│   ├── build.sh
│   ├── build_dmg.sh
│   └── generate_icon.swift
└── .github/workflows
    └── build-dmg.yml
```

## Notes

- The app is currently signed ad-hoc with `codesign --sign -`.
- The generated DMG is suitable for local/manual distribution.
- For broader public distribution, the app should eventually be signed with an Apple Developer ID and notarized.
