# Cycle Pulse

An Apple Watch round timer with live heart rate, with an iPhone companion for
statistics and history. Built to be read at a glance: dark, high contrast, few
and large targets.

## What it does

A **session** consists of several **rounds** with a rest phase between them.

**On the watch**

- Large phase-coloured timer, current pulse and the round's maximum pulse
- Round counter — a session runs for as many rounds as you like
- Swipe left for the controls page: end the session, or engage Water Lock
- Always-On display keeps phase, elapsed time and pulse visible
- Optional reminder taps at a configurable interval, or switched off entirely
- Action button support on Apple Watch Ultra to switch between round and rest
  (see [Action button](#action-button) for the one-time setup it needs)

**On the iPhone**

- Statistics per day, week, month, year or all time: total round time,
  sessions, rounds, averages, calories, heart-rate trends, longest session and
  which day and time of day you go most often
- History with a round-by-round breakdown of every session
- Notes per session ("Evening rounds, felt relaxed")
- Settings for MET value, body weight override, vibration
- Swipe left on a session to delete it

## Action button

On Apple Watch Ultra, watchOS runs the Action button in two stages:

| Press | Runs | Effect |
|---|---|---|
| 1, with no session running | `StartSaunaWorkoutIntent` | Starts the session and its first round |
| any press during a session | `TogglePhaseIntent`, the *next action* | Ends the current phase, starts the other one |

The next action is an ordinary `AppIntent` the app donates while its workout
session is live. `HealthKitSessionRecorder` donates it the moment the session
starts, so the button is armed whether the session was started with the button
or on screen. Each toggle re-arms itself, and the app plays a haptic on the
switch: the press happens with the app in the background, usually with Water
Lock on, so the tap is the only confirmation.

`PauseWorkoutIntent` and `ResumeWorkoutIntent` are deliberately not adopted.
They belong to the Action + side button chord rather than to a single press —
mapping the phases onto them, as an earlier attempt did, left every press after
the first doing nothing.

**One-time setup.** An app cannot claim the button; it has to be pointed here,
and the assignment is global rather than per-app:

**Settings → Action Button → Action: Workout → App: Cycle Pulse**

While it points here, a press no longer starts a workout in Apple's Workout
app. `ActionButtonInfoView` says all of this on first launch, on Ultra models
only.

## Where the data lives

**Apple Health is the only store.** Every finished session is written as an
`HKWorkout` of type *Other*, together with per-round heart rate and the
calculated active energy; the round structure and any note ride along in the
workout's metadata. The app keeps no database of its own, works fully offline,
has no account and collects nothing. Deleting a session in the app deletes the
workout in Health.

A note is stored with the workout, but Health and Fitness do not render
third-party workout metadata — so notes are only visible inside Cycle Pulse.

## Calories

Energy is estimated with the MET model, counting only time actually spent in
rounds, not the rests:

```
kcal = MET × body weight (kg) × hours in rounds
```

The MET value is configurable between 1.5 and 2.0 and defaults to 1.75. Body
weight comes from Health unless overridden in settings.

## Requirements

- watchOS 26.5, iOS 26.5, Xcode 26
- Apple Watch Ultra for the Action button; everything else runs on any
  Apple Watch

## Build

Open `Sauna Companion.xcodeproj` and run the *Cycle Pulse Watch App* scheme.
The project file, the source folders, the bundle identifiers and the Swift
module names (`Sauna_Companion`, `Sauna_Companion_Watch_App`) keep the app's
original working name: the Health data of existing sessions is bound to the
bundle identifiers, and the Action button's stored intents to the module
names.

The build number is a `YYYYMMDDHHMM` timestamp shared by both apps: a build
phase writes `Config/Version.xcconfig`, and every target takes
`CURRENT_PROJECT_VERSION` from `BUILD_TIMESTAMP`, so the iPhone app and the
watch app always carry the same number. It takes effect from the next build.

## Tests

```
xcodebuild test -scheme "Cycle Pulse" -destination 'platform=iOS Simulator,name=iPhone 17'
```

Covers the session state machine, statistics, the calorie model, duration
formatting, body-weight parsing and the Health metadata round-trip.

## Languages

English, German, Swedish, Finnish.
