import Foundation

struct ActiveSessionRecord: Codable, Equatable {
    enum Phase: String, Codable, Equatable {
        case settling
        case running
        case paused
        case breakTime
    }

    var phase: Phase
    var session: FocusSession
    var remainingSeconds: Int
    var settleRemainingSeconds: Int
    var breakRemainingSeconds: Int
    var distractionCounts: [String: Int]
    var remindersMuted: Bool
    var completedPomodoroCount: Int
    var savedAt: Date
}
