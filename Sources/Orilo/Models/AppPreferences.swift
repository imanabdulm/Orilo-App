import Foundation

struct AppPreferences: Codable, Equatable {
    enum Appearance: String, Codable, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system: "System"
            case .light: "Light"
            case .dark: "Dark"
            }
        }
    }

    var defaultDurationMinutes: Int
    var customDurationMinutes: Int
    var distractionAppNames: [String]
    var appearance: Appearance
    var openFocusSettingsOnStart: Bool
    var completionNotificationsEnabled: Bool
    var distractionNotificationsEnabled: Bool
    var distractionOverlayEnabled: Bool
    var launchAtLoginEnabled: Bool
    var soundEnabled: Bool
    var pomodoroEnabled: Bool
    var sessionsBeforeLongBreak: Int
    var breakDurationMinutes: Int
    var longBreakDurationMinutes: Int
    var hasCompletedOnboarding: Bool
    var defaultCreatorMode: CreatorMode
    var excludeWeekendsFromStreak: Bool

    static let defaults = AppPreferences(
        defaultDurationMinutes: 25,
        customDurationMinutes: 30,
        distractionAppNames: ["Safari", "Slack", "Discord", "Messages"],
        appearance: .system,
        openFocusSettingsOnStart: false,
        completionNotificationsEnabled: true,
        distractionNotificationsEnabled: true,
        distractionOverlayEnabled: true,
        launchAtLoginEnabled: false,
        soundEnabled: true,
        pomodoroEnabled: false,
        sessionsBeforeLongBreak: 4,
        breakDurationMinutes: 5,
        longBreakDurationMinutes: 15,
        hasCompletedOnboarding: false,
        defaultCreatorMode: .write,
        excludeWeekendsFromStreak: false
    )

    init(
        defaultDurationMinutes: Int,
        customDurationMinutes: Int,
        distractionAppNames: [String],
        appearance: Appearance,
        openFocusSettingsOnStart: Bool,
        completionNotificationsEnabled: Bool,
        distractionNotificationsEnabled: Bool,
        distractionOverlayEnabled: Bool = false,
        launchAtLoginEnabled: Bool,
        soundEnabled: Bool,
        pomodoroEnabled: Bool,
        sessionsBeforeLongBreak: Int,
        breakDurationMinutes: Int,
        longBreakDurationMinutes: Int,
        hasCompletedOnboarding: Bool,
        defaultCreatorMode: CreatorMode = .write,
        excludeWeekendsFromStreak: Bool = false
    ) {
        self.defaultDurationMinutes = defaultDurationMinutes
        self.customDurationMinutes = customDurationMinutes
        self.distractionAppNames = distractionAppNames
        self.appearance = appearance
        self.openFocusSettingsOnStart = openFocusSettingsOnStart
        self.completionNotificationsEnabled = completionNotificationsEnabled
        self.distractionNotificationsEnabled = distractionNotificationsEnabled
        self.distractionOverlayEnabled = distractionOverlayEnabled
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.soundEnabled = soundEnabled
        self.pomodoroEnabled = pomodoroEnabled
        self.sessionsBeforeLongBreak = sessionsBeforeLongBreak
        self.breakDurationMinutes = breakDurationMinutes
        self.longBreakDurationMinutes = longBreakDurationMinutes
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.defaultCreatorMode = defaultCreatorMode
        self.excludeWeekendsFromStreak = excludeWeekendsFromStreak
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self.defaults

        defaultDurationMinutes = try container.decodeIfPresent(Int.self, forKey: .defaultDurationMinutes) ?? defaults.defaultDurationMinutes
        customDurationMinutes = try container.decodeIfPresent(Int.self, forKey: .customDurationMinutes) ?? defaults.customDurationMinutes
        distractionAppNames = try container.decodeIfPresent([String].self, forKey: .distractionAppNames) ?? defaults.distractionAppNames
        appearance = try container.decodeIfPresent(Appearance.self, forKey: .appearance) ?? defaults.appearance
        openFocusSettingsOnStart = try container.decodeIfPresent(Bool.self, forKey: .openFocusSettingsOnStart) ?? defaults.openFocusSettingsOnStart
        completionNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .completionNotificationsEnabled) ?? defaults.completionNotificationsEnabled
        distractionNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .distractionNotificationsEnabled) ?? defaults.distractionNotificationsEnabled
        distractionOverlayEnabled = try container.decodeIfPresent(Bool.self, forKey: .distractionOverlayEnabled) ?? defaults.distractionOverlayEnabled
        launchAtLoginEnabled = try container.decodeIfPresent(Bool.self, forKey: .launchAtLoginEnabled) ?? defaults.launchAtLoginEnabled
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? defaults.soundEnabled
        pomodoroEnabled = try container.decodeIfPresent(Bool.self, forKey: .pomodoroEnabled) ?? defaults.pomodoroEnabled
        sessionsBeforeLongBreak = try container.decodeIfPresent(Int.self, forKey: .sessionsBeforeLongBreak) ?? defaults.sessionsBeforeLongBreak
        breakDurationMinutes = try container.decodeIfPresent(Int.self, forKey: .breakDurationMinutes) ?? defaults.breakDurationMinutes
        longBreakDurationMinutes = try container.decodeIfPresent(Int.self, forKey: .longBreakDurationMinutes) ?? defaults.longBreakDurationMinutes
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? defaults.hasCompletedOnboarding
        defaultCreatorMode = try container.decodeIfPresent(CreatorMode.self, forKey: .defaultCreatorMode) ?? defaults.defaultCreatorMode
        excludeWeekendsFromStreak = try container.decodeIfPresent(Bool.self, forKey: .excludeWeekendsFromStreak) ?? defaults.excludeWeekendsFromStreak
    }
}
