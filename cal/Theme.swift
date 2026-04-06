import SwiftUI

// MARK: - Color Palette

enum Cal {
    // Backgrounds
    static let bg = Color(hex: 0x0A0A0A)
    static let bgCard = Color(hex: 0x161616)
    static let bgElevated = Color(hex: 0x1E1E1E)
    static let bgSubtle = Color(hex: 0x252525)

    // Accent: Apple Intelligence spectrum
    static let accent = Color(hex: 0xB07FE0)      // Soft violet as primary
    static let accentSoft = Color(hex: 0xB07FE0).opacity(0.15)

    // Intelligence glow colors
    static let glowPurple = Color(hex: 0xA855F7)
    static let glowBlue = Color(hex: 0x6366F1)
    static let glowCyan = Color(hex: 0x38BDF8)
    static let glowPink = Color(hex: 0xEC4899)
    static let glowOrange = Color(hex: 0xF59E42)
    static let glowWhite = Color(hex: 0xE0D8F0)

    // Semantic Colors
    static let protein = Color(hex: 0x7C9FEC)      // Periwinkle blue
    static let carbs = Color(hex: 0xE089B5)         // Soft rose-pink
    static let fat = Color(hex: 0xB898E8)           // Lilac
    static let fiber = Color(hex: 0x6BBFA3)         // Seafoam

    // Micro categories
    static let vitaminFat = Color(hex: 0xE8C170)
    static let vitaminWater = Color(hex: 0x6BBFA3)
    static let mineral = Color(hex: 0xC4866B)
    static let trace = Color(hex: 0x8B9DC3)

    // Text
    static let textPrimary = Color(hex: 0xF2EDE8)
    static let textSecondary = Color(hex: 0x8A8480)
    static let textTertiary = Color(hex: 0x5A5653)

    // Status
    static let good = Color(hex: 0x7EB88C)
    static let warn = Color(hex: 0xE8A54B)
    static let low = Color(hex: 0xD4714E)

    // Gradients
    static let accentGradient = LinearGradient(
        colors: [Color(hex: 0x6366F1), Color(hex: 0xA855F7), Color(hex: 0xEC4899)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let proteinGradient = LinearGradient(
        colors: [Color(hex: 0x6366F1), Color(hex: 0x38BDF8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let carbsGradient = LinearGradient(
        colors: [Color(hex: 0xEC4899), Color(hex: 0xF59E42)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let fatGradient = LinearGradient(
        colors: [Color(hex: 0xA855F7), Color(hex: 0x6366F1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let bgGradient = LinearGradient(
        colors: [Color(hex: 0x0A0A0A), Color(hex: 0x12100E)],
        startPoint: .top,
        endPoint: .bottom
    )

    // Apple Intelligence multi-color glow gradient (angular)
    static let intelligenceGlow = AngularGradient(
        colors: [
            Color(hex: 0x6366F1),  // Indigo
            Color(hex: 0xA855F7),  // Purple
            Color(hex: 0xEC4899),  // Pink
            Color(hex: 0xF59E42),  // Orange
            Color(hex: 0x38BDF8),  // Cyan
            Color(hex: 0x6366F1),  // Back to indigo
        ],
        center: .center
    )
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Card Modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Cal.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, padding: CGFloat = 20) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Intelligence Glow Border

struct IntelligenceGlowBorder: ViewModifier {
    var cornerRadius: CGFloat = 20
    var lineWidth: CGFloat = 1.5
    var blur: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Cal.intelligenceGlow, lineWidth: lineWidth)
                    .blur(radius: blur)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Cal.intelligenceGlow, lineWidth: lineWidth * 0.5)
            )
    }
}

extension View {
    func intelligenceGlow(cornerRadius: CGFloat = 20, lineWidth: CGFloat = 1.5, blur: CGFloat = 8) -> some View {
        modifier(IntelligenceGlowBorder(cornerRadius: cornerRadius, lineWidth: lineWidth, blur: blur))
    }
}

// MARK: - Typography Helpers

extension Font {
    static func displayLarge() -> Font {
        .system(size: 56, weight: .black, design: .rounded)
    }

    static func displayMedium() -> Font {
        .system(size: 36, weight: .bold, design: .rounded)
    }

    static func displaySmall() -> Font {
        .system(size: 24, weight: .bold, design: .rounded)
    }

    static func mono(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    static func label() -> Font {
        .system(size: 11, weight: .semibold, design: .rounded)
    }
}
