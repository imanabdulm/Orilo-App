import Foundation

enum TimeFormatting {
    static func clock(_ seconds: Int) -> String {
        let safeSeconds = max(0, seconds)
        let minutes = safeSeconds / 60
        let remainder = safeSeconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }

    static func minutes(_ seconds: Int) -> String {
        let minutes = max(0, seconds) / 60
        return "\(minutes)m"
    }

    static func compactDate(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}
