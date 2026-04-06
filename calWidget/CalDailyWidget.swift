import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct CalDailyEntry: TimelineEntry {
    let date: Date
    let data: WidgetNutritionData
}

// MARK: - Timeline Provider

struct CalDailyProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalDailyEntry {
        CalDailyEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalDailyEntry) -> Void) {
        if context.isPreview {
            completion(CalDailyEntry(date: .now, data: .placeholder))
        } else {
            let data = WidgetDataProvider.fetchToday()
            completion(CalDailyEntry(date: .now, data: data))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalDailyEntry>) -> Void) {
        let data = WidgetDataProvider.fetchToday()
        let entry = CalDailyEntry(date: .now, data: data)
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Definition

struct CalDailyWidget: Widget {
    let kind = "CalDailyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalDailyProvider()) { entry in
            CalDailyWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Nutrition")
        .description("Today's calories, macros, and nutrition score.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Views

struct CalDailyWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: CalDailyEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    // MARK: Small Widget
    private var smallView: some View {
        VStack(spacing: 8) {
            HStack {
                Text(entry.data.grade)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(gradeColor)
                Spacer()
                Text("\(entry.data.score)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("/100")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(Int(entry.data.calories))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("kcal")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    macroLabel("P", value: entry.data.protein, color: .blue)
                    macroLabel("C", value: entry.data.carbs, color: .pink)
                    macroLabel("F", value: entry.data.fat, color: .purple)
                }
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: Medium Widget
    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left: Score
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(gradeColor.opacity(0.2), lineWidth: 6)
                        .frame(width: 64, height: 64)

                    Circle()
                        .trim(from: 0, to: Double(entry.data.score) / 100.0)
                        .stroke(gradeColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 64, height: 64)

                    Text(entry.data.grade)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(gradeColor)
                }

                Text("\(entry.data.nutrientsCovered)/\(entry.data.totalNutrients)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            // Right: Details
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(entry.data.calories))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("kcal")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                HStack(spacing: 12) {
                    macroColumn("Protein", value: entry.data.protein, color: .blue)
                    macroColumn("Carbs", value: entry.data.carbs, color: .pink)
                    macroColumn("Fat", value: entry.data.fat, color: .purple)
                }

                Spacer(minLength: 0)

                HStack {
                    Text("\(entry.data.entryCount) meals logged")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("Score: \(entry.data.score)/100")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: Helpers

    private func macroLabel(_ letter: String, value: Double, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(letter)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text("\(Int(value))g")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private func macroColumn(_ label: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Circle().fill(color).frame(width: 5, height: 5)
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Text("\(Int(value))g")
                .font(.system(size: 15, weight: .bold, design: .rounded))
        }
    }

    private var gradeColor: Color {
        switch entry.data.grade {
        case "A+", "A": return .green
        case "B+", "B": return .purple
        case "C+", "C": return .orange
        default: return .red
        }
    }
}
