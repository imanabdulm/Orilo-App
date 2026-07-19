import XCTest
@testable import Orilo

@MainActor
final class FocusViewModelTests: XCTestCase {
    private var tempURL: URL!

    override func setUpWithError() throws {
        tempURL = FileManager.default.temporaryDirectory
            .appending(path: "OriloViewModelTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    override func tearDownWithError() throws {
        if let tempURL {
            try? FileManager.default.removeItem(at: tempURL)
        }
    }

    func testAddingDistractionAppsDeduplicatesCaseInsensitively() {
        let viewModel = makeViewModel()
        viewModel.preferences.distractionAppNames = []

        viewModel.addDistractionApp(named: "Safari")
        viewModel.addDistractionApp(named: "safari")

        XCTAssertEqual(viewModel.preferences.distractionAppNames, ["Safari"])
    }

    func testEndingSessionCreatesRecap() {
        let viewModel = makeViewModel()
        viewModel.intention = "Make a storyboard"
        viewModel.selectDuration(25)

        viewModel.startSession()
        viewModel.skipSettling()
        viewModel.remainingSeconds = 24 * 60
        viewModel.endSession()

        XCTAssertEqual(viewModel.recaps.count, 1)
        XCTAssertEqual(viewModel.recaps[0].intention, "Make a storyboard")
        XCTAssertEqual(viewModel.recaps[0].focusedDuration, 60)
    }

    func testStartingSessionBeginsWithSettlingRitual() {
        let viewModel = makeViewModel()
        viewModel.intention = "Draft opening scene"

        viewModel.startSession()

        XCTAssertEqual(viewModel.phase, .settling)
        XCTAssertEqual(viewModel.settleRemainingSeconds, 5)
        XCTAssertEqual(viewModel.remainingSeconds, 25 * 60)
    }

    func testSkippingSettlingStartsCountdown() {
        let viewModel = makeViewModel()
        viewModel.intention = "Draft opening scene"

        viewModel.startSession()
        viewModel.skipSettling()

        XCTAssertEqual(viewModel.phase, .running)
        XCTAssertEqual(viewModel.remainingSeconds, 25 * 60)
    }

    func testPomodoroEnabledStartsBreakAfterNaturalCompletion() async throws {
        let viewModel = makeViewModel()
        viewModel.preferences.pomodoroEnabled = true
        viewModel.preferences.completionNotificationsEnabled = false
        viewModel.preferences.distractionNotificationsEnabled = false
        viewModel.preferences.breakDurationMinutes = 3
        viewModel.intention = "Draft opening scene"

        viewModel.startSession()
        viewModel.skipSettling()
        viewModel.remainingSeconds = 1

        try await Task.sleep(nanoseconds: 1_250_000_000)

        XCTAssertEqual(viewModel.phase, .breakTime)
        XCTAssertEqual(viewModel.breakRemainingSeconds, 3 * 60)
        XCTAssertEqual(viewModel.completedPomodoroCount, 1)
    }

    func testCustomDurationCanMatchPresetAndRemainSelected() {
        let viewModel = makeViewModel()

        viewModel.selectCustomDuration()
        viewModel.updateCustomDuration(45)

        XCTAssertTrue(viewModel.isCustomDurationSelected)
        XCTAssertEqual(viewModel.currentDurationMinutes, 45)
        XCTAssertEqual(viewModel.remainingSeconds, 45 * 60)
    }

    func testSelectingCreatorModePersistsAsDefault() {
        let viewModel = makeViewModel()

        viewModel.selectCreatorMode(.work)

        XCTAssertEqual(viewModel.selectedCreatorMode, .work)
        XCTAssertEqual(viewModel.preferences.defaultCreatorMode, .work)
        XCTAssertTrue(CreatorMode.allCases.contains(.research))
        XCTAssertFalse(CreatorMode.work.ritualPrompt.isEmpty)
    }

    func testProtectionRateAndSuggestedNextIntentionUseRecaps() {
        let viewModel = makeViewModel()

        viewModel.recaps = [
            makeRecap(intention: "Revise chapter", endedAt: .now, protectedIntention: false),
            makeRecap(intention: "Sketch layout", endedAt: .now.addingTimeInterval(-3600), protectedIntention: true)
        ]

        XCTAssertEqual(viewModel.protectionRate, 0.5)
        XCTAssertEqual(viewModel.suggestedNextIntention, "Revise chapter")
    }

    func testRitualSuggestionPrioritizesUnprotectedRecap() {
        let viewModel = makeViewModel()
        let recap = makeRecap(
            intention: "Finish launch copy",
            endedAt: .now,
            protectedIntention: false
        )

        let suggestion = viewModel.ritualSuggestion(for: recap)

        XCTAssertEqual(suggestion.title, "Continue this intention")
        XCTAssertEqual(suggestion.intention, "Finish launch copy")
        XCTAssertTrue(suggestion.detail.contains("deserves another pass"))
    }

    func testWeeklyProofMetricsUseRecentSessions() {
        let viewModel = makeViewModel()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now).addingTimeInterval(12 * 60 * 60)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let oldDate = calendar.date(byAdding: .day, value: -9, to: today)!

        viewModel.recaps = [
            makeRecap(intention: "Draft", endedAt: today, creatorMode: .write, protectedIntention: true),
            makeRecap(intention: "Review", endedAt: yesterday, creatorMode: .work, distractionCounts: ["Slack": 2], protectedIntention: false),
            makeRecap(intention: "Old work", endedAt: oldDate, creatorMode: .code, distractionCounts: ["Discord": 10], protectedIntention: false)
        ]

        let metrics = viewModel.weeklyProofMetrics

        XCTAssertEqual(metrics.map(\.title), ["Protected", "Best mode", "Main pull"])
        XCTAssertEqual(metrics[0].value, "50%")
        XCTAssertEqual(metrics[1].value, "Write")
        XCTAssertEqual(metrics[2].value, "Slack")
    }

    func testSavingReflectionAndClosePersistsThenReturnsIdle() {
        let viewModel = makeViewModel()
        let recap = makeRecap(intention: "Design Thinking", endedAt: .now)
        viewModel.recaps = [recap]
        viewModel.phase = .completed(recap)
        viewModel.reflectionText = "Clarified the outline"

        viewModel.saveReflectionAndClose(for: recap)

        XCTAssertEqual(viewModel.phase, .idle)
        XCTAssertEqual(viewModel.recaps.first?.reflection, "Clarified the outline")
        XCTAssertEqual(viewModel.reflectionText, "")
    }

    func testRecapDiagnosisPrioritizesRevisitThenInterruptedThenClean() {
        let viewModel = makeViewModel()
        let revisit = makeRecap(
            intention: "Revise",
            endedAt: .now,
            distractionCounts: ["Discord": 2],
            protectedIntention: false
        )
        let interrupted = makeRecap(
            intention: "Draft",
            endedAt: .now,
            distractionCounts: ["Slack": 1]
        )
        let clean = makeRecap(intention: "Read", endedAt: .now)

        XCTAssertEqual(viewModel.diagnosis(for: revisit), .revisit)
        XCTAssertEqual(viewModel.diagnosis(for: interrupted), .interrupted)
        XCTAssertEqual(viewModel.diagnosis(for: clean), .clean)
    }

    func testEndingDuringSettlingCancelsWithoutRecap() {
        let viewModel = makeViewModel()
        viewModel.intention = "Draft opening scene"

        viewModel.startSession()
        viewModel.endSession()

        XCTAssertEqual(viewModel.phase, .idle)
        XCTAssertTrue(viewModel.recaps.isEmpty)
    }

    func testMutingDistractionRemindersOnlyAppliesToCurrentSession() {
        let viewModel = makeViewModel()
        viewModel.intention = "Draft opening scene"

        viewModel.startSession()
        viewModel.muteDistractionRemindersForCurrentSession()

        XCTAssertTrue(viewModel.areDistractionRemindersMutedForSession)

        viewModel.endSession()
        XCTAssertFalse(viewModel.areDistractionRemindersMutedForSession)

        viewModel.startSession()

        XCTAssertFalse(viewModel.areDistractionRemindersMutedForSession)
    }

    func testUnmutingDistractionRemindersRestoresCurrentSessionReminders() {
        let viewModel = makeViewModel()
        viewModel.intention = "Draft opening scene"

        viewModel.startSession()
        viewModel.muteDistractionRemindersForCurrentSession()
        viewModel.unmuteDistractionRemindersForCurrentSession()

        XCTAssertFalse(viewModel.areDistractionRemindersMutedForSession)
    }

    func testHistoryInsightsCalculateStreakAndTopIntention() {
        let viewModel = makeViewModel()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now).addingTimeInterval(10 * 60)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: today)!

        viewModel.recaps = [
            makeRecap(intention: "Storyboard", endedAt: today, focusedDuration: 1500),
            makeRecap(intention: "Storyboard", endedAt: yesterday, focusedDuration: 2700),
            makeRecap(intention: "Draft", endedAt: twoDaysAgo, focusedDuration: 3600),
            makeRecap(intention: "Storyboard", endedAt: fourDaysAgo, focusedDuration: 1200)
        ]

        XCTAssertEqual(viewModel.currentStreakDays, 3)
        XCTAssertEqual(viewModel.topIntention, "Storyboard")
    }

    func testHistoryInsightsAllowYesterdayStreakWhenTodayIsEmpty() {
        let viewModel = makeViewModel()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: .now))!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: .now))!

        viewModel.recaps = [
            makeRecap(intention: "Draft", endedAt: yesterday, focusedDuration: 1500),
            makeRecap(intention: "Draft", endedAt: twoDaysAgo, focusedDuration: 1500)
        ]

        XCTAssertEqual(viewModel.currentStreakDays, 2)
    }

    func testHistorySectionsGroupFilteredRecapsByDayNewestFirst() {
        let viewModel = makeViewModel()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let lateToday = today.addingTimeInterval(18 * 60 * 60)
        let earlyToday = today.addingTimeInterval(9 * 60 * 60)
        let yesterdayRecap = yesterday.addingTimeInterval(14 * 60 * 60)

        viewModel.recaps = [
            makeRecap(intention: "Late sketch", endedAt: lateToday, focusedDuration: 1500),
            makeRecap(intention: "Yesterday draft", endedAt: yesterdayRecap, focusedDuration: 2700),
            makeRecap(intention: "Morning outline", endedAt: earlyToday, focusedDuration: 900)
        ]

        let sections = viewModel.historySections

        XCTAssertEqual(sections.count, 2)
        XCTAssertTrue(calendar.isDateInToday(sections[0].day))
        XCTAssertEqual(sections[0].recaps.map(\.intention), ["Late sketch", "Morning outline"])
        XCTAssertEqual(sections[1].recaps.map(\.intention), ["Yesterday draft"])
    }

    private func makeViewModel() -> FocusViewModel {
        let viewModel = FocusViewModel(
            store: LocalPersistenceStore(baseURL: tempURL),
            focusModeCoordinator: FocusModeCoordinator(),
            notificationService: NotificationService(),
            launchAtLoginService: LaunchAtLoginService(),
            runningAppsProvider: RunningAppsProvider()
        )
        viewModel.preferences.completionNotificationsEnabled = false
        viewModel.preferences.distractionNotificationsEnabled = false
        return viewModel
    }

    private func makeRecap(
        intention: String,
        endedAt: Date,
        creatorMode: CreatorMode = .write,
        focusedDuration: TimeInterval = 1500,
        distractionCounts: [String: Int] = [:],
        protectedIntention: Bool? = nil
    ) -> SessionRecap {
        SessionRecap(
            sessionID: UUID(),
            intention: intention,
            creatorMode: creatorMode,
            startedAt: endedAt.addingTimeInterval(-focusedDuration),
            endedAt: endedAt,
            plannedDuration: focusedDuration,
            focusedDuration: focusedDuration,
            distractionCounts: distractionCounts,
            protectedIntention: protectedIntention
        )
    }
}
