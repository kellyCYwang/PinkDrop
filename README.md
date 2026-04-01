# PinkDrop

A native iOS metronome app built with SwiftUI and AVAudioEngine. Features precise audio timing, a black-and-pink themed UI, Dynamic Island integration, and background audio playback.

## Features

- **Precise click timing** via AVAudioEngine with sample-accurate scheduling
- **Tempo range** 20-300 BPM with slider, +/- buttons, tap tempo, and direct number input
- **Time signatures** 2/4 through 7/4
- **Subdivisions** quarter, eighth, triplet, and sixteenth notes
- **Background audio** keeps playing when the app is minimized or screen is locked
- **Dynamic Island / Live Activity** shows BPM, tempo marking, time signature, and a play/stop button
- **Lock Screen widget** with playback controls
- **Custom number keypad** themed to match the app (dark background, pink accents)

## Requirements

- Xcode 15.0+
- iOS 17.0+
- iPhone 14 Pro or later (for Dynamic Island; the app itself runs on any iOS 17 device)

## Getting Started

1. Open `Metronome.xcodeproj` in Xcode
2. Select your development team under Signing & Capabilities for **both** targets:
   - `Metronome` (main app)
   - `MetronomeWidgetExtensionExtension` (widget)
3. Build and run on a device or simulator

> **Note:** Dynamic Island only works on physical iPhone 14 Pro+ hardware. The simulator supports Lock Screen Live Activities but not the Dynamic Island pill.

## Project Structure

```
Metronome/
  MetronomeApp.swift            # App entry point
  ContentView.swift             # Main UI (BPM display, controls, custom keypad)
  AudioEngine.swift             # AVAudioEngine-based click generator with precise timing
  Theme.swift                   # Color palette (dark + pink)
  LiveActivityManager.swift     # Starts/updates/ends Live Activities via ActivityKit
  MetronomeAttributes.swift     # ActivityAttributes model (shared with widget)
  ToggleMetronomeIntent.swift   # LiveActivityIntent for play/stop from Dynamic Island
  Info.plist                    # Background audio + Live Activities entitlements

MetronomeWidgetExtension/
  MetronomeWidgetExtensionBundle.swift  # Widget entry point
  MetronomeLiveActivity.swift           # Dynamic Island + Lock Screen UI
  MetronomeAttributes.swift             # ActivityAttributes model (shared with app)
  MetronomeTheme.swift                  # Theme colors for the widget extension
  ToggleMetronomeIntent.swift           # Intent stub (execution happens in main app)
  Info.plist                            # Widget extension config
```

## Architecture

- **AudioEngine** uses `AVAudioEngine` + `AVAudioPlayerNode` with a `DispatchSourceTimer` on a `.userInteractive` QoS queue for low-latency click scheduling. Three synthesized tones (accent at 1200 Hz, normal at 880 Hz, subdivision at 660 Hz) are generated as PCM buffers at startup.

- **Live Activities** use local-only updates (no push notifications required). The Dynamic Island shows static metadata (BPM, time signature, tempo marking) rather than per-beat animation, because ActivityKit's update rate (~1/sec) is too slow for accurate beat visualization at typical tempos.

- **Background audio** is enabled via the `UIBackgroundModes: audio` Info.plist entry and the `.playback` audio session category. An interruption handler resumes playback after phone calls or other audio interruptions.

## License

MIT
