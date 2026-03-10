import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    static let zinc100 = Color(hex: "f4f4f5")
    static let zinc200 = Color(hex: "e4e4e7")
    static let zinc300 = Color(hex: "d4d4d8")
    static let zinc500 = Color(hex: "71717a")
    static let zinc600 = Color(hex: "52525b")
    static let zinc800 = Color(hex: "27272a")
    static let zinc900 = Color(hex: "18181b")
    static let lime400 = Color(hex: "a3e635")
    static let lime500 = Color(hex: "84cc16")
    static let red500 = Color(hex: "ef4444")
    static let red950 = Color(hex: "450a0a")
    static let red300 = Color(hex: "fca5a5")
}
