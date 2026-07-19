import AppKit
import Foundation

struct RunningAppsProvider {
    func runningApps() -> [RunningAppInfo] {
        NSWorkspace.shared.runningApplications
            .filter { app in
                app.activationPolicy == .regular && app.localizedName != nil
            }
            .map { app in
                RunningAppInfo(
                    name: app.localizedName ?? "Unknown App",
                    bundleIdentifier: app.bundleIdentifier
                )
            }
            .reduce(into: [RunningAppInfo]()) { partialResult, app in
                guard !partialResult.contains(where: { $0.id == app.id }) else {
                    return
                }
                partialResult.append(app)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
