import AppKit
import ApplicationServices
import Foundation
import Observation

struct FrontmostApp: Equatable {
    var name: String
    var bundleIdentifier: String?
    var processIdentifier: pid_t

    /// Bundle identifiers of common browsers whose active tab title we can read
    /// via the Accessibility API to catch web-based distractions (e.g. YouTube).
    private static let browserBundleIdentifiers: Set<String> = [
        "com.apple.safari",
        "com.apple.safaritechnologypreview",
        "com.google.chrome",
        "com.google.chrome.canary",
        "com.google.chrome.beta",
        "com.google.chrome.dev",
        "org.chromium.chromium",
        "com.microsoft.edgemac",
        "com.microsoft.edgemac.beta",
        "com.microsoft.edgemac.dev",
        "com.microsoft.edgemac.canary",
        "org.mozilla.firefox",
        "org.mozilla.firefoxdeveloperedition",
        "org.mozilla.nightly",
        "com.brave.browser",
        "com.brave.browser.beta",
        "com.brave.browser.nightly",
        "company.thebrowser.browser",     // Arc
        "company.thebrowser.dia",         // Dia
        "com.operasoftware.opera",
        "com.operasoftware.operagx",
        "com.vivaldi.vivaldi",
        "com.duckduckgo.macos.browser",
        "app.zen-browser.zen",
        "com.kagi.kagimacos",             // Orion
        "com.sigmaos.sigmaos.macos",
        "org.torproject.torbrowser",
    ]

    /// Bundle-ID prefixes for browser families, so Beta/Dev/Canary and other
    /// channel variants are recognized without listing every one.
    private static let browserBundlePrefixes: [String] = [
        "com.google.chrome",
        "com.microsoft.edgemac",
        "com.brave.browser",
        "com.operasoftware.opera",
        "company.thebrowser.",
    ]

    var isBrowser: Bool {
        guard let bundleIdentifier else { return false }
        let id = bundleIdentifier.lowercased()
        if Self.browserBundleIdentifiers.contains(id) {
            return true
        }
        return Self.browserBundlePrefixes.contains { id.hasPrefix($0) }
    }
}

@Observable
final class FrontmostAppMonitor {
    private(set) var currentApp: FrontmostApp?

    private var observer: NSObjectProtocol?

    init(workspace: NSWorkspace = .shared) {
        currentApp = Self.frontmostApp(from: workspace.frontmostApplication)
        observer = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }

            self?.currentApp = Self.frontmostApp(from: app)
        }
    }

    deinit {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    func matchesDistraction(_ names: [String]) -> Bool {
        guard let currentApp else {
            return false
        }

        let normalizedTargets = names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        guard !normalizedTargets.isEmpty else {
            return false
        }

        let appName = currentApp.name.lowercased()
        let bundleID = currentApp.bundleIdentifier?.lowercased()
        let appWords = appName.split { !$0.isLetter && !$0.isNumber }.map(String.init)

        // For browsers, read the active tab/page title so web distractions
        // (e.g. "youtube") match even though the app is just "Safari".
        let windowTitle = currentApp.isBrowser
            ? Self.focusedWindowTitle(pid: currentApp.processIdentifier)?.lowercased()
            : nil

        return normalizedTargets.contains { target in
            // Entries that look like a bundle identifier match the bundle ID...
            if target.contains(".") {
                if bundleID == target || bundleID?.contains(target) == true {
                    return true
                }
                // ...but a dotted entry like "youtube.com" may also be a website,
                // so still check the browser tab title below.
            }

            // Display-name entries match the whole name or a whole word in it,
            // so short entries like "go" don't accidentally match "Google".
            if appName == target || appWords.contains(target) {
                return true
            }

            // Web distractions: match against the browser's active tab title.
            if let windowTitle, windowTitle.contains(target) {
                return true
            }

            return false
        }
    }

    private static func frontmostApp(from runningApp: NSRunningApplication?) -> FrontmostApp? {
        guard let runningApp else {
            return nil
        }

        return FrontmostApp(
            name: runningApp.localizedName ?? "Unknown App",
            bundleIdentifier: runningApp.bundleIdentifier,
            processIdentifier: runningApp.processIdentifier
        )
    }

    /// Reads the focused window's title of another app via the Accessibility API.
    /// Returns nil if Accessibility permission has not been granted.
    private static func focusedWindowTitle(pid: pid_t) -> String? {
        guard AXIsProcessTrusted() else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(pid)

        var windowValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowValue) == .success,
              let windowValue,
              CFGetTypeID(windowValue) == AXUIElementGetTypeID() else {
            return nil
        }

        let window = windowValue as! AXUIElement

        var titleValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue) == .success,
              let title = titleValue as? String,
              !title.isEmpty else {
            return nil
        }

        return title
    }

    /// If the app's focused window is in native macOS full screen, exit it via
    /// the Accessibility API. Returns true if it was full screen (and we asked
    /// it to exit). A full-screen app lives on its own Space and cannot be
    /// hidden with `hide()`, so callers should exit full screen first.
    @discardableResult
    static func exitFullScreenIfNeeded(pid: pid_t) -> Bool {
        guard AXIsProcessTrusted() else { return false }

        let appElement = AXUIElementCreateApplication(pid)

        var windowValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowValue) == .success,
              let windowValue,
              CFGetTypeID(windowValue) == AXUIElementGetTypeID() else {
            return false
        }

        let window = windowValue as! AXUIElement

        var fsValue: CFTypeRef?
        let hasAttr = AXUIElementCopyAttributeValue(window, "AXFullScreen" as CFString, &fsValue) == .success
        let isFullScreen = (fsValue as? Bool) ?? false

        guard hasAttr, isFullScreen else { return false }

        AXUIElementSetAttributeValue(window, "AXFullScreen" as CFString, kCFBooleanFalse)
        return true
    }
}
