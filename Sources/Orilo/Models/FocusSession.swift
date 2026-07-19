import Foundation

struct FocusSession: Codable, Identifiable, Equatable {
    enum State: String, Codable, Equatable {
        case active
        case paused
        case ended
    }

    var id: UUID
    var intention: String
    var creatorMode: CreatorMode
    var plannedDuration: TimeInterval
    var startedAt: Date
    var endedAt: Date?
    var state: State

    init(
        id: UUID = UUID(),
        intention: String,
        creatorMode: CreatorMode = .write,
        plannedDuration: TimeInterval,
        startedAt: Date = .now,
        endedAt: Date? = nil,
        state: State = .active
    ) {
        self.id = id
        self.intention = intention
        self.creatorMode = creatorMode
        self.plannedDuration = plannedDuration
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.state = state
    }
}
