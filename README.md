# Jeffpardy for iOS

An iOS companion for [Jeffpardy](https://github.com/JeffSteinbok/jeffpardy) with two focused experiences:

- **Host Display** scans the host's QR code and embeds the existing `/HostSecondary` web experience.
- **Player** is a native SwiftUI player registration and buzzer connected directly to the Jeffpardy SignalR hub.
- **Nearby discovery** advertises the public game code with Multipeer Connectivity so players in the room can select it without typing.

## Requirements

- Xcode 16 or later
- XcodeGen
- iOS 17 or later

## Getting started

```bash
brew install xcodegen
xcodegen generate
open JeffpardyIOS.xcodeproj
```

Select a development team in the Jeffpardy target before running on a physical device.

## Server configuration

The default server is `https://jeffpardy.azurewebsites.net`. To use a local or alternate server, change `JEFFPARDY_BASE_URL` in `project.yml`, then regenerate the Xcode project.

Local HTTP development also requires an App Transport Security exception. Prefer a trusted HTTPS development endpoint instead of adding a broad exception.

## Architecture

The app intentionally has only two top-level tabs. The host display stays on the web so it continues to share presentation behavior with Jeffpardy. The latency-sensitive player buzzer is native and uses the official `SignalRClient` Swift package.

Nearby discovery uses Multipeer Connectivity only to advertise the public game code and device name. It never shares the host code, and all gameplay continues through the existing SignalR server. Manual code entry remains available to players when local discovery is unavailable.
