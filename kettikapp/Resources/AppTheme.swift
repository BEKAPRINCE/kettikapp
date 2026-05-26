import SwiftUI
import UIKit

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


// MARK: - Native Liquid Glass
enum LiquidGlassStyle {
    case regular
    case clear
}

private struct NativeLiquidGlassView: UIViewRepresentable {
    let style: LiquidGlassStyle

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }

    func updateUIView(_ view: UIVisualEffectView, context: Context) {
        view.effect = effect
    }

    private var effect: UIVisualEffect {
        if #available(iOS 26.0, *) {
            switch style {
            case .regular:
                return UIGlassEffect(style: .regular)
            case .clear:
                return UIGlassEffect(style: .clear)
            }
        } else {
            return UIBlurEffect(style: .systemUltraThinMaterialDark)
        }
    }
}

struct LiquidGlassBackground: View {
    var cornerRadius: CGFloat = 28
    var style: LiquidGlassStyle = .regular
    var tint: Color = .cardBackground
    var tintOpacity: Double = 0.18
    var strokeOpacity: Double = 0.24
    var shadowOpacity: Double = 0.32

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.clear)
            .background {
                NativeLiquidGlassView(style: style)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint.opacity(tintOpacity))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(strokeOpacity),
                                Color.cardBorder.opacity(0.7),
                                Color.accentTeal.opacity(0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(shadowOpacity), radius: 22, y: 10)
    }
}

extension View {
    func liquidGlassBackground(
        cornerRadius: CGFloat = 28,
        style: LiquidGlassStyle = .regular,
        tint: Color = .cardBackground,
        tintOpacity: Double = 0.18,
        strokeOpacity: Double = 0.24,
        shadowOpacity: Double = 0.32
    ) -> some View {
        background {
            LiquidGlassBackground(
                cornerRadius: cornerRadius,
                style: style,
                tint: tint,
                tintOpacity: tintOpacity,
                strokeOpacity: strokeOpacity,
                shadowOpacity: shadowOpacity
            )
        }
    }
}

// MARK: - Fonts
extension Font {
    static let appTitle    = Font.system(size: 28, weight: .heavy,   design: .rounded)
    static let appHeadline = Font.system(size: 20, weight: .bold,    design: .rounded)
    static let appBody     = Font.system(size: 15, weight: .regular)
    static let appCaption  = Font.system(size: 12, weight: .medium)
    static let appLabel    = Font.system(size: 11, weight: .bold)
}

