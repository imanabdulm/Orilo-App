import Foundation
import UserNotifications

struct NotificationService {
    enum AuthorizationStatus: Equatable {
        case notDetermined
        case authorized
        case denied
        case provisional
        case ephemeral
        case unknown

        var title: String {
            switch self {
            case .notDetermined: "Not Asked"
            case .authorized: "Allowed"
            case .denied: "Denied"
            case .provisional: "Quiet"
            case .ephemeral: "Temporary"
            case .unknown: "Unknown"
            }
        }
    }

    enum ActionIdentifier {
        static let openOrilo = "OPEN_ORILO"
        static let muteDistractionRemindersForSession = "MUTE_DISTRACTION_REMINDERS_FOR_SESSION"
    }

    enum CategoryIdentifier {
        static let sessionComplete = "ORILO_SESSION_COMPLETE"
        static let distractionReminder = "ORILO_DISTRACTION_REMINDER"
    }

    static var isSupported: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    static func registerNotificationCategories() {
        guard isSupported else { return }

        let openOriloAction = UNNotificationAction(
            identifier: ActionIdentifier.openOrilo,
            title: "Open Orilo",
            options: [.foreground]
        )

        let muteReminderAction = UNNotificationAction(
            identifier: ActionIdentifier.muteDistractionRemindersForSession,
            title: "Mute This Session",
            options: []
        )

        let sessionCompleteCategory = UNNotificationCategory(
            identifier: CategoryIdentifier.sessionComplete,
            actions: [openOriloAction],
            intentIdentifiers: [],
            options: []
        )

        let distractionReminderCategory = UNNotificationCategory(
            identifier: CategoryIdentifier.distractionReminder,
            actions: [openOriloAction, muteReminderAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            sessionCompleteCategory,
            distractionReminderCategory
        ])
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        guard Self.isSupported else { return false }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound])
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    func authorizationStatus() async -> AuthorizationStatus {
        guard Self.isSupported else { return .unknown }
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        case .ephemeral:
            return .ephemeral
        @unknown default:
            return .unknown
        }
    }

    func sendSessionComplete(intention: String, focusedMinutes: Int) async {
        guard await requestAuthorizationIfNeeded() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Orilo session complete"
        content.body = "\(focusedMinutes)m protected for \(intention)"
        content.categoryIdentifier = CategoryIdentifier.sessionComplete
        content.sound = .default

        await schedule(content, identifier: "orilo-session-complete-\(UUID().uuidString)")
    }

    func sendDistractionReminder(appName: String, intention: String) async {
        guard await requestAuthorizationIfNeeded() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Gentle check-in"
        content.body = "\(appName) is on your distraction list. Return to \(intention)."
        content.categoryIdentifier = CategoryIdentifier.distractionReminder
        content.sound = .default

        await schedule(content, identifier: "orilo-distraction-\(UUID().uuidString)")
    }

    func scheduleStreakProtectionReminder(streakDays: Int, at hour: Int = 19) async {
        guard await requestAuthorizationIfNeeded() else { return }

        // Cancel any existing streak reminder before scheduling a new one
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["orilo-streak-protection"]
        )

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0

        let content = UNMutableNotificationContent()
        content.title = streakDays == 1
            ? "Keep your focus ritual going"
            : "Don't break your \(streakDays)-day streak 🔥"
        content.body = "Protect one outcome before the day ends."
        content.categoryIdentifier = CategoryIdentifier.sessionComplete
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "orilo-streak-protection",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Non-critical, ignore
        }
    }

    func cancelStreakProtectionReminder() {
        guard Self.isSupported else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["orilo-streak-protection"]
        )
    }

    private func schedule(_ content: UNMutableNotificationContent, identifier: String) async {
        guard Self.isSupported else { return }
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            assertionFailure("Failed to schedule Orilo notification: \(error.localizedDescription)")
        }
    }
}
