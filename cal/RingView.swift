import SwiftUI

struct RingView: View {
    let progress: Double
    let gradient: LinearGradient
    let lineWidth: CGFloat
    let size: CGFloat
    var glowColor: Color = .clear

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: glowColor.opacity(0.4), radius: lineWidth * 1.5, x: 0, y: 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: clampedProgress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Large Calorie Ring

struct CalorieRingView: View {
    let consumed: Double
    let goal: Double
    @State private var appeared = false

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return consumed / goal
    }

    private var remaining: Int {
        Int(max(goal - consumed, 0))
    }

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Cal.accent.opacity(0.08), .clear],
                        center: .center,
                        startRadius: 60,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)

            RingView(
                progress: appeared ? progress : 0,
                gradient: Cal.accentGradient,
                lineWidth: 14,
                size: 180,
                glowColor: Cal.accent
            )

            VStack(spacing: 2) {
                Text("\(Int(consumed))")
                    .font(.displayLarge())
                    .foregroundStyle(Cal.textPrimary)

                Text("of \(Int(goal)) kcal")
                    .font(.label())
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .foregroundStyle(Cal.textSecondary)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - Macro Ring

struct MacroRingView: View {
    let label: String
    let value: Double
    let goal: Double
    let unit: String
    let gradient: LinearGradient
    let glowColor: Color
    let size: CGFloat
    @State private var appeared = false

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return value / goal
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RingView(
                    progress: appeared ? progress : 0,
                    gradient: gradient,
                    lineWidth: size * 0.1,
                    size: size,
                    glowColor: glowColor
                )
                VStack(spacing: 0) {
                    Text("\(Int(value))")
                        .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                        .foregroundStyle(Cal.textPrimary)
                    Text(unit)
                        .font(.system(size: size * 0.13, weight: .medium, design: .monospaced))
                        .foregroundStyle(Cal.textTertiary)
                }
            }
            Text(label.uppercased())
                .font(.label())
                .tracking(1.2)
                .foregroundStyle(Cal.textSecondary)
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.3)) {
                appeared = true
            }
        }
    }
}

// MARK: - Micro Progress Bar

struct MicroProgressRow: View {
    let nutrient: NutrientInfo
    let value: Double
    let accentColor: Color
    @State private var appeared = false

    private var progress: Double {
        NutrientDatabase.percentDV(value, nutrient: nutrient)
    }

    private var displayValue: String {
        if value < 1 && value > 0 {
            return String(format: "%.1f", value)
        }
        return "\(Int(value))"
    }

    private var percentText: String {
        "\(Int(min(progress * 100, 999)))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(nutrient.shortName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Cal.textPrimary)

                Spacer()

                Text("\(displayValue)\(nutrient.unit)")
                    .font(.mono(12))
                    .foregroundStyle(Cal.textTertiary)

                Text(percentText)
                    .font(.mono(12))
                    .foregroundStyle(statusColor)
                    .frame(width: 40, alignment: .trailing)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 4)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.7), accentColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: appeared ? min(geo.size.width * min(progress, 1.0), geo.size.width) : 0,
                            height: 4
                        )
                        .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 0)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 3)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }

    private var statusColor: Color {
        if progress >= 1.0 { return Cal.good }
        if progress >= 0.5 { return Cal.textSecondary }
        if progress >= 0.25 { return Cal.warn }
        return Cal.low
    }
}
