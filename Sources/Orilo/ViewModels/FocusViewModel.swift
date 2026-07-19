import AppKit
import ApplicationServices
import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class FocusViewModel {
    enum RecapDiagnosis: String {
        case clean = "Clean"
        case interrupted = "Interrupted"
        case revisit = "Revisit"

        var systemImage: String {
            switch self {
            case .clean: "checkmark.circle"
            case .interrupted: "hand.raised"
            case .revisit: "arrow.clockwise"
            }
        }
    }

    enum HistoryFilter: String, CaseIterable, Identifiable {
        case all
        case sevenDays
        case today

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: "All"
            case .sevenDays: "7 Days"
            case .today: "Today"
            }
        }
    }

    enum SessionPhase: Equatable {
        case idle
        case settling
        case running
        case paused
        case breakTime
        case completed(SessionRecap)
    }

    struct HistorySection: Identifiable, Equatable {
        let day: Date
        let recaps: [SessionRecap]

        var id: Date { day }
    }

    struct RitualSuggestion: Equatable {
        let title: String
        let detail: String
        let systemImage: String
        let intention: String?
    }

    struct ProofMetric: Identifiable, Equatable {
        let id: String
        let title: String
        let value: String
        let detail: String
    }

    var phase: SessionPhase = .idle
    var intention = ""
    var selectedDurationMinutes = 25
    var customDurationMinutes = 30
    var isCustomDurationSelected = false
    var selectedCreatorMode: CreatorMode = .write
    var reflectionText = ""
    var preferences: AppPreferences
    var recaps: [SessionRecap]
    var activeSession: FocusSession?
    var remainingSeconds: Int = 25 * 60
    var settleRemainingSeconds = 5
    var runningApps: [RunningAppInfo] = []
    var launchAtLoginErrorMessage: String?
    var historyFilter: HistoryFilter = .all
    var notificationAuthorizationStatus: NotificationService.AuthorizationStatus = .unknown
    var accessibilityTrusted: Bool = AXIsProcessTrusted()
    var currentSessionDistractionCounts: [String: Int] = [:]
    private(set) var areDistractionRemindersMutedForSession = false
    var breakRemainingSeconds: Int = 5 * 60
    var completedPomodoroCount: Int = 0

    let durationPresets = [25, 45, 60]
    let frontmostAppMonitor = FrontmostAppMonitor()
    private let distractionOverlay = DistractionOverlayController()
    private var lastOverlayShownAt: Date?
    private var lastOverlayApp: String?

    private let store: LocalPersistenceStore
    private let focusModeCoordinator: FocusModeCoordinator
    private let notificationService: NotificationService
    private let launchAtLoginService: LaunchAtLoginService
    private let runningAppsProvider: RunningAppsProvider
    private let soundService: SoundService
    private let dataExportService: DataExportService
    private var timer: Timer?
    private var lastDistractionNotificationAt: Date?
    private var lastDistractionNotificationApp: String?
    private var lastTrackedDistractionApp: String?

    init(
        store: LocalPersistenceStore = LocalPersistenceStore(),
        focusModeCoordinator: FocusModeCoordinator = FocusModeCoordinator(),
        notificationService: NotificationService = NotificationService(),
        launchAtLoginService: LaunchAtLoginService = LaunchAtLoginService(),
        runningAppsProvider: RunningAppsProvider = RunningAppsProvider(),
        soundService: SoundService = SoundService(),
        dataExportService: DataExportService = DataExportService()
    ) {
        self.store = store
        self.focusModeCoordinator = focusModeCoordinator
        self.notificationService = notificationService
        self.launchAtLoginService = launchAtLoginService
        self.runningAppsProvider = runningAppsProvider
        self.soundService = soundService
        self.dataExportService = dataExportService
        preferences = store.loadPreferences()
        recaps = store.loadRecaps().sorted { $0.endedAt > $1.endedAt }
        selectedDurationMinutes = preferences.defaultDurationMinutes
        customDurationMinutes = preferences.customDurationMinutes
        selectedCreatorMode = preferences.defaultCreatorMode
        remainingSeconds = preferences.defaultDurationMinutes * 60
        preferences.launchAtLoginEnabled = launchAtLoginService.isEnabled
        runningApps = runningAppsProvider.runningApps()
        restoreActiveSessionIfNeeded()
    }

    var preferredColorScheme: ColorScheme? {
        switch preferences.appearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var menuBarTitle: String {
        switch phase {
        case .idle, .completed:
            return "Orilo"
        case .settling:
            return "Settle"
        case .running, .paused:
            return TimeFormatting.clock(remainingSeconds)
        case .breakTime:
            return "Break " + TimeFormatting.clock(breakRemainingSeconds)
        }
    }

    var menuBarSystemImage: String {
        switch phase {
        case .idle, .settling: "timer.circle.fill"
        case .running: "timer.circle.fill"
        case .paused: "pause.circle.fill"
        case .breakTime: "cup.and.saucer.fill"
        case .completed: "checkmark.circle.fill"
        }
    }

    var canStart: Bool {
        !intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isActive: Bool {
        phase == .settling || phase == .running || phase == .paused || phase == .breakTime
    }

    var isOnBreak: Bool { phase == .breakTime }

    var breakProgress: Double {
        let total = currentBreakDurationSeconds
        guard total > 0 else { return 0 }
        let elapsed = total - breakRemainingSeconds
        return min(max(Double(elapsed) / Double(total), 0), 1)
    }

    var currentBreakDurationSeconds: Int {
        if preferences.pomodoroEnabled && completedPomodoroCount > 0 && completedPomodoroCount % preferences.sessionsBeforeLongBreak == 0 {
            return preferences.longBreakDurationMinutes * 60
        }
        return preferences.breakDurationMinutes * 60
    }

    var isLongBreak: Bool {
        preferences.pomodoroEnabled && completedPomodoroCount > 0 && completedPomodoroCount % preferences.sessionsBeforeLongBreak == 0
    }

    var isRunning: Bool {
        phase == .running
    }

    var selectedDuration: TimeInterval {
        TimeInterval(currentDurationMinutes * 60)
    }

    var currentDurationMinutes: Int {
        isCustomDurationSelected ? customDurationMinutes : selectedDurationMinutes
    }

    var distractionAppName: String? {
        guard isRunning,
              frontmostAppMonitor.matchesDistraction(preferences.distractionAppNames) else {
            return nil
        }

        return frontmostAppMonitor.currentApp?.name
    }

    var todaysRecaps: [SessionRecap] {
        recaps.filter { Calendar.current.isDateInToday($0.endedAt) }
    }

    var todaysCompletedCount: Int {
        todaysRecaps.count
    }

    var todaysFocusedSeconds: Int {
        Int(todaysRecaps.reduce(0) { $0 + $1.focusedDuration })
    }

    var sessionProgress: Double {
        guard let activeSession, activeSession.plannedDuration > 0 else {
            return 0
        }

        let elapsed = activeSession.plannedDuration - TimeInterval(remainingSeconds)
        return min(max(elapsed / activeSession.plannedDuration, 0), 1)
    }

    var weeklyRecaps: [SessionRecap] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        guard let startOfWindow = calendar.date(byAdding: .day, value: -6, to: startOfToday) else {
            return todaysRecaps
        }

        return recaps.filter { $0.endedAt >= startOfWindow }
    }

    var weeklyFocusedSeconds: Int {
        Int(weeklyRecaps.reduce(0) { $0 + $1.focusedDuration })
    }

    var weeklyCompletedCount: Int {
        weeklyRecaps.count
    }

    var filteredHistoryRecaps: [SessionRecap] {
        switch historyFilter {
        case .all:
            return recaps
        case .sevenDays:
            return weeklyRecaps
        case .today:
            return todaysRecaps
        }
    }

    var historySections: [HistorySection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredHistoryRecaps) {
            calendar.startOfDay(for: $0.endedAt)
        }

        return grouped
            .map { day, recaps in
                HistorySection(
                    day: day,
                    recaps: recaps.sorted { $0.endedAt > $1.endedAt }
                )
            }
            .sorted { $0.day > $1.day }
    }

    var currentStreakDays: Int {
        let calendar = Calendar.current
        let completedDays = Set(recaps.map { calendar.startOfDay(for: $0.endedAt) })

        guard !completedDays.isEmpty else {
            return 0
        }

        let today = calendar.startOfDay(for: .now)
        let startDay = completedDays.contains(today)
            ? today
            : calendar.date(byAdding: .day, value: -1, to: today)!

        var streak = 0
        var cursor = startDay

        while true {
            if completedDays.contains(cursor) {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
                cursor = previousDay
            } else if preferences.excludeWeekendsFromStreak && calendar.isDateInWeekend(cursor) {
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
                cursor = previousDay
            } else {
                break
            }
        }

        return streak
    }

    var longestStreak: Int {
        let calendar = Calendar.current
        let sortedDays = Set(recaps.map { calendar.startOfDay(for: $0.endedAt) })
            .sorted()

        guard !sortedDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for i in 1..<sortedDays.count {
            let diff = calendar.dateComponents([.day], from: sortedDays[i - 1], to: sortedDays[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }

        return longest
    }

    var pendingMilestone: MilestoneView.Milestone? {
        let total = recaps.count
        let clean = recaps.filter { $0.totalDistractions == 0 }.count
        let streak = currentStreakDays

        if [1, 5, 10, 25, 50, 100].contains(total) {
            return MilestoneView.Milestone(
                title: total == 1 ? "First ritual complete!" : "Focus milestone!",
                detail: total == 1
                    ? "You protected your first outcome. That's the hardest one."
                    : "\(total) rituals completed. Every one is proof.",
                systemImage: "checkmark.seal.fill",
                value: "\(total)"
            )
        }

        if [5, 10, 25].contains(clean) {
            return MilestoneView.Milestone(
                title: "Clean focus!",
                detail: "\(clean) sessions with zero distractions. This is real protection.",
                systemImage: "shield.fill",
                value: "\(clean)×"
            )
        }

        if [3, 7, 14, 30].contains(streak) {
            return MilestoneView.Milestone(
                title: "\(streak)-day streak!",
                detail: streak >= 7
                    ? "A full week of protected work. Momentum is building."
                    : "\(streak) days in a row. Keep the ritual going.",
                systemImage: "flame.fill",
                value: "\(streak)d"
            )
        }

        return nil
    }

    var topIntention: String? {
        let grouped = Dictionary(grouping: recaps) {
            $0.intention.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        guard let topGroup = grouped
            .filter({ !$0.key.isEmpty })
            .max(by: { lhs, rhs in
                if lhs.value.count == rhs.value.count {
                    return lhs.value.reduce(0) { $0 + $1.focusedDuration } < rhs.value.reduce(0) { $0 + $1.focusedDuration }
                }
                return lhs.value.count < rhs.value.count
            }) else {
            return nil
        }

        return topGroup.value.first?.intention
    }

    var topDistraction: (name: String, count: Int)? {
        recaps
            .flatMap { $0.distractionCounts }
            .reduce(into: [String: Int]()) { totals, item in
                totals[item.key, default: 0] += item.value
            }
            .max { lhs, rhs in lhs.value < rhs.value }
            .map { (name: $0.key, count: $0.value) }
    }

    var cleanestSession: SessionRecap? {
        recaps
            .filter { $0.focusedDuration > 0 }
            .min {
                if $0.totalDistractions == $1.totalDistractions {
                    return $0.endedAt > $1.endedAt
                }
                return $0.totalDistractions < $1.totalDistractions
            }
    }

    var cleanestMode: (mode: CreatorMode, cleanCount: Int)? {
        let grouped = Dictionary(grouping: recaps.filter { $0.totalDistractions == 0 }) { $0.creatorMode }

        return grouped
            .map { (mode: $0.key, cleanCount: $0.value.count) }
            .max { lhs, rhs in lhs.cleanCount < rhs.cleanCount }
    }

    var protectionRate: Double? {
        let answered = recaps.compactMap(\.protectedIntention)
        guard !answered.isEmpty else {
            return nil
        }

        let protectedCount = answered.filter { $0 }.count
        return Double(protectedCount) / Double(answered.count)
    }

    var suggestedNextIntention: String? {
        recaps.first { recap in
            if recap.protectedIntention == false {
                return true
            }
            return recap.totalDistractions > 0
        }?.intention
    }

    var nextRitualSuggestion: RitualSuggestion {
        suggestion(from: filteredHistoryRecaps.first ?? recaps.first)
    }

    var weeklyProofMetrics: [ProofMetric] {
        let source = weeklyRecaps

        let protectedValue: String
        let protectedDetail: String
        let answered = source.compactMap(\.protectedIntention)
        if answered.isEmpty {
            protectedValue = "-"
            protectedDetail = "Answer recaps to measure follow-through."
        } else {
            let protectedCount = answered.filter { $0 }.count
            protectedValue = "\(Int((Double(protectedCount) / Double(answered.count) * 100).rounded()))%"
            protectedDetail = "\(protectedCount) of \(answered.count) marked protected."
        }

        let cleanMode = cleanestMode(in: source)
        let modeValue = cleanMode?.mode.title ?? "-"
        let modeDetail = cleanMode.map { "\($0.cleanCount) clean session\($0.cleanCount == 1 ? "" : "s")." } ?? "Complete clean sessions to reveal this."

        let distraction = topDistraction(in: source)
        let distractionValue = distraction?.name ?? "None"
        let distractionDetail = distraction.map { "\($0.count) check-in\($0.count == 1 ? "" : "s") this week." } ?? "No tracked interruptions this week."

        return [
            ProofMetric(id: "protected", title: "Protected", value: protectedValue, detail: protectedDetail),
            ProofMetric(id: "best-mode", title: "Best mode", value: modeValue, detail: modeDetail),
            ProofMetric(id: "main-pull", title: "Main pull", value: distractionValue, detail: distractionDetail)
        ]
    }

    var revisitQueue: [SessionRecap] {
        recaps
            .filter { diagnosis(for: $0) != .clean }
            .prefix(3)
            .map { $0 }
    }

    var dailyStory: String {
        guard !todaysRecaps.isEmpty else {
            return "Protect one outcome to start today's proof."
        }

        let minutes = TimeFormatting.minutes(todaysFocusedSeconds)
        let cleanCount = todaysRecaps.filter { $0.totalDistractions == 0 }.count
        if cleanCount > 0 {
            return "\(minutes) protected today, \(cleanCount) clean session\(cleanCount == 1 ? "" : "s")."
        }

        let distractionTotal = todaysRecaps.reduce(0) { $0 + $1.totalDistractions }
        return "\(minutes) protected today with \(distractionTotal) gentle check-in\(distractionTotal == 1 ? "" : "s")."
    }

    func recapInsight(for recap: SessionRecap) -> String {
        suggestion(from: recap).detail
    }

    func ritualSuggestion(for recap: SessionRecap) -> RitualSuggestion {
        suggestion(from: recap)
    }

    func diagnosis(for recap: SessionRecap) -> RecapDiagnosis {
        if recap.protectedIntention == false {
            return .revisit
        }

        if recap.totalDistractions > 0 {
            return .interrupted
        }

        return .clean
    }

    private func suggestion(from recap: SessionRecap?) -> RitualSuggestion {
        guard let recap else {
            return RitualSuggestion(
                title: "Start one protected outcome",
                detail: "Choose one line, idea, draft, or decision worth protecting.",
                systemImage: "sparkles",
                intention: nil
            )
        }

        if recap.protectedIntention == false {
            return RitualSuggestion(
                title: "Continue this intention",
                detail: "\(recap.intention) deserves another pass before it fades.",
                systemImage: "arrow.forward.circle",
                intention: recap.intention
            )
        }

        if let appName = recap.topDistractionName {
            let count = recap.distractionCounts[appName, default: 0]
            return RitualSuggestion(
                title: "Protect the same work tighter",
                detail: "\(appName) pulled attention \(count) time\(count == 1 ? "" : "s"). Start the next ritual with that boundary visible.",
                systemImage: "shield.lefthalf.filled",
                intention: recap.intention
            )
        }

        if recap.totalDistractions == 0 {
            return RitualSuggestion(
                title: "Repeat this clean pattern",
                detail: "Clean session. \(recap.creatorMode.title) is working for this kind of output.",
                systemImage: "checkmark.seal",
                intention: recap.intention
            )
        }

        return RitualSuggestion(
            title: "Close the same loop",
            detail: "\(recap.totalDistractions) check-in\(recap.totalDistractions == 1 ? "" : "s") showed where the next ritual needs protection.",
            systemImage: "arrow.triangle.2.circlepath",
            intention: recap.intention
        )
    }

    private func topDistraction(in recaps: [SessionRecap]) -> (name: String, count: Int)? {
        recaps
            .flatMap { $0.distractionCounts }
            .reduce(into: [String: Int]()) { totals, item in
                totals[item.key, default: 0] += item.value
            }
            .max { lhs, rhs in lhs.value < rhs.value }
            .map { (name: $0.key, count: $0.value) }
    }

    private func cleanestMode(in recaps: [SessionRecap]) -> (mode: CreatorMode, cleanCount: Int)? {
        let grouped = Dictionary(grouping: recaps.filter { $0.totalDistractions == 0 }) { $0.creatorMode }

        return grouped
            .map { (mode: $0.key, cleanCount: $0.value.count) }
            .max { lhs, rhs in lhs.cleanCount < rhs.cleanCount }
    }

    func selectDuration(_ minutes: Int) {
        isCustomDurationSelected = false
        selectedDurationMinutes = minutes
        preferences.defaultDurationMinutes = minutes
        remainingSeconds = minutes * 60
        persistPreferences()
    }

    func selectCustomDuration() {
        isCustomDurationSelected = true
        selectedDurationMinutes = customDurationMinutes
        preferences.defaultDurationMinutes = customDurationMinutes
        remainingSeconds = customDurationMinutes * 60
        persistPreferences()
    }

    func updateCustomDuration(_ minutes: Int) {
        customDurationMinutes = min(max(minutes, 5), 180)
        preferences.customDurationMinutes = customDurationMinutes
        if isCustomDurationSelected {
            selectedDurationMinutes = customDurationMinutes
            preferences.defaultDurationMinutes = customDurationMinutes
            remainingSeconds = customDurationMinutes * 60
        }
        persistPreferences()
    }

    func selectCreatorMode(_ mode: CreatorMode) {
        selectedCreatorMode = mode
        preferences.defaultCreatorMode = mode
        persistPreferences()
    }

    func startSession() {
        guard canStart else {
            return
        }

        let cleanIntention = intention.trimmingCharacters(in: .whitespacesAndNewlines)
        let session = FocusSession(
            intention: cleanIntention,
            creatorMode: selectedCreatorMode,
            plannedDuration: selectedDuration
        )
        activeSession = session
        remainingSeconds = Int(selectedDuration)
        settleRemainingSeconds = 5
        reflectionText = ""
        lastDistractionNotificationAt = nil
        lastDistractionNotificationApp = nil
        lastTrackedDistractionApp = nil
        currentSessionDistractionCounts = [:]
        areDistractionRemindersMutedForSession = false
        phase = .settling
        persistActiveSessionRecord()
        if preferences.soundEnabled { soundService.playSessionStart() }
        focusModeCoordinator.openFocusSettingsIfRequested(preferences.openFocusSettingsOnStart)
        if preferences.completionNotificationsEnabled || preferences.distractionNotificationsEnabled {
            Task {
                _ = await notificationService.requestAuthorizationIfNeeded()
            }
        }
        startTimer()
    }

    func skipSettling() {
        guard phase == .settling else {
            return
        }

        beginCountdown()
    }

    func pauseSession() {
        guard var session = activeSession, phase == .running else {
            return
        }

        session.state = .paused
        activeSession = session
        phase = .paused
        if preferences.soundEnabled { soundService.playPause() }
        stopTimer()
        persistActiveSessionRecord()
    }

    func resumeSession() {
        guard var session = activeSession, phase == .paused else {
            return
        }

        session.state = .active
        activeSession = session
        phase = .running
        if preferences.soundEnabled { soundService.playResume() }
        startTimer()
        persistActiveSessionRecord()
    }

    func extendSession(byMinutes minutes: Int) {
        guard (phase == .running || phase == .paused), var session = activeSession else { return }
        let additionalSeconds = minutes * 60
        remainingSeconds += additionalSeconds
        session.plannedDuration += TimeInterval(additionalSeconds)
        activeSession = session
        persistActiveSessionRecord()
    }

    func endSession() {
        if phase == .settling {
            stopTimer()
            resetToIdle()
            return
        }

        if phase == .breakTime {
            stopTimer()
            resetToIdle()
            return
        }

        finishSession(completedNaturally: false)
    }

    func resetToIdle() {
        activeSession = nil
        intention = ""
        reflectionText = ""
        areDistractionRemindersMutedForSession = false
        currentSessionDistractionCounts = [:]
        lastTrackedDistractionApp = nil
        distractionOverlay.dismiss()
        lastOverlayShownAt = nil
        lastOverlayApp = nil
        completedPomodoroCount = 0
        phase = .idle
        settleRemainingSeconds = 5
        remainingSeconds = currentDurationMinutes * 60
        store.clearActiveSessionRecord()
    }

    func saveReflection(for recap: SessionRecap) {
        let cleanReflection = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = recaps.firstIndex(where: { $0.id == recap.id }) else {
            return
        }

        recaps[index].reflection = cleanReflection.isEmpty ? nil : cleanReflection
        store.saveRecaps(recaps)
        phase = .completed(recaps[index])
    }

    func saveReflectionAndClose(for recap: SessionRecap) {
        saveReflection(for: recap)
        resetToIdle()
    }

    func setProtectedIntention(_ protected: Bool, for recap: SessionRecap) {
        guard let index = recaps.firstIndex(where: { $0.id == recap.id }) else {
            return
        }

        recaps[index].protectedIntention = protected
        store.saveRecaps(recaps)
        phase = .completed(recaps[index])
    }

    func addDistractionApp(named name: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            return
        }

        let exists = preferences.distractionAppNames.contains {
            $0.caseInsensitiveCompare(cleanName) == .orderedSame
        }

        guard !exists else {
            return
        }

        preferences.distractionAppNames.append(cleanName)
        preferences.distractionAppNames.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        persistPreferences()
    }

    func removeDistractionApps(at offsets: IndexSet) {
        preferences.distractionAppNames.remove(atOffsets: offsets)
        persistPreferences()
    }

    func addDistractionApp(_ app: RunningAppInfo) {
        addDistractionApp(named: app.bundleIdentifier ?? app.name)
    }

    func refreshRunningApps() {
        runningApps = runningAppsProvider.runningApps()
    }

    func setLaunchAtLoginEnabled(_ isEnabled: Bool) {
        launchAtLoginErrorMessage = nil

        do {
            try launchAtLoginService.setEnabled(isEnabled)
            preferences.launchAtLoginEnabled = launchAtLoginService.isEnabled
            persistPreferences()
        } catch {
            preferences.launchAtLoginEnabled = launchAtLoginService.isEnabled
            launchAtLoginErrorMessage = "Launch at Login could not be updated from this build. Try again after moving Orilo to Applications."
            persistPreferences()
        }
    }

    func refreshNotificationAuthorizationStatus() async {
        notificationAuthorizationStatus = await notificationService.authorizationStatus()
    }

    func requestNotificationAuthorization() async {
        _ = await notificationService.requestAuthorizationIfNeeded()
        await refreshNotificationAuthorizationStatus()
    }

    func refreshAccessibilityTrust() {
        accessibilityTrusted = AXIsProcessTrusted()
    }

    /// Prompts for Accessibility access (used to read browser tab titles for
    /// web-based distractions). macOS shows a dialog directing to System Settings.
    func requestAccessibilityPermission() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        accessibilityTrusted = AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    func playSoundPreview() {
        guard preferences.soundEnabled else {
            return
        }

        soundService.playSessionComplete()
    }

    func muteDistractionRemindersForCurrentSession() {
        guard isActive else {
            return
        }

        areDistractionRemindersMutedForSession = true
        persistActiveSessionRecord()
    }

    func unmuteDistractionRemindersForCurrentSession() {
        areDistractionRemindersMutedForSession = false
        persistActiveSessionRecord()
    }

    func persistPreferences() {
        preferences.customDurationMinutes = customDurationMinutes
        store.savePreferences(preferences)
    }

    func persistCurrentSessionState() {
        persistActiveSessionRecord()
    }

    private func restoreActiveSessionIfNeeded() {
        guard let record = store.loadActiveSessionRecord() else {
            return
        }

        activeSession = record.session
        selectedCreatorMode = record.session.creatorMode
        selectedDurationMinutes = Int(record.session.plannedDuration / 60)
        remainingSeconds = max(record.remainingSeconds, 0)
        settleRemainingSeconds = max(record.settleRemainingSeconds, 0)
        breakRemainingSeconds = max(record.breakRemainingSeconds, 0)
        currentSessionDistractionCounts = record.distractionCounts
        areDistractionRemindersMutedForSession = record.remindersMuted
        completedPomodoroCount = record.completedPomodoroCount
        reflectionText = ""

        let elapsed = max(0, Int(Date().timeIntervalSince(record.savedAt)))

        switch record.phase {
        case .settling:
            if elapsed < record.settleRemainingSeconds {
                settleRemainingSeconds = record.settleRemainingSeconds - elapsed
                phase = .settling
                startTimer()
            } else {
                let countdownElapsed = elapsed - record.settleRemainingSeconds
                remainingSeconds = max(record.remainingSeconds - countdownElapsed, 0)
                phase = .running
                if remainingSeconds <= 0 {
                    finishSession(completedNaturally: true)
                } else {
                    startTimer()
                    persistActiveSessionRecord()
                }
            }
        case .running:
            remainingSeconds = max(record.remainingSeconds - elapsed, 0)
            phase = .running
            if remainingSeconds <= 0 {
                finishSession(completedNaturally: true)
            } else {
                startTimer()
                persistActiveSessionRecord()
            }
        case .paused:
            phase = .paused
            if var session = activeSession {
                session.state = .paused
                activeSession = session
            }
            persistActiveSessionRecord()
        case .breakTime:
            breakRemainingSeconds = max(record.breakRemainingSeconds - elapsed, 0)
            phase = .breakTime
            if breakRemainingSeconds <= 0 {
                store.clearActiveSessionRecord()
                startNextPomodoroOrIdle()
            } else {
                startTimer()
                persistActiveSessionRecord()
            }
        }
    }

    private func persistActiveSessionRecord() {
        guard let activeSession else {
            store.clearActiveSessionRecord()
            return
        }

        let recordPhase: ActiveSessionRecord.Phase
        switch phase {
        case .settling:
            recordPhase = .settling
        case .running:
            recordPhase = .running
        case .paused:
            recordPhase = .paused
        case .breakTime:
            recordPhase = .breakTime
        case .idle, .completed:
            store.clearActiveSessionRecord()
            return
        }

        store.saveActiveSessionRecord(
            ActiveSessionRecord(
                phase: recordPhase,
                session: activeSession,
                remainingSeconds: remainingSeconds,
                settleRemainingSeconds: settleRemainingSeconds,
                breakRemainingSeconds: breakRemainingSeconds,
                distractionCounts: currentSessionDistractionCounts,
                remindersMuted: areDistractionRemindersMutedForSession,
                completedPomodoroCount: completedPomodoroCount,
                savedAt: Date()
            )
        )
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        if phase == .settling {
            if settleRemainingSeconds > 0 {
                settleRemainingSeconds -= 1
                persistActiveSessionRecord()
            }

            if settleRemainingSeconds <= 0 {
                beginCountdown()
            }

            return
        }

        if phase == .breakTime {
            if breakRemainingSeconds > 0 {
                breakRemainingSeconds -= 1
                persistActiveSessionRecord()
            }
            if breakRemainingSeconds <= 0 {
                if preferences.soundEnabled { soundService.playBreakEnd() }
                startNextPomodoroOrIdle()
            }
            return
        }

        guard phase == .running else {
            return
        }

        trackCurrentDistractionIfNeeded()

        if remainingSeconds > 0 {
            remainingSeconds -= 1
            persistActiveSessionRecord()
        }

        if remainingSeconds <= 0 {
            finishSession(completedNaturally: true)
            return
        }

        // When the Focus shield is on it handles distractions with a full-screen
        // nudge, so skip the notification to avoid double-nagging for the same
        // distraction. The notification is only the fallback when the shield is off.
        if preferences.distractionOverlayEnabled {
            maybePresentDistractionOverlay()
        } else {
            maybeSendDistractionReminder()
        }
    }

    private func maybePresentDistractionOverlay() {
        // Take the shield down only when the feature is off, muted, or the
        // session is no longer running. We must NOT dismiss based on the
        // frontmost app, because presenting the overlay activates our own app
        // (so the distraction is no longer frontmost) — that would close the
        // overlay a second after it appears. It stays until the user acts.
        guard preferences.distractionOverlayEnabled,
              !areDistractionRemindersMutedForSession,
              phase == .running,
              let intention = activeSession?.intention else {
            distractionOverlay.dismiss()
            return
        }

        // Leave an open overlay alone — it's dismissed by the user's buttons.
        guard !distractionOverlay.isVisible else {
            return
        }

        guard let appName = distractionAppName else {
            return
        }

        // Cooldown applies only to the SAME app the user just dismissed, so
        // switching to a different distraction (Discord → Safari) shows the
        // overlay immediately instead of being silenced by a global timer.
        let now = Date()
        if appName == lastOverlayApp,
           let shownAt = lastOverlayShownAt,
           now.timeIntervalSince(shownAt) < 60 {
            return
        }

        lastOverlayShownAt = now
        lastOverlayApp = appName
        let bundleID = frontmostAppMonitor.currentApp?.bundleIdentifier

        distractionOverlay.present(
            appName: appName,
            intention: intention,
            onHide: { [weak self] in
                // Resolve the running app fresh at click time (the frontmost app
                // captured at present-time may be stale), then hide it. Hiding by
                // bundle id covers multi-process apps like Chrome more reliably
                // than a single cached NSRunningApplication proxy.
                self?.hideDistractingApp(bundleID: bundleID)
                self?.lastOverlayShownAt = Date()
            },
            onDismiss: { [weak self] in
                self?.lastOverlayShownAt = Date()
            },
            onSnooze: { [weak self] in
                self?.muteDistractionRemindersForCurrentSession()
            }
        )
    }

    private func hideDistractingApp(bundleID: String?) {
        let frontmost = NSWorkspace.shared.frontmostApplication
        let targetApps: [NSRunningApplication] = {
            if let bundleID {
                let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
                if !apps.isEmpty { return apps }
            }
            return frontmost.map { [$0] } ?? []
        }()

        guard let pid = targetApps.first?.processIdentifier else { return }

        // A full-screen app sits on its own Space and ignores hide(). Exit full
        // screen first, then hide after the exit animation settles.
        if FrontmostAppMonitor.exitFullScreenIfNeeded(pid: pid) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                targetApps.forEach { $0.hide() }
            }
        } else {
            targetApps.forEach { $0.hide() }
        }
    }

    private func maybeSendDistractionReminder() {
        guard preferences.distractionNotificationsEnabled,
              !areDistractionRemindersMutedForSession,
              let appName = distractionAppName,
              let intention = activeSession?.intention else {
            return
        }

        let now = Date()
        let cooldownHasPassed = lastDistractionNotificationAt.map { now.timeIntervalSince($0) >= 300 } ?? true
        let appChanged = lastDistractionNotificationApp != appName

        guard cooldownHasPassed || appChanged else {
            return
        }

        lastDistractionNotificationAt = now
        lastDistractionNotificationApp = appName

        Task {
            await notificationService.sendDistractionReminder(appName: appName, intention: intention)
        }
    }

    private func trackCurrentDistractionIfNeeded() {
        guard let appName = distractionAppName else {
            lastTrackedDistractionApp = nil
            return
        }

        guard appName != lastTrackedDistractionApp else {
            return
        }

        currentSessionDistractionCounts[appName, default: 0] += 1
        lastTrackedDistractionApp = appName
        persistActiveSessionRecord()
    }

    private func beginCountdown() {
        guard var session = activeSession else {
            resetToIdle()
            return
        }

        session.state = .active
        activeSession = session
        settleRemainingSeconds = 0
        phase = .running
        startTimer()
        persistActiveSessionRecord()
    }

    private func finishSession(completedNaturally: Bool) {
        guard var session = activeSession else {
            resetToIdle()
            return
        }

        stopTimer()
        let endedAt = Date()
        session.state = .ended
        session.endedAt = endedAt
        activeSession = session
        store.clearActiveSessionRecord()

        let focusedDuration = completedNaturally
            ? session.plannedDuration
            : max(0, session.plannedDuration - TimeInterval(remainingSeconds))

        let recap = SessionRecap(
            sessionID: session.id,
            intention: session.intention,
            creatorMode: session.creatorMode,
            startedAt: session.startedAt,
            endedAt: endedAt,
            plannedDuration: session.plannedDuration,
            focusedDuration: focusedDuration,
            distractionCounts: currentSessionDistractionCounts
        )

        recaps.insert(recap, at: 0)
        store.saveRecaps(recaps)

        // Schedule end-of-day streak protection reminder
        if preferences.completionNotificationsEnabled {
            let streak = currentStreakDays
            if streak > 0 {
                Task {
                    await notificationService.scheduleStreakProtectionReminder(streakDays: streak)
                }
            }
        }

        if preferences.pomodoroEnabled && completedNaturally {
            completedPomodoroCount += 1
            if preferences.soundEnabled { soundService.playSessionComplete() }
            startBreak(playSound: false)
            if preferences.completionNotificationsEnabled {
                Task {
                    await notificationService.sendSessionComplete(
                        intention: session.intention,
                        focusedMinutes: Int(recap.focusedDuration / 60)
                    )
                }
            }
        } else {
            if preferences.soundEnabled { soundService.playSessionComplete() }
            areDistractionRemindersMutedForSession = false
            phase = .completed(recap)
            if completedNaturally, preferences.completionNotificationsEnabled {
                Task {
                    await notificationService.sendSessionComplete(
                        intention: session.intention,
                        focusedMinutes: Int(recap.focusedDuration / 60)
                    )
                }
            }
        }
    }

    private func startBreak(playSound: Bool = true) {
        breakRemainingSeconds = currentBreakDurationSeconds
        phase = .breakTime
        if playSound, preferences.soundEnabled { soundService.playBreakStart() }
        startTimer()
        persistActiveSessionRecord()
    }

    func skipBreak() {
        guard phase == .breakTime else { return }
        stopTimer()
        if preferences.soundEnabled { soundService.playBreakEnd() }
        startNextPomodoroOrIdle()
    }

    private func startNextPomodoroOrIdle() {
        remainingSeconds = currentDurationMinutes * 60
        settleRemainingSeconds = 5
        phase = .settling
        if preferences.soundEnabled { soundService.playSessionStart() }
        startTimer()
    }

    func exportToCSV() -> URL? {
        dataExportService.exportToCSV(recaps)
    }

    func exportToJSON() -> URL? {
        dataExportService.exportToJSON(recaps)
    }

    func deleteRecap(_ recap: SessionRecap) {
        recaps.removeAll { $0.id == recap.id }
        store.saveRecaps(recaps)
    }

    func clearAllHistory() {
        recaps.removeAll()
        store.saveRecaps(recaps)
    }

    func completeOnboarding() {
        preferences.hasCompletedOnboarding = true
        persistPreferences()
    }
}
