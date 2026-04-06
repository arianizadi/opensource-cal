import Foundation

struct FoodScore {
    let entry: FoodEntry
    let overallScore: Int          // 0-100
    let macroBalance: Int          // 0-100
    let microDensity: Int          // 0-100
    let grade: String              // A+, A, B+, B, C+, C, D, F

    static func score(_ entry: FoodEntry) -> FoodScore {
        let macro = macroBalanceScore(entry)
        let micro = microDensityScore(entry)
        let overall = Int(Double(macro) * 0.4 + Double(micro) * 0.6)
        let grade = gradeFor(overall)
        return FoodScore(entry: entry, overallScore: overall, macroBalance: macro, microDensity: micro, grade: grade)
    }

    // MARK: - Macro Balance (40% of score)
    // Rewards: good protein ratio, moderate fat, fiber, low added sugar
    private static func macroBalanceScore(_ e: FoodEntry) -> Int {
        guard e.calories > 0 else { return 0 }
        var score = 50.0 // Start at neutral

        let cal = e.calories

        // Protein density: aim for 15-30% of calories from protein
        let proteinCal = e.protein * 4
        let proteinRatio = proteinCal / cal
        if proteinRatio >= 0.15 && proteinRatio <= 0.35 { score += 15 }
        else if proteinRatio >= 0.10 { score += 8 }
        else if proteinRatio < 0.05 { score -= 10 }

        // Fiber bonus: aim for 3g+ per 200 cal
        let fiberPer200 = (e.dietaryFiber / cal) * 200
        if fiberPer200 >= 5 { score += 15 }
        else if fiberPer200 >= 3 { score += 10 }
        else if fiberPer200 >= 1 { score += 5 }

        // Saturated fat penalty: >30% of fat from sat fat
        if e.totalFat > 0 {
            let satRatio = e.saturatedFat / e.totalFat
            if satRatio > 0.5 { score -= 15 }
            else if satRatio > 0.33 { score -= 8 }
        }

        // Trans fat penalty
        if e.transFat > 0.5 { score -= 15 }
        else if e.transFat > 0 { score -= 5 }

        // Added sugars penalty: >25% of calories from added sugar
        let sugarCal = e.addedSugars * 4
        let sugarRatio = sugarCal / cal
        if sugarRatio > 0.25 { score -= 20 }
        else if sugarRatio > 0.10 { score -= 10 }
        else if sugarRatio < 0.05 { score += 5 }

        // Sodium density: >400mg per 200 cal is high
        let sodiumPer200 = (e.sodium / cal) * 200
        if sodiumPer200 > 500 { score -= 10 }
        else if sodiumPer200 > 300 { score -= 5 }

        return max(0, min(100, Int(score)))
    }

    // MARK: - Micro Density (60% of score)
    // How many micronutrient DVs does this food meaningfully contribute to?
    private static func microDensityScore(_ e: FoodEntry) -> Int {
        guard e.calories > 0 else { return 0 }

        // Calculate how much %DV this food provides per 200 calories
        let scale = 200.0 / e.calories

        let contributions: [(value: Double, dv: Double)] = [
            (e.vitaminA * scale, 900),
            (e.vitaminC * scale, 90),
            (e.vitaminD * scale, 20),
            (e.vitaminE * scale, 15),
            (e.vitaminK * scale, 120),
            (e.thiamine * scale, 1.2),
            (e.riboflavin * scale, 1.3),
            (e.niacin * scale, 16),
            (e.vitaminB6 * scale, 1.7),
            (e.folate * scale, 400),
            (e.vitaminB12 * scale, 2.4),
            (e.calcium * scale, 1300),
            (e.iron * scale, 18),
            (e.magnesium * scale, 420),
            (e.phosphorus * scale, 1250),
            (e.potassium * scale, 4700),
            (e.zinc * scale, 11),
            (e.copper * scale, 0.9),
            (e.manganese * scale, 2.3),
            (e.selenium * scale, 55),
        ]

        var totalDVPercent = 0.0
        var nutrientsAbove5 = 0

        for c in contributions {
            guard c.dv > 0 else { continue }
            let pct = c.value / c.dv
            totalDVPercent += min(pct, 1.0) // Cap at 100% per nutrient
            if pct >= 0.05 { nutrientsAbove5 += 1 }
        }

        // Score: combination of total DV coverage and breadth
        let coverageScore = min(totalDVPercent / 3.0, 1.0) * 60  // Up to 60 pts for total coverage
        let breadthScore = min(Double(nutrientsAbove5) / 10.0, 1.0) * 40  // Up to 40 pts for breadth

        return max(0, min(100, Int(coverageScore + breadthScore)))
    }

    private static func gradeFor(_ score: Int) -> String {
        switch score {
        case 90...100: return "A+"
        case 80..<90: return "A"
        case 70..<80: return "B+"
        case 60..<70: return "B"
        case 50..<60: return "C+"
        case 40..<50: return "C"
        case 25..<40: return "D"
        default: return "F"
        }
    }
}

// MARK: - Analytics Computations

struct DailyNutrientSummary: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let entryCount: Int
}

struct NutrientGap: Identifiable {
    let id = UUID()
    let nutrient: NutrientInfo
    let averagePercent: Double // Average %DV over period
}

struct AnalyticsEngine {
    static func dailySummaries(from entries: [FoodEntry], days: Int = 7) -> [DailyNutrientSummary] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            return DailyNutrientSummary(
                date: date,
                calories: dayEntries.reduce(0) { $0 + $1.calories },
                protein: dayEntries.reduce(0) { $0 + $1.protein },
                carbs: dayEntries.reduce(0) { $0 + $1.totalCarbohydrates },
                fat: dayEntries.reduce(0) { $0 + $1.totalFat },
                entryCount: dayEntries.count
            )
        }.reversed()
    }

    static func nutrientGaps(from entries: [FoodEntry], days: Int = 7) -> [NutrientGap] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let daysWithData = (0..<days).filter { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return false }
            return entries.contains { calendar.isDate($0.date, inSameDayAs: date) }
        }.count
        guard daysWithData > 0 else { return [] }

        let allMicros = NutrientDatabase.fatSolubleVitamins
            + NutrientDatabase.waterSolubleVitamins
            + NutrientDatabase.macrominerals
            + NutrientDatabase.traceMinerals

        let recentEntries = entries.filter { entry in
            guard let cutoff = calendar.date(byAdding: .day, value: -days, to: today) else { return false }
            return entry.date >= cutoff
        }

        return allMicros.map { nutrient in
            let total = NutrientDatabase.totalForEntries(recentEntries, nutrient: nutrient)
            let avgDaily = total / Double(daysWithData)
            let percentDV = NutrientDatabase.percentDV(avgDaily, nutrient: nutrient)
            return NutrientGap(nutrient: nutrient, averagePercent: percentDV)
        }.sorted { $0.averagePercent < $1.averagePercent }
    }

    static func scoredFoods(from entries: [FoodEntry]) -> [FoodScore] {
        entries
            .filter { $0.calories > 0 }
            .map { FoodScore.score($0) }
            .sorted { $0.overallScore > $1.overallScore }
    }
}
