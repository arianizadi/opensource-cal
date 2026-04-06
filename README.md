# Cal

A privacy first nutrition tracker for iPhone, built with SwiftUI. Log food, scan nutrition labels with on device OCR, sync with Apple Health, and follow macros on your wrist or Home Screen. **No accounts, no subscription, no cloud nutrition APIs.** Build it yourself and run it on your own devices.

## Why Cal

Commercial diet apps often send data off device or lock features behind paywalls. Cal is **open source** so you can audit the code, keep your data on device, and extend behavior if you want. Nutrition facts from packaging are read using **Apple Vision** on device. Parsing stays local; nothing is sent to a third party nutrition service for scanning.

## Features

- **Dashboard:** daily calories, macros, micros, and scoring at a glance  
- **Food log:** add meals and track nutrients over time with **SwiftData** persistence  
- **Nutrition scanner:** camera or photo library, **Vision** OCR, structured nutrient parsing  
- **Analytics:** trends and insights from your entries  
- **Apple Health:** read and write nutrition data with **HealthKit** (with your permission)  
- **Apple Watch:** companion app for quick stats on your wrist  
- **Widgets:** Lock Screen and Home Screen widgets via App Group shared data (`group.com.ariandev.cal`)

## Requirements

- macOS with **Xcode** (project targets recent Swift and SwiftUI; open `cal.xcodeproj` and let Xcode resolve the recommended toolchain)  
- An **Apple Developer** account for signing if you use HealthKit, Watch, widgets, App Groups, or CloudKit capabilities  
- **iOS** and **watchOS** devices or simulators supported by your Xcode version  

## Getting started

1. **Clone** this repository.  
2. **Open** `cal.xcodeproj` in Xcode.  
3. **Select** the `cal` scheme and your development team under **Signing & Capabilities** for the iOS app, watch extension, and widget targets. Update bundle identifiers if you fork the project (keep App Group and capability identifiers consistent across targets).  
4. **Build and run** on a simulator or device. Grant **Health**, **Camera**, and **Photo Library** access when prompted so logging and scanning work as intended.  

> **Note:** Entitlements include HealthKit, App Groups, and iCloud (CloudKit). If you only want local storage, you can adjust capabilities in Xcode to match your needs; some features (widgets sharing data with the main app) expect the App Group to be configured.

## Project layout

| Path | Purpose |
|------|---------|
| `cal/` | iOS app (SwiftUI, SwiftData, HealthKit, Vision) |
| `calWatch/` | watchOS app |
| `calWidget/` | Widget extension |
| `AnalyticsView.swift`, `DashboardView.swift`, … | Feature screens at repo root / `cal/` per Xcode groups |

## Tech stack

Swift, SwiftUI, SwiftData, HealthKit, Vision, WidgetKit, watchOS.

## Contributing

Issues and pull requests are welcome. Please keep behavior aligned with the privacy model: avoid introducing network calls that upload food images or nutrition logs to third parties without clear opt in and documentation.

## License

Add a `LICENSE` file to the repository if you have not already (for example MIT or Apache 2.0), then update this section with the chosen license.
