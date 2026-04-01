import SwiftUI

enum Theme {
    static let pink = Color(red: 1.0, green: 0.71, blue: 0.76)
    static let pinkLight = Color(red: 1.0, green: 0.82, blue: 0.86)
    static let pinkDark = Color(red: 0.92, green: 0.58, blue: 0.65)
    static let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    static let surface = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let surfaceLight = Color(red: 0.18, green: 0.18, blue: 0.20)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.55)

    static let pinkGradient = LinearGradient(
        colors: [pink, pinkDark],
        startPoint: .top,
        endPoint: .bottom
    )

    static let pinkGlow = Color(red: 1.0, green: 0.71, blue: 0.76).opacity(0.4)
}
