import WidgetKit
import SwiftUI

// MARK: - Watch Complication Entry

struct WatchComplicationEntry: TimelineEntry {
    let date: Date
    let data: WidgetNutritionData
}

// MARK: - Watch Complication Provider

struct WatchComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchComplicationEntry {
        WatchComplicationEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchComplicationEntry) -> Void) {
        if context.isPreview {
            completion(WatchComplicationEntry(date: .now, data: .placeholder))
        } else {
            let data = WidgetDataProvider.fetchToday()
            completion(WatchComplicationEntry(date: .now, data: data))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchComplicationEntry>) -> Void) {
        let data = WidgetDataProvider.fetchToday()
        let entry = WatchComplicationEntry(date: .now, data: data)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Complications Widget Bundle

struct CalWatchComplicationsBundle: WidgetBundle {
    var body: some Widget {
        CalWatchCircularComplication()
        CalWatchRectangularComplication()
        CalWatchCornerComplication()
        CalWatchInlineComplication()
    }
}

// MARK: - Circular Complication (Grade in ring)

struct CalWatchCircularComplication: Widget {
    let kind = "CalWatchCircular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            ZStack {
                AccessoryWidgetBackground()
                Gauge(value: Double(entry.data.score), in: 0...100) {
                    Text(entry.data.grade)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                }
                .gaugeStyle(.accessoryCircularCapacity)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Score")
        .description("Daily nutrition grade.")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Rectangular Complication (Calories + Macros)

struct CalWatchRectangularComplication: Widget {
    let kind = "CalWatchRectangular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.data.grade)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                    Text("\(Int(entry.data.calories)) kcal")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }

                HStack(spacing: 6) {
                    Text("P:\(Int(entry.data.protein))g")
                    Text("C:\(Int(entry.data.carbs))g")
                    Text("F:\(Int(entry.data.fat))g")
                }
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)

                Gauge(value: Double(entry.data.score), in: 0...100) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryLinearCapacity)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Summary")
        .description("Calories, macros, and score.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Corner Complication (Calorie count)

struct CalWatchCornerComplication: Widget {
    let kind = "CalWatchCorner"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text("\(Int(entry.data.calories))")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Text("kcal")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Calories")
        .description("Today's calorie count.")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Inline Complication

struct CalWatchInlineComplication: Widget {
    let kind = "CalWatchInline"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            Text("\(entry.data.grade) · \(Int(entry.data.calories)) kcal")
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Cal Inline")
        .description("Grade and calories.")
        .supportedFamilies([.accessoryInline])
    }
}
