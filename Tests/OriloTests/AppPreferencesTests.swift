import XCTest
@testable import Orilo

final class AppPreferencesTests: XCTestCase {
    func testDecodingLegacyPreferencesFillsNewDefaults() throws {
        let json = """
        {
          "defaultDurationMinutes": 45,
          "customDurationMinutes": 35,
          "distractionAppNames": ["Safari"],
          "appearance": "dark",
          "openFocusSettingsOnStart": true
        }
        """.data(using: .utf8)!

        let preferences = try JSONDecoder().decode(AppPreferences.self, from: json)

        XCTAssertEqual(preferences.defaultDurationMinutes, 45)
        XCTAssertEqual(preferences.customDurationMinutes, 35)
        XCTAssertEqual(preferences.distractionAppNames, ["Safari"])
        XCTAssertEqual(preferences.appearance, .dark)
        XCTAssertTrue(preferences.openFocusSettingsOnStart)
        XCTAssertTrue(preferences.completionNotificationsEnabled)
        XCTAssertTrue(preferences.distractionNotificationsEnabled)
        XCTAssertFalse(preferences.launchAtLoginEnabled)
        XCTAssertTrue(preferences.soundEnabled)
        XCTAssertFalse(preferences.pomodoroEnabled)
        XCTAssertEqual(preferences.sessionsBeforeLongBreak, 4)
        XCTAssertEqual(preferences.breakDurationMinutes, 5)
        XCTAssertEqual(preferences.longBreakDurationMinutes, 15)
        XCTAssertFalse(preferences.hasCompletedOnboarding)
        XCTAssertEqual(preferences.defaultCreatorMode, .write)
    }
}
