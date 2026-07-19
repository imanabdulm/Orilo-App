# Orilo 🎯

> **A native, open-source macOS menu bar focus ritual app for creators.**  
> 100% free, local-first, privacy-focused, and built with SwiftUI & AppKit.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014.0%2B-lightgrey.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org)

---

## ✨ Features

- **🎯 Focus Ritual & Settling Mode:** Intention-driven focus sessions with customizable durations, pre-session settling countdown, and clean progress rings.
- **🛡️ Distraction Blocker & Work Pass:** Block distracting desktop apps dynamically during active sessions with a 3-minute Work Pass snooze for urgent tasks.
- **📊 Unified Analytics & Focus Proof:** Track daily focus durations, session counts, current & longest streaks, and top intentions in a clean unified window.
- **❄️ Weekend Streak Freeze:** Preserve your momentum without breaking streaks over weekends.
- **⚡ Smart Presets:** One-click presets for blocking Social Media, Video & Streaming, and Games.
- **💾 Local Data & Export:** 100% private, local persistence with one-click CSV and JSON export.
- **🍅 Pomodoro & Break Management:** Optional automatic break timer with customizable break intervals.

---

## 🛠️ Technology Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI with AppKit integration (`NSStatusItem`, `NSPanel`, `NSWorkspace`)
- **Build System:** Swift Package Manager (SPM)
- **Minimum OS:** macOS 14.0 (Sonoma) or newer

---

## 🚀 Building & Running Locally

### Quick Run
Clone the repository and run the build script:

```bash
git clone https://github.com/your-username/Orilo.git
cd Orilo
./script/build_and_run.sh
```

### Build Options
```bash
# Verify build & launch without opening terminal logs
./script/build_and_run.sh --verify

# Run tests
swift test
```

### Release Bundle
To generate an `.app` bundle for distribution:

```bash
./script/release.sh
```

---

## 🤝 Contributing

Contributions, bug reports, and feature suggestions are warmly welcome!
1. Fork the project repository.
2. Create your feature branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes (`git commit -m 'Add amazing feature'`).
4. Push to the branch (`git push origin feature/amazing-feature`).
5. Open a Pull Request.

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.
