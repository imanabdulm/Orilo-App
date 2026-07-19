import AppKit
import Foundation

struct FocusModeCoordinator {
    func openFocusSettingsIfRequested(_ shouldOpen: Bool) {
        guard shouldOpen else {
            return
        }

        let url = URL(string: "x-apple.systempreferences:com.apple.Focus-Settings.extension")!
        NSWorkspace.shared.open(url)
    }
}
