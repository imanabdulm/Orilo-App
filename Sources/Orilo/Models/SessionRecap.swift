import Foundation

struct SessionRecap: Codable, Identifiable, Equatable {
    var id: UUID
    var sessionID: UUID
    var intention: String
    var creatorMode: CreatorMode
    var startedAt: Date
    var endedAt: Date
    var plannedDuration: TimeInterval
    var focusedDuration: TimeInterval
    var distractionCounts: [String: Int]
    var reflection: String?
    var protectedIntention: Bool?

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        intention: String,
        creatorMode: CreatorMode = .write,
        startedAt: Date,
        endedAt: Date,
        plannedDuration: TimeInterval,
        focusedDuration: TimeInterval,
        distractionCounts: [String: Int] = [:],
        reflection: String? = nil,
        protectedIntention: Bool? = nil
    ) {
        self.id = id
        self.sessionID = sessionID
        self.intention = intention
        self.creatorMode = creatorMode
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedDuration = plannedDuration
        self.focusedDuration = focusedDuration
        self.distractionCounts = distractionCounts
        self.reflection = reflection
        self.protectedIntention = protectedIntention
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        sessionID = try container.decode(UUID.self, forKey: .sessionID)
        intention = try container.decode(String.self, forKey: .intention)
        creatorMode = try container.decodeIfPresent(CreatorMode.self, forKey: .creatorMode) ?? .write
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        endedAt = try container.decode(Date.self, forKey: .endedAt)
        plannedDuration = try container.decode(TimeInterval.self, forKey: .plannedDuration)
        focusedDuration = try container.decode(TimeInterval.self, forKey: .focusedDuration)
        distractionCounts = try container.decodeIfPresent([String: Int].self, forKey: .distractionCounts) ?? [:]
        reflection = try container.decodeIfPresent(String.self, forKey: .reflection)
        protectedIntention = try container.decodeIfPresent(Bool.self, forKey: .protectedIntention)
    }
}

extension SessionRecap {
    var totalDistractions: Int {
        distractionCounts.values.reduce(0, +)
    }

    var topDistractionName: String? {
        distractionCounts.max { lhs, rhs in lhs.value < rhs.value }?.key
    }
}
