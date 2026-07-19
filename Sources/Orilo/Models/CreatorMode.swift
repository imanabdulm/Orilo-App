import Foundation

enum CreatorMode: String, Codable, CaseIterable, Identifiable, Equatable {
    case write
    case design
    case code
    case research
    case plan
    case work
    case study
    case read

    var id: String { rawValue }

    var title: String {
        switch self {
        case .write: "Write"
        case .design: "Design"
        case .code: "Code"
        case .research: "Research"
        case .plan: "Plan"
        case .work: "Work"
        case .study: "Study"
        case .read: "Read"
        }
    }

    var systemImage: String {
        switch self {
        case .write: "pencil.and.outline"
        case .design: "sparkles"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .research: "magnifyingglass"
        case .plan: "list.bullet.rectangle"
        case .work: "briefcase"
        case .study: "book.closed"
        case .read: "text.book.closed"
        }
    }

    var ritualPrompt: String {
        switch self {
        case .write: "Name the page you want to move forward."
        case .design: "Choose the decision this pass should clarify."
        case .code: "Pick the smallest useful slice to finish."
        case .research: "Set the question this session should investigate."
        case .plan: "Choose the decision or next step to organize."
        case .work: "Name the outcome this work block should protect."
        case .study: "Set the question this session should answer."
        case .read: "Choose the idea you want to stay with."
        }
    }

    var reflectionPrompt: String {
        switch self {
        case .write: "What line, idea, or draft moved forward?"
        case .design: "What became clearer in the work?"
        case .code: "What shipped, simplified, or unblocked?"
        case .research: "What did you find or rule out?"
        case .plan: "What next step became clearer?"
        case .work: "What outcome moved forward?"
        case .study: "What did you understand better?"
        case .read: "What idea should stay with you?"
        }
    }
}
