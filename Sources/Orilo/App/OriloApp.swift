import AppKit
import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private weak var viewModel: FocusViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if NotificationService.isSupported {
            NotificationService.registerNotificationCategories()
            UNUserNotificationCenter.current().delegate = self
        }
    }

    @MainActor
    func applicationWillTerminate(_ notification: Notification) {
        viewModel?.persistCurrentSessionState()
    }

    @MainActor
    func configure(viewModel: FocusViewModel) {
        self.viewModel = viewModel
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor [weak self] in
            switch response.actionIdentifier {
            case NotificationService.ActionIdentifier.openOrilo, UNNotificationDefaultActionIdentifier:
                NSApp.activate(ignoringOtherApps: true)
            case NotificationService.ActionIdentifier.muteDistractionRemindersForSession:
                self?.viewModel?.muteDistractionRemindersForCurrentSession()
            default:
                break
            }

            completionHandler()
        }
    }
}

@main
struct OriloApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var viewModel: FocusViewModel

    init() {
        let viewModel = FocusViewModel()
        _viewModel = State(initialValue: viewModel)

        if !viewModel.preferences.hasCompletedOnboarding {
            Task { @MainActor in
                await Task.yield()
                OnboardingWindowPresenter.shared.show(viewModel: viewModel)
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            if viewModel.preferences.hasCompletedOnboarding {
                MenuBarRootView(viewModel: viewModel)
                    .preferredColorScheme(viewModel.preferredColorScheme)
                    .onAppear {
                        appDelegate.configure(viewModel: viewModel)
                    }
            } else {
                EmptyView()
            }
        } label: {
            if viewModel.preferences.hasCompletedOnboarding {
                MenuBarIcon()
            } else {
                EmptyView()
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            PreferencesView(viewModel: viewModel)
                .preferredColorScheme(viewModel.preferredColorScheme)
        }

        Window("Orilo Insights", id: "history") {
            HistoryView(viewModel: viewModel)
                .preferredColorScheme(viewModel.preferredColorScheme)
        }
        .defaultSize(width: 680, height: 420)
    }
}

private final class OnboardingWindowPresenter: NSObject, NSWindowDelegate {
    static let shared = OnboardingWindowPresenter()

    private var window: NSWindow?

    @MainActor
    func show(viewModel: FocusViewModel) {
        guard window == nil else {
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingView = NSHostingView(
            rootView: OnboardingView(viewModel: viewModel) { [weak self] in
                self?.close()
            }
                .preferredColorScheme(viewModel.preferredColorScheme)
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Orilo"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.center()
        window.delegate = self
        window.titlebarAppearsTransparent = true

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @MainActor
    private func close() {
        window?.close()
        window = nil
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}

private struct MenuBarIcon: View {
    private let iconSize: CGFloat = 18

    var body: some View {
        if let image = NSImage(named: "MenuBarIconTemplate") {
            Image(nsImage: configuredTemplateImage(image, pointSize: iconSize))
                .renderingMode(.template)
                .frame(width: iconSize, height: iconSize)
                .clipped()
                .accessibilityHidden(true)
        } else {
            Image(systemName: "camera.macro.circle.fill")
                .font(.system(size: iconSize, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)
        }
    }

    private func configuredTemplateImage(_ image: NSImage, pointSize: CGFloat) -> NSImage {
        let configuredImage = image.copy() as? NSImage ?? image
        configuredImage.isTemplate = true
        configuredImage.size = NSSize(width: pointSize, height: pointSize)
        return configuredImage
    }
}
