import Foundation
import SwiftData

struct WidgetNutritionData {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let score: Int
    let grade: String
    let nutrientsCovered: Int
    let totalNutrients: Int
    let entryCount: Int

    static let placeholder = WidgetNutritionData(
        calories: 1850, protein: 95, carbs: 220, fat: 65,
        score: 72, grade: "B+", nutrientsCovered: 18, totalNutrients: 24, entryCount: 4
    )

    static let empty = WidgetNutritionData(
        calories: 0, protein: 0, carbs: 0, fat: 0,
        score: 0, grade: "—", nutrientsCovered: 0, totalNutrients: 0, entryCount: 0
    )
}

enum WidgetDataProvider {
    @MainActor
    static func fetchToday() -> WidgetNutritionData {
        do {
            let container = SharedModelContainer.container
            let context = container.mainContext

            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: .now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let descriptor = FetchDescriptor<FoodEntry>(
                predicate: #Predicate<FoodEntry> { entry in
                    entry.date >= startOfDay && entry.date < endOfDay
                }
            )

            let entries = try context.fetch(descriptor)
            guard !entries.isEmpty else { return .empty }

            let calories = entries.reduce(0.0) { $0 + $1.calories }
            let protein = entries.reduce(0.0) { $0 + $1.protein }
            let carbs = entries.reduce(0.0) { $0 + $1.totalCarbohydrates }
            let fat = entries.reduce(0.0) { $0 + $1.totalFat }

            let dailyScore = DailyScore.score(entries: entries)

            return WidgetNutritionData(
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                score: dailyScore.overallScore,
                grade: dailyScore.grade,
                nutrientsCovered: dailyScore.nutrientsCovered,
                totalNutrients: dailyScore.totalNutrients,
                entryCount: entries.count
            )
        } catch {
            return .empty
        }
    }
}
