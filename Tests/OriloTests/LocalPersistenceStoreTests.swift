import XCTest
@testable import Orilo

final class LocalPersistenceStoreTests: XCTestCase {
    private var tempURL: URL!

    override func setUpWithError() throws {
        tempURL = FileManager.default.temporaryDirectory
            .appending(path: "OriloTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    override func tearDownWithError() throws {
        if let tempURL {
            try? FileManager.default.removeItem(at: tempURL)
        }
    }

    func testPreferencesRoundTrip() {
        let store = LocalPersistenceStore(baseURL: tempURL)
        let preferences = AppPreferences(
            defaultDurationMinutes: 60,
            customDurationMinutes: 40,
            distractionAppNames: ["com.apple.Safari"],
            appearance: .light,
            openFocusSettingsOnStart: true,
            completionNotificationsEnabled: false,
            distractionNotificationsEnabled: true,
            launchAtLoginEnabled: false,
            soundEnabled: false,
            pomodoroEnabled: true,
            sessionsBeforeLongBreak: 3,
            breakDurationMinutes: 7,
            longBreakDurationMinutes: 20,
            hasCompletedOnboarding: true
        )

        store.savePreferences(preferences)

        XCTAssertEqual(store.loadPreferences(), preferences)
    }

    func testRecapsRoundTrip() {
        let store = LocalPersistenceStore(baseURL: tempURL)
        let recap = SessionRecap(
            sessionID: UUID(),
            intention: "Write draft",
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 200),
            plannedDuration: 1500,
            focusedDuration: 100,
            reflection: "Good first pass"
        )

        store.saveRecaps([recap])

        XCTAssertEqual(store.loadRecaps(), [recap])
    }
}
