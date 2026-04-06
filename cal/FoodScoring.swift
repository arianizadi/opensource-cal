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
            (e.choline * scale, 550),
            (e.chromium * scale, 35),
            (e.molybdenum * scale, 45),
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

// MARK: - Daily Completeness Score

struct DailyScore {
    let overallScore: Int       // 0-100
    let calorieScore: Int       // 0-100
    let macroScore: Int         // 0-100
    let microScore: Int         // 0-100
    let glycemicScore: Int      // 0-100
    let grade: String           // A+, A, B+, B, C+, C, D, F
    let nutrientsCovered: Int   // How many nutrients hit ≥50% DV
    let totalNutrients: Int     // Total tracked nutrients
    let estimatedGI: Double?    // Weighted-average daily GI
    let dailyGL: Double         // Total daily glycemic load

    /// Requires UserProfile to have body stats for TDEE-based scoring
    static func score(entries: [FoodEntry], profile: UserProfile) -> DailyScore {
        guard !entries.isEmpty else {
            return DailyScore(overallScore: 0, calorieScore: 0, macroScore: 0, microScore: 0, glycemicScore: 50, grade: "F", nutrientsCovered: 0, totalNutrients: 0, estimatedGI: nil, dailyGL: 0)
        }

        let cal = calorieAdequacy(entries, profile: profile)
        let macro = macroBalance(entries, profile: profile)
        let (micro, covered, total) = microCompleteness(entries)
        let glycemic = GlycemicEstimator.glycemicScore(entries: entries)
        let avgGI = GlycemicEstimator.dailyAverageGI(entries: entries)
        let gl = GlycemicEstimator.dailyGL(entries: entries)

        // 20% calorie adequacy, 20% macro balance, 10% glycemic, 50% micro coverage
        let overall = Int(Double(cal) * 0.20 + Double(macro) * 0.20 + Double(glycemic) * 0.10 + Double(micro) * 0.50)
        let grade = gradeFor(overall)

        return DailyScore(
            overallScore: overall,
            calorieScore: cal,
            macroScore: macro,
            microScore: micro,
            glycemicScore: glycemic,
            grade: grade,
            nutrientsCovered: covered,
            totalNutrients: total,
            estimatedGI: avgGI,
            dailyGL: gl
        )
    }

    // MARK: - Calorie Adequacy (20%)
    // Are you eating close to your calorie goal? Penalizes under AND over eating.
    // In tracker mode, no calorie target exists — return neutral score.
    private static func calorieAdequacy(_ entries: [FoodEntry], profile: UserProfile) -> Int {
        guard profile.mode == .limit else { return 75 }

        let consumed = entries.reduce(0.0) { $0 + $1.calories }
        let target = profile.calorieGoal

        guard target > 0, consumed > 0 else { return 0 }

        let ratio = consumed / target
        if ratio >= 0.85 && ratio <= 1.15 { return 100 }
        if ratio >= 0.75 && ratio <= 1.25 { return 80 }
        if ratio >= 0.60 && ratio <= 1.40 { return 55 }
        if ratio >= 0.50 && ratio <= 1.50 { return 35 }
        return 10
    }

    // MARK: - Macro Balance (25%)
    // Based on MD Anderson guidelines:
    // Carbs: 45-65% of cal, Fat: 20-35% of cal (<10% sat), Protein: 0.8g/kg+
    // Fiber: 25-35g, Added sugar: <10% of cal, Sodium: <2300mg
    private static func macroBalance(_ entries: [FoodEntry], profile: UserProfile) -> Int {
        let cal = entries.reduce(0.0) { $0 + $1.calories }
        guard cal > 100 else { return 0 }

        var score = 0.0

        let protein = entries.reduce(0.0) { $0 + $1.protein }
        let carbs = entries.reduce(0.0) { $0 + $1.totalCarbohydrates }
        let fat = entries.reduce(0.0) { $0 + $1.totalFat }
        let satFat = entries.reduce(0.0) { $0 + $1.saturatedFat }
        let fiber = entries.reduce(0.0) { $0 + $1.dietaryFiber }
        let addedSugar = entries.reduce(0.0) { $0 + $1.addedSugars }
        let sodium = entries.reduce(0.0) { $0 + $1.sodium }

        // Carb ratio: 45-65% of calories (MD Anderson)
        let carbPct = (carbs * 4) / cal
        if carbPct >= 0.45 && carbPct <= 0.65 { score += 15 }
        else if carbPct >= 0.35 && carbPct <= 0.70 { score += 8 }

        // Fat ratio: 20-35% of calories (MD Anderson)
        let fatPct = (fat * 9) / cal
        if fatPct >= 0.20 && fatPct <= 0.35 { score += 15 }
        else if fatPct >= 0.15 && fatPct <= 0.40 { score += 8 }

        // Saturated fat: <10% of calories (MD Anderson)
        let satPct = (satFat * 9) / cal
        if satPct < 0.07 { score += 10 }
        else if satPct < 0.10 { score += 7 }
        else if satPct < 0.13 { score += 3 }

        // Protein: minimum 0.8g per kg body weight
        let proteinTarget = profile.weightKg * 0.8
        let proteinRatio = min(protein / proteinTarget, 2.0)
        if proteinRatio >= 1.0 { score += 15 }
        else if proteinRatio >= 0.7 { score += 8 }
        else { score += max(0, proteinRatio * 5) }

        // Fiber: 25-35g (Harvard / MD Anderson)
        if fiber >= 25 { score += 15 }
        else if fiber >= 18 { score += 10 }
        else if fiber >= 10 { score += 5 }

        // Added sugars: <10% of calories
        let sugarPct = (addedSugar * 4) / cal
        if sugarPct < 0.05 { score += 15 }
        else if sugarPct < 0.10 { score += 10 }
        else if sugarPct < 0.15 { score += 5 }

        // Sodium: <2300mg (CDRR)
        if sodium <= 1500 { score += 15 }
        else if sodium <= 2300 { score += 10 }
        else if sodium <= 3000 { score += 4 }

        return max(0, min(100, Int(score)))
    }

    // MARK: - Micro Completeness (50%)
    // What percentage of micronutrient DVs are covered?
    private static func microCompleteness(_ entries: [FoodEntry]) -> (score: Int, covered: Int, total: Int) {
        let allMicros = NutrientDatabase.fatSolubleVitamins
            + NutrientDatabase.waterSolubleVitamins
            + NutrientDatabase.macrominerals
            + NutrientDatabase.traceMinerals
            + NutrientDatabase.others.filter { $0.name == "Choline" }

        var totalDVPercent = 0.0
        var covered = 0

        for nutrient in allMicros {
            let total = NutrientDatabase.totalForEntries(entries, nutrient: nutrient)
            let pct = NutrientDatabase.percentDV(total, nutrient: nutrient)
            totalDVPercent += min(pct, 1.5) // Cap at 150%
            if pct >= 0.5 { covered += 1 }
        }

        let avgCoverage = totalDVPercent / Double(allMicros.count)
        let coverageScore = min(avgCoverage, 1.0) * 60
        let breadthScore = min(Double(covered) / Double(allMicros.count), 1.0) * 40

        let score = max(0, min(100, Int(coverageScore + breadthScore)))
        return (score, covered, allMicros.count)
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

// MARK: - Glycemic Index Estimation
// Based on: Rytz et al. (2019) "Predicting Glycemic Index and Glycemic Load from Macronutrients"
// Nutrients 2019, 11, 1172 — Equation 3c

struct GlycemicEstimator {

    /// Estimate GI for a single food entry from its macronutrient composition.
    /// Returns nil when there are no glycemic carbohydrates.
    static func estimateGI(for entry: FoodEntry) -> Double? {
        let totalCarbs = entry.totalCarbohydrates
        let fiber = entry.dietaryFiber
        let sugars = entry.totalSugars
        let protein = entry.protein
        let fat = entry.totalFat
        let water = entry.water

        // Glycemic carbohydrates = total carbs minus fiber
        let glycemicCarbs = max(totalCarbs - fiber, 0)
        guard glycemicCarbs > 1 else { return nil }

        // Split glycemic carbs into sugars and starch
        let sugarPortion = min(sugars, glycemicCarbs)
        let starchPortion = max(glycemicCarbs - sugarPortion, 0)

        // GI values from Table 2 of the paper
        // Sugars: use sucrose GI (62) as a reasonable average for label-reported sugars
        let sugarGI = 62.0
        // Starch: GI = 110, corrected by RDS fraction (default 0.75 for typical mixed foods)
        let starchGI = 110.0
        let rdsRatio = 0.75

        // Numerator: Σ(xi * ai * GIi) — Equation 3c
        let numerator = sugarPortion * 1.0 * sugarGI + starchPortion * rdsRatio * starchGI

        // Denominator: Σ(glycemic xi) + Σ(non-glycemic xj * bj) — Table 3 coefficients
        // Fiber: approximate average of soluble (0.3) and insoluble (0.1) → 0.15
        let fiberB = 0.15
        let proteinB = 0.6
        let fatB = 0.6
        let waterB = 0.0

        let denominator = glycemicCarbs
            + fiber * fiberB
            + protein * proteinB
            + fat * fatB
            + water * waterB

        guard denominator > 0 else { return nil }

        return min(numerator / denominator, 110)
    }

    /// Glycemic Load for a single entry: GL = GI × glycemic_carbs_per_serving / 100
    static func estimateGL(for entry: FoodEntry) -> Double? {
        guard let gi = estimateGI(for: entry) else { return nil }
        let glycemicCarbs = max(entry.totalCarbohydrates - entry.dietaryFiber, 0)
        return gi * glycemicCarbs / 100.0
    }

    /// Daily weighted-average GI across all entries (weighted by glycemic carbs)
    static func dailyAverageGI(entries: [FoodEntry]) -> Double? {
        var totalWeightedGI = 0.0
        var totalGlycemicCarbs = 0.0

        for entry in entries {
            guard let gi = estimateGI(for: entry) else { continue }
            let glycCarbs = max(entry.totalCarbohydrates - entry.dietaryFiber, 0)
            totalWeightedGI += gi * glycCarbs
            totalGlycemicCarbs += glycCarbs
        }

        guard totalGlycemicCarbs > 0 else { return nil }
        return totalWeightedGI / totalGlycemicCarbs
    }

    /// Total daily glycemic load
    static func dailyGL(entries: [FoodEntry]) -> Double {
        entries.compactMap { estimateGL(for: $0) }.reduce(0, +)
    }

    /// Score 0-100: lower GI is better. Uses WHO/GI Foundation thresholds:
    /// Low GI ≤55, Medium 56-69, High ≥70
    static func glycemicScore(entries: [FoodEntry]) -> Int {
        guard let avgGI = dailyAverageGI(entries: entries) else { return 50 }

        // Score inversely proportional to GI
        // GI ≤ 45 → 100, GI 55 → 80, GI 70 → 50, GI 85 → 20, GI ≥ 95 → 0
        let score: Double
        if avgGI <= 45 {
            score = 100
        } else if avgGI <= 55 {
            // 45-55 → 100-80
            score = 100 - (avgGI - 45) * 2.0
        } else if avgGI <= 70 {
            // 55-70 → 80-50
            score = 80 - (avgGI - 55) * 2.0
        } else if avgGI <= 85 {
            // 70-85 → 50-20
            score = 50 - (avgGI - 70) * 2.0
        } else {
            // 85+ → 20-0
            score = max(20 - (avgGI - 85) * 2.0, 0)
        }

        return max(0, min(100, Int(score)))
    }
}

// MARK: - Score Recommendations

struct ScoreRecommendation: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let impact: Int          // Estimated points recoverable (for sorting)
    let category: ScoreCategory

    enum ScoreCategory: String {
        case calorie = "Calories"
        case macro = "Macros"
        case micro = "Micronutrients"
        case glycemic = "Glycemic"
    }
}

struct ScoreBreakdown {
    let calorieScore: Int
    let macroScore: Int
    let microScore: Int
    let glycemicScore: Int
    let recommendations: [ScoreRecommendation]

    static func analyze(entries: [FoodEntry], profile: UserProfile) -> ScoreBreakdown {
        let score = DailyScore.score(entries: entries, profile: profile)
        var recs: [ScoreRecommendation] = []

        // --- Calorie recommendations (limit mode only) ---
        let consumed = entries.reduce(0.0) { $0 + $1.calories }
        if consumed == 0 {
            recs.append(ScoreRecommendation(
                icon: "exclamationmark.circle",
                title: "No food logged yet",
                detail: "Log your meals to get a meaningful score and personalized recommendations.",
                impact: 50, category: .calorie))
        } else if profile.mode == .limit {
            let target = profile.calorieGoal
            let ratio = consumed / target
            if ratio < 0.60 {
                let deficit = Int(target - consumed)
                recs.append(ScoreRecommendation(
                    icon: "arrow.down.circle",
                    title: "Eating too little",
                    detail: "You've eaten \(Int(consumed)) kcal — about \(deficit) below your \(Int(target)) goal. Undereating slows metabolism and can cause nutrient gaps.",
                    impact: 20, category: .calorie))
            } else if ratio < 0.85 {
                let deficit = Int(target - consumed)
                recs.append(ScoreRecommendation(
                    icon: "fork.knife",
                    title: "Eat a bit more",
                    detail: "You're \(deficit) kcal under target. A snack with protein and fiber would help close the gap.",
                    impact: 12, category: .calorie))
            } else if ratio > 1.40 {
                let surplus = Int(consumed - target)
                recs.append(ScoreRecommendation(
                    icon: "arrow.up.circle",
                    title: "Significantly over target",
                    detail: "You're \(surplus) kcal over your \(Int(target)) goal. Consider lighter options for the rest of the day.",
                    impact: 20, category: .calorie))
            } else if ratio > 1.15 {
                let surplus = Int(consumed - target)
                recs.append(ScoreRecommendation(
                    icon: "scalemass",
                    title: "Slightly over calorie target",
                    detail: "You're \(surplus) kcal above your goal. A light dinner or skipping dessert would balance things out.",
                    impact: 10, category: .calorie))
            }
        }

        // --- Macro recommendations ---
        let cal = consumed
        if cal > 100 {
            let protein = entries.reduce(0.0) { $0 + $1.protein }
            let carbs = entries.reduce(0.0) { $0 + $1.totalCarbohydrates }
            let fat = entries.reduce(0.0) { $0 + $1.totalFat }
            let fiber = entries.reduce(0.0) { $0 + $1.dietaryFiber }
            let addedSugar = entries.reduce(0.0) { $0 + $1.addedSugars }
            let sodium = entries.reduce(0.0) { $0 + $1.sodium }
            let satFat = entries.reduce(0.0) { $0 + $1.saturatedFat }

            let proteinTarget = profile.weightKg * 0.8
            if protein < proteinTarget * 0.7 {
                let need = Int(proteinTarget - protein)
                recs.append(ScoreRecommendation(
                    icon: "flame",
                    title: "Protein is low",
                    detail: "You need ~\(need)g more protein to hit \(Int(proteinTarget))g (0.8g/kg). Try chicken, Greek yogurt, eggs, or legumes.",
                    impact: 15, category: .macro))
            }

            if fiber < 18 {
                recs.append(ScoreRecommendation(
                    icon: "leaf",
                    title: "Get more fiber",
                    detail: "Only \(Int(fiber))g fiber today — aim for 25g+. Need ~\(Int(25 - fiber))g more. Add beans, berries, oats, or vegetables.",
                    impact: 12, category: .macro))
            }

            let sugarPct = (addedSugar * 4) / cal
            if sugarPct > 0.10 {
                recs.append(ScoreRecommendation(
                    icon: "cube",
                    title: "High added sugar",
                    detail: "\(Int(addedSugar))g added sugar is >\(Int(sugarPct * 100))% of calories. Swap sugary drinks or snacks for whole food alternatives.",
                    impact: 12, category: .macro))
            }

            if sodium > 2300 {
                recs.append(ScoreRecommendation(
                    icon: "drop.triangle",
                    title: "Sodium is high",
                    detail: "\(Int(sodium))mg sodium exceeds the 2,300mg limit. Watch for processed foods, sauces, and deli meats.",
                    impact: 10, category: .macro))
            }

            let satPct = (satFat * 9) / cal
            if satPct > 0.10 {
                recs.append(ScoreRecommendation(
                    icon: "heart",
                    title: "Saturated fat is high",
                    detail: "\(Int(satPct * 100))% of calories from sat fat (aim <10%). Swap butter for olive oil, or choose leaner cuts.",
                    impact: 8, category: .macro))
            }

            let carbPct = (carbs * 4) / cal
            if carbPct < 0.35 {
                recs.append(ScoreRecommendation(
                    icon: "bolt",
                    title: "Carbs are very low",
                    detail: "Only \(Int(carbPct * 100))% of calories from carbs. Add whole grains, fruits, or starchy vegetables.",
                    impact: 6, category: .macro))
            } else if carbPct > 0.70 {
                recs.append(ScoreRecommendation(
                    icon: "bolt",
                    title: "Carb-heavy day",
                    detail: "\(Int(carbPct * 100))% of calories from carbs. Balance with more protein and healthy fats.",
                    impact: 6, category: .macro))
            }

            let fatPct = (fat * 9) / cal
            if fatPct < 0.15 {
                recs.append(ScoreRecommendation(
                    icon: "drop",
                    title: "Fat is very low",
                    detail: "Only \(Int(fatPct * 100))% of calories from fat. You need fat for hormone production and vitamin absorption. Add nuts, avocado, or olive oil.",
                    impact: 6, category: .macro))
            }
        }

        // --- Micro recommendations ---
        let allMicros = NutrientDatabase.fatSolubleVitamins
            + NutrientDatabase.waterSolubleVitamins
            + NutrientDatabase.macrominerals
            + NutrientDatabase.traceMinerals
            + NutrientDatabase.others.filter { $0.name == "Choline" }

        var lowNutrients: [(name: String, pct: Int)] = []
        for nutrient in allMicros {
            let total = NutrientDatabase.totalForEntries(entries, nutrient: nutrient)
            let pct = NutrientDatabase.percentDV(total, nutrient: nutrient)
            if pct < 0.25 {
                lowNutrients.append((nutrient.shortName, Int(pct * 100)))
            }
        }

        if !lowNutrients.isEmpty {
            let topMissing = lowNutrients.prefix(5)
            let names = topMissing.map { "\($0.name) (\($0.pct)%)" }.joined(separator: ", ")
            let impact = min(lowNutrients.count * 3, 25)
            recs.append(ScoreRecommendation(
                icon: "chart.bar.xaxis",
                title: "\(lowNutrients.count) nutrients below 25% DV",
                detail: "Lowest: \(names). Eat more colorful vegetables, leafy greens, and varied proteins.",
                impact: impact, category: .micro))
        }

        let coveredCount = allMicros.filter { nutrient in
            let total = NutrientDatabase.totalForEntries(entries, nutrient: nutrient)
            return NutrientDatabase.percentDV(total, nutrient: nutrient) >= 0.50
        }.count

        if coveredCount < allMicros.count / 2 && !entries.isEmpty {
            recs.append(ScoreRecommendation(
                icon: "square.grid.3x3.topleft.filled",
                title: "Low nutrient variety",
                detail: "Only \(coveredCount)/\(allMicros.count) nutrients above 50% DV. Micronutrient coverage is the biggest part of your score (50%). Eat a wider range of whole foods.",
                impact: 20, category: .micro))
        }

        // --- Glycemic recommendations ---
        if let avgGI = GlycemicEstimator.dailyAverageGI(entries: entries) {
            if avgGI > 70 {
                recs.append(ScoreRecommendation(
                    icon: "waveform.path.ecg",
                    title: "High glycemic index",
                    detail: "Average GI of \(Int(avgGI)) is high — spikes blood sugar. Swap white bread/rice for whole grains, add protein or fat to carb-heavy meals.",
                    impact: 10, category: .glycemic))
            } else if avgGI > 55 {
                recs.append(ScoreRecommendation(
                    icon: "waveform.path.ecg",
                    title: "Medium glycemic index",
                    detail: "Average GI of \(Int(avgGI)). Pair carbs with protein/fat/fiber to bring it under 55 for steadier energy.",
                    impact: 5, category: .glycemic))
            }
        }

        recs.sort { $0.impact > $1.impact }

        return ScoreBreakdown(
            calorieScore: score.calorieScore,
            macroScore: score.macroScore,
            microScore: score.microScore,
            glycemicScore: score.glycemicScore,
            recommendations: recs
        )
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

// MARK: - Weight + Deficit Correlation

struct WeeklyCorrelation: Identifiable {
    let id = UUID()
    let weekStart: Date
    let avgDailyCalories: Double
    let avgDailyDeficit: Double    // Positive = deficit, negative = surplus
    let weightStart: Double        // kg
    let weightEnd: Double          // kg
    let weightChange: Double       // kg (negative = loss)
    let theoreticalChange: Double  // kg based on 7700 kcal ≈ 1 kg
}

struct WeightDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let kg: Double
    let lbs: Double
}

struct DeficitDay: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
    let target: Double
    let deficit: Double  // positive = under target
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
            + NutrientDatabase.others

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

    // MARK: - Weight + Deficit Analytics

    /// Daily calorie deficit relative to goal
    static func dailyDeficits(from entries: [FoodEntry], profile: UserProfile, days: Int = 30) -> [DeficitDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let target = profile.mode == .limit ? profile.calorieGoal : profile.tdee

        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let cals = dayEntries.reduce(0.0) { $0 + $1.calories }
            return DeficitDay(
                date: date,
                calories: cals,
                target: target,
                deficit: target - cals
            )
        }.reversed()
    }

    /// Convert HealthKit weight samples to display-ready data points
    static func weightTrend(from samples: [HealthKitManager.WeightSample], useImperial: Bool) -> [WeightDataPoint] {
        samples.map { sample in
            WeightDataPoint(
                date: sample.date,
                kg: sample.kg,
                lbs: sample.kg * 2.20462
            )
        }
    }

    /// Weekly correlation between calorie deficit and weight change
    static func weeklyCorrelations(
        entries: [FoodEntry],
        weights: [HealthKitManager.WeightSample],
        profile: UserProfile
    ) -> [WeeklyCorrelation] {
        let calendar = Calendar.current
        let target = profile.mode == .limit ? profile.calorieGoal : profile.tdee

        guard weights.count >= 2 else { return [] }

        // Group entries by week (Monday start)
        let sortedWeights = weights.sorted { $0.date < $1.date }
        guard let firstDate = sortedWeights.first?.date,
              let lastDate = sortedWeights.last?.date else { return [] }

        var correlations: [WeeklyCorrelation] = []
        var weekStart = calendar.dateInterval(of: .weekOfYear, for: firstDate)?.start ?? firstDate

        while weekStart < lastDate {
            guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { break }

            // Get weight at start and end of week (closest samples)
            let startWeight = sortedWeights.last(where: { $0.date <= weekStart })
                ?? sortedWeights.first(where: { $0.date >= weekStart })
            let endWeight = sortedWeights.last(where: { $0.date <= weekEnd })
                ?? sortedWeights.first(where: { $0.date >= weekEnd && $0.date < (calendar.date(byAdding: .day, value: 3, to: weekEnd) ?? weekEnd) })

            guard let sw = startWeight, let ew = endWeight, sw.date != ew.date else {
                weekStart = weekEnd
                continue
            }

            // Get calorie data for this week
            let weekEntries = entries.filter { $0.date >= weekStart && $0.date < weekEnd }
            let daysLogged = Set(weekEntries.map { calendar.startOfDay(for: $0.date) }).count
            guard daysLogged >= 3 else {
                weekStart = weekEnd
                continue
            }

            let totalCals = weekEntries.reduce(0.0) { $0 + $1.calories }
            let avgDailyCals = totalCals / Double(daysLogged)
            let avgDeficit = target - avgDailyCals
            let weightChange = ew.kg - sw.kg
            // 7700 kcal deficit ≈ 1 kg loss
            let theoreticalChange = -(avgDeficit * Double(daysLogged)) / 7700.0

            correlations.append(WeeklyCorrelation(
                weekStart: weekStart,
                avgDailyCalories: avgDailyCals,
                avgDailyDeficit: avgDeficit,
                weightStart: sw.kg,
                weightEnd: ew.kg,
                weightChange: weightChange,
                theoreticalChange: theoreticalChange
            ))

            weekStart = weekEnd
        }

        return correlations
    }
}
