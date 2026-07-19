import SwiftUI

enum OriloColors {
    // Sampled straight from the app icon's blue gradient.
    static let gradientStart = Color(red: 4 / 255, green: 64 / 255, blue: 169 / 255)   // #0440A9
    static let gradientMid = Color(red: 31 / 255, green: 102 / 255, blue: 219 / 255)   // #1F66DB
    static let gradientEnd = Color(red: 87 / 255, green: 189 / 255, blue: 254 / 255)   // #57BDFE
    static let focusRing = Color(red: 31 / 255, green: 102 / 255, blue: 219 / 255)     // #1F66DB
    static let breakRing = Color(hue: 0.42, saturation: 0.50, brightness: 0.85)
    static let successGreen = Color(hue: 0.38, saturation: 0.55, brightness: 0.78)
    static let warningOrange = Color(hue: 0.08, saturation: 0.65, brightness: 0.95)
    static let streakFlame = Color(hue: 0.06, saturation: 0.75, brightness: 0.95)
    static let surfaceElevated = Color.secondary.opacity(0.06)
    static let surfaceBorder = Color.secondary.opacity(0.10)
    static let surfaceHover = Color.secondary.opacity(0.12)

    static var primaryGradient: LinearGradient {
        LinearGradient(colors: [gradientStart, gradientMid, gradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var focusGradient: LinearGradient {
        LinearGradient(colors: [gradientStart, gradientMid, gradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var breakGradient: LinearGradient {
        LinearGradient(colors: [breakRing, Color(hue: 0.48, saturation: 0.45, brightness: 0.88)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

enum OriloSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let cardPadding: CGFloat = 16
}

enum OriloRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}

enum OriloAnimation {
    static let spring = Animation.spring(duration: 0.4, bounce: 0.2)
    static let smooth = Animation.smooth(duration: 0.25)
    static let quick = Animation.smooth(duration: 0.15)
    static let slow = Animation.smooth(duration: 0.5)
}
