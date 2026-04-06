import WidgetKit
import SwiftUI

// MARK: - Lock Screen Widget

struct CalLockScreenWidget: Widget {
    let kind = "CalLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalDailyProvider()) { entry in
            CalLockScreenView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Cal Quick View")
        .description("Calories and nutrition grade at a glance.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct CalLockScreenView: View {
    @Environment(\.widgetFamily) var family
    let entry: CalDailyEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }

    // MARK: - Circular: Grade in a ring
    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()

            Gauge(value: Double(entry.data.score), in: 0...100) {
                Text(entry.data.grade)
                    .font(.system(size: 16, weight: .black, design: .rounded))
            }
            .gaugeStyle(.accessoryCircularCapacity)
        }
    }

    // MARK: - Rectangular: Calories + Grade + Macros
    private var rectangularView: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.data.grade)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                    Text("\(Int(entry.data.calories)) kcal")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }

                HStack(spacing: 8) {
                    Text("P:\(Int(entry.data.protein))g")
                    Text("C:\(Int(entry.data.carbs))g")
                    Text("F:\(Int(entry.data.fat))g")
                }
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)

                Gauge(value: Double(entry.data.score), in: 0...100) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryLinearCapacity)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Inline: Simple text
    private var inlineView: some View {
        Text("\(entry.data.grade) · \(Int(entry.data.calories)) kcal · \(entry.data.score)/100")
    }
}
