import Foundation

struct RunningAppInfo: Identifiable, Equatable {
    var id: String {
        bundleIdentifier ?? name
    }

    var name: String
    var bundleIdentifier: String?
}
