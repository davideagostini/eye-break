# Eye Break

Eye Break is a native macOS menu bar app that reminds you to rest your eyes and step away from the screen at regular intervals.

It stays out of the way while you work, counts only active computer time, and shows a full-screen break overlay when it is time to pause.

## Features

- Short eye breaks and longer stand breaks.
- Full-screen overlay across connected displays.
- Skip and snooze controls.
- Temporary pause controls for 30 minutes or 1 hour.
- Configurable intervals and durations.
- Optional launch at login.
- Simple daily stats with a last-7-days view.

## Default Schedule

| Break | Interval | Duration |
| --- | ---: | ---: |
| Eye break | 20 min | 20 sec |
| Stand break | 60 min | 90 sec |

Timers advance only while the Mac appears active. If there is no keyboard or mouse input for about a minute, Eye Break stops counting until you use the computer again.

## Menu

From the menu bar you can:

- Enable or disable reminders.
- Stop the current break.
- Pause reminders temporarily.
- Resume reminders.
- Start test breaks.
- Open settings.
- Open stats.
- Quit the app.

## Settings

The settings window lets you configure:

| Setting | Default |
| --- | ---: |
| Eye break interval | 20 min |
| Eye break duration | 20 sec |
| Stand break interval | 60 min |
| Stand break duration | 90 sec |
| Snooze duration | 5 min |
| Start at login | Off |

## Stats

Eye Break tracks lightweight local stats:

- active computer time
- expected breaks
- completed breaks
- skipped breaks
- snoozed breaks

Stats are stored locally on your Mac and are not sent anywhere.

## Build

Requirements:

- macOS
- Xcode Command Line Tools

Build the app:

```sh
./scripts/build.sh
```

Run it:

```sh
open build/EyeBreak.app
```

## Release DMG

The app version is stored in `VERSION`.

Build a distributable DMG:

```sh
./scripts/build_dmg.sh
```

The generated file is written to `dist/`.

## GitHub Actions

The repository includes a GitHub Actions workflow that builds the DMG on every push to `main` and uploads it as a workflow artifact.

When a version tag is pushed, for example `v0.1.0`, the same workflow also creates a GitHub Release and attaches the DMG.

## Distribution Notes

The current build uses ad-hoc signing. For public distribution outside personal testing, the app should be signed with an Apple Developer ID and notarized.
