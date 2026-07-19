# Contributing to Orilo 🎯

Thank you for your interest in contributing to Orilo! Orilo is a 100% open-source, community-driven macOS menu bar app built for creators.

---

## 🛠️ Development Setup

### Requirements
- macOS 14.0 (Sonoma) or newer
- Xcode 15.0+ or Swift 5.9+ CLI tools

### Clone & Build
```bash
git clone https://github.com/imanabdulm/Orilo-App.git
cd Orilo-App

# Run local development build
./script/build_and_run.sh

# Run test suite
swift test
```

---

## 💡 How to Contribute

1. **Check Existing Issues:** Before opening a new issue or PR, search existing issues to avoid duplicates.
2. **Fork & Branch:** Create a feature branch off `main` (`git checkout -b feature/my-feature`).
3. **Write Clean Code:** Follow modern SwiftUI conventions, preserve docstrings, and keep UI components reusable.
4. **Test Thoroughly:** Ensure `swift test` passes cleanly with 0 failures before opening your Pull Request.
5. **Submit a PR:** Provide a clear description of your changes and reference any related issue.

---

## 📄 License & Attribution

By submitting a Pull Request, you agree that your contributions will be licensed under Orilo's [MIT License](LICENSE).
