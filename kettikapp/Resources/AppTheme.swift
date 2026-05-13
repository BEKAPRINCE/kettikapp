import SwiftUI

// MARK: - App Brand Colors
extension Color {
    // Brand
    static let brandBlue    = Color(hex: "#285CCC")

    // Акцентные
    static let accentTeal    = Color(hex: "#285CCC")
    static let accentBlue    = Color(hex: "#285CCC")
    static let accentYellow  = Color(hex: "#F2C14E")
    static let accentOrange  = Color(hex: "#F29D4B")
    static let accentGreen   = Color(hex: "#4DAA7D")
    static let dangerRed     = Color(hex: "#E35D6A")
}

// MARK: - Hex Init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Card Modifier
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cardBorder, lineWidth: 1))
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardModifier()) }
}

// MARK: - Fonts
extension Font {
    static let appTitle    = Font.system(size: 28, weight: .heavy,   design: .rounded)
    static let appHeadline = Font.system(size: 20, weight: .bold,    design: .rounded)
    static let appBody     = Font.system(size: 15, weight: .regular)
    static let appCaption  = Font.system(size: 12, weight: .medium)
    static let appLabel    = Font.system(size: 11, weight: .bold)
}

