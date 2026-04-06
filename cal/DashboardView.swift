import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [FoodEntry]
    @State private var selectedDate: Date = .now
    @State private var appeared = false
    @State private var showSettings = false
    @State private var showScoreInsight = false
    @Bindable private var profile = UserProfile.shared

    private var todaysEntries: [FoodEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private func total(_ keyPath: KeyPath<FoodEntry, Double>) -> Double {
        todaysEntries.reduce(0) { $0 + $1[keyPath: keyPath] }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                calorieSection
                    .padding(.top, 8)
                dailyScoreSection
                    .padding(.top, 24)
                topRecommendationsSection
                    .padding(.top, 12)
                macroSection
                    .padding(.top, 32)
                microSection
                    .padding(.top, 32)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .background(Cal.bg)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedDate, format: .dateTime.weekday(.wide))
                        .font(.label())
                        .textCase(.uppercase)
                        .tracking(2)
                        .foregroundStyle(Cal.accent)

                    Text(selectedDate, format: .dateTime.month(.wide).day())
                        .font(.displaySmall())
                        .foregroundStyle(Cal.textPrimary)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Cal.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(Cal.bgElevated, in: Circle())
                    }
                    .sheet(isPresented: $showSettings) { SettingsView() }

                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Cal.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(Cal.bgElevated, in: Circle())
                    }

                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Calendar.current.isDateInToday(selectedDate) ? Cal.textTertiary : Cal.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(Cal.bgElevated, in: Circle())
                    }
                    .disabled(Calendar.current.isDateInToday(selectedDate))
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Daily Score

    private var dailyScore: DailyScore {
        DailyScore.score(entries: todaysEntries, profile: profile)
    }

    @ViewBuilder
    private var dailyScoreSection: some View {
        if profile.hasSetProfile {
            let score = dailyScore
            Button {
                showScoreInsight = true
            } label: {
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // Grade circle
                        ZStack {
                            Circle()
                                .stroke(Cal.intelligenceGlow, lineWidth: 3)
                                .blur(radius: 6)
                                .opacity(0.3)
                                .frame(width: 56, height: 56)

                            Circle()
                                .fill(Cal.bgElevated)
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Circle()
                                        .stroke(gradeColor(score.grade).opacity(0.5), lineWidth: 1.5)
                                )

                            Text(score.grade)
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(gradeColor(score.grade))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Score")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(Cal.textPrimary)

                            Text("\(score.nutrientsCovered)/\(score.totalNutrients) nutrients above 50% DV")
                                .font(.mono(11))
                                .foregroundStyle(Cal.textTertiary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(score.overallScore)")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(gradeColor(score.grade))
                            Text("/ 100")
                                .font(.mono(10))
                                .foregroundStyle(Cal.textTertiary)
                        }
                    }

                    if let avgGI = score.estimatedGI {
                        Divider().overlay(Color.white.opacity(0.04))

                        HStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(giColor(avgGI).opacity(0.5))
                                    .frame(width: 6, height: 6)
                                Text("Est. Glycemic Index")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Cal.textSecondary)
                            }

                            Spacer()

                            Text(giLabel(avgGI))
                                .font(.mono(11))
                                .foregroundStyle(giColor(avgGI))

                            Text("\(Int(avgGI))")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(giColor(avgGI))
                        }

                        HStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Cal.textTertiary.opacity(0.5))
                                    .frame(width: 6, height: 6)
                                Text("Glycemic Load")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Cal.textSecondary)
                            }

                            Spacer()

                            Text("\(Int(score.dailyGL)) g")
                                .font(.mono(13))
                                .foregroundStyle(Cal.textPrimary)
                        }
                    }
                }
                .glassCard()
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showScoreInsight) {
                ScoreInsightSheet(entries: todaysEntries, profile: profile)
            }
        } else {
            Button {
                showSettings = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Cal.bgElevated)
                            .frame(width: 44, height: 44)
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 18))
                            .foregroundStyle(Cal.accent)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Set Up Your Profile")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Cal.textPrimary)
                        Text("Add height & weight to unlock your Daily Score")
                            .font(.system(size: 12))
                            .foregroundStyle(Cal.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Cal.textTertiary)
                }
            }
            .glassCard()
        }
    }

    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A+", "A": return Cal.good
        case "B+", "B": return Cal.accent
        case "C+", "C": return Cal.warn
        default: return Cal.low
        }
    }

    private func giColor(_ gi: Double) -> Color {
        if gi <= 55 { return Cal.good }
        if gi <= 69 { return Cal.warn }
        return Cal.low
    }

    private func giLabel(_ gi: Double) -> String {
        if gi <= 55 { return "LOW" }
        if gi <= 69 { return "MED" }
        return "HIGH"
    }

    // MARK: - Top Recommendations

    @ViewBuilder
    private var topRecommendationsSection: some View {
        if profile.hasSetProfile && !todaysEntries.isEmpty {
            let breakdown = ScoreBreakdown.analyze(entries: todaysEntries, profile: profile)
            let topRecs = Array(breakdown.recommendations.prefix(3))

            if !topRecs.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("TOP ACTIONS")
                        .font(.label())
                        .tracking(2)
                        .foregroundStyle(Cal.textTertiary)
                        .padding(.leading, 4)

                    ForEach(topRecs) { rec in
                        HStack(spacing: 12) {
                            Image(systemName: rec.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(categoryColor(rec.category))
                                .frame(width: 30, height: 30)
                                .background(categoryColor(rec.category).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(rec.title)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Cal.textPrimary)
                                    .lineLimit(1)
                                Text(rec.detail)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Cal.textTertiary)
                                    .lineLimit(2)
                            }

                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(16)
                .background(Cal.bgCard, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                )
            }
        }
    }

    private func categoryColor(_ cat: ScoreRecommendation.ScoreCategory) -> Color {
        switch cat {
        case .calorie: return Cal.accent
        case .macro: return Cal.protein
        case .micro: return Cal.vitaminWater
        case .glycemic: return Cal.warn
        }
    }

    // MARK: - Calorie Ring

    private var calorieSection: some View {
        VStack(spacing: 4) {
            if profile.mode == .limit {
                CalorieRingView(consumed: total(\.calories), goal: profile.calorieGoal)

                Text("\(Int(max(profile.calorieGoal - total(\.calories), 0))) remaining")
                    .font(.mono(12))
                    .foregroundStyle(Cal.textTertiary)
                    .padding(.top, 4)
            } else {
                TrackerCalorieView(consumed: total(\.calories))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glassCard()
        .intelligenceGlow(blur: 12)
    }

    // MARK: - Macros

    private var macroSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Macros")

            HStack(spacing: 0) {
                if profile.mode == .limit {
                    MacroRingView(
                        label: "Protein",
                        value: total(\.protein),
                        goal: profile.proteinGoal,
                        unit: "g",
                        gradient: Cal.proteinGradient,
                        glowColor: Cal.protein,
                        size: 80
                    )
                    .frame(maxWidth: .infinity)

                    MacroRingView(
                        label: "Carbs",
                        value: total(\.totalCarbohydrates),
                        goal: profile.carbGoal,
                        unit: "g",
                        gradient: Cal.carbsGradient,
                        glowColor: Cal.carbs,
                        size: 80
                    )
                    .frame(maxWidth: .infinity)

                    MacroRingView(
                        label: "Fat",
                        value: total(\.totalFat),
                        goal: profile.fatGoal,
                        unit: "g",
                        gradient: Cal.fatGradient,
                        glowColor: Cal.fat,
                        size: 80
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    TrackerMacroView(label: "Protein", value: total(\.protein), unit: "g", gradient: Cal.proteinGradient)
                        .frame(maxWidth: .infinity)
                    TrackerMacroView(label: "Carbs", value: total(\.totalCarbohydrates), unit: "g", gradient: Cal.carbsGradient)
                        .frame(maxWidth: .infinity)
                    TrackerMacroView(label: "Fat", value: total(\.totalFat), unit: "g", gradient: Cal.fatGradient)
                        .frame(maxWidth: .infinity)
                }
            }

            // Detail rows
            VStack(spacing: 0) {
                Divider().overlay(Color.white.opacity(0.04))
                    .padding(.bottom, 12)

                macroDetailRow("Sat. Fat", value: total(\.saturatedFat), unit: "g")
                macroDetailRow("Trans Fat", value: total(\.transFat), unit: "g")
                macroDetailRow("Cholesterol", value: total(\.cholesterol), unit: "mg")
                macroDetailRow("Sodium", value: total(\.sodium), unit: "mg")
                macroDetailRow("Fiber", value: total(\.dietaryFiber), unit: "g", color: Cal.fiber)
                macroDetailRow("Sugars", value: total(\.totalSugars), unit: "g")
            }
        }
        .glassCard()
    }

    private func macroDetailRow(_ name: String, value: Double, unit: String, color: Color = Cal.textSecondary) -> some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(color.opacity(0.5))
                    .frame(width: 4, height: 4)
                Text(name)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Cal.textSecondary)
            }
            Spacer()
            Text("\(value < 1 && value > 0 ? String(format: "%.1f", value) : "\(Int(value))") \(unit)")
                .font(.mono(13))
                .foregroundStyle(Cal.textPrimary)
        }
        .padding(.vertical, 5)
    }

    // MARK: - Micronutrients

    private var microSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Micronutrients")

            ForEach(Array(microCategories.enumerated()), id: \.offset) { index, group in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(group.color)
                            .frame(width: 3, height: 14)
                        Text(group.title.uppercased())
                            .font(.label())
                            .tracking(1)
                            .foregroundStyle(Cal.textTertiary)
                    }
                    .padding(.top, index > 0 ? 8 : 0)

                    ForEach(group.nutrients) { nutrient in
                        MicroProgressRow(
                            nutrient: nutrient,
                            value: NutrientDatabase.totalForEntries(todaysEntries, nutrient: nutrient),
                            accentColor: group.color
                        )
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.label())
            .tracking(2)
            .foregroundStyle(Cal.textTertiary)
    }

    private var microCategories: [(title: String, color: Color, nutrients: [NutrientInfo])] {
        [
            ("Fat-Soluble Vitamins", Cal.vitaminFat, NutrientDatabase.fatSolubleVitamins),
            ("Water-Soluble Vitamins", Cal.vitaminWater, NutrientDatabase.waterSolubleVitamins),
            ("Macrominerals", Cal.mineral, NutrientDatabase.macrominerals),
            ("Trace Minerals", Cal.trace, NutrientDatabase.traceMinerals),
            ("Other", Cal.accent, NutrientDatabase.others),
        ]
    }
}

// MARK: - Score Insight Sheet

struct ScoreInsightSheet: View {
    @Environment(\.dismiss) private var dismiss
    let entries: [FoodEntry]
    let profile: UserProfile

    private var score: DailyScore {
        DailyScore.score(entries: entries, profile: profile)
    }

    private var breakdown: ScoreBreakdown {
        ScoreBreakdown.analyze(entries: entries, profile: profile)
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    heroSection
                    breakdownSection
                    recommendationsSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(Cal.bg)
            .navigationTitle("Score Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Cal.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Cal.intelligenceGlow, lineWidth: 6)
                    .blur(radius: 12)
                    .opacity(0.3)
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(Cal.bgElevated)
                    .frame(width: 90, height: 90)
                    .overlay(
                        Circle()
                            .stroke(gradeColor(score.grade).opacity(0.5), lineWidth: 2)
                    )

                Text(score.grade)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(gradeColor(score.grade))
            }

            Text("\(score.overallScore) / 100")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Cal.textPrimary)

            Text("Your daily nutrition score based on calorie adequacy, macro balance, micronutrient coverage, and glycemic impact.")
                .font(.system(size: 13))
                .foregroundStyle(Cal.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard()
    }

    // MARK: - Component Breakdown

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SCORE COMPONENTS")
                .font(.label())
                .tracking(2)
                .foregroundStyle(Cal.textTertiary)

            componentRow(
                label: "Calories",
                detail: "20% of score",
                score: breakdown.calorieScore,
                color: Cal.accent,
                explanation: calorieExplanation
            )
            componentRow(
                label: "Macros",
                detail: "20% of score",
                score: breakdown.macroScore,
                color: Cal.protein,
                explanation: macroExplanation
            )
            componentRow(
                label: "Micronutrients",
                detail: "50% of score",
                score: breakdown.microScore,
                color: Cal.vitaminWater,
                explanation: microExplanation
            )
            componentRow(
                label: "Glycemic Index",
                detail: "10% of score",
                score: breakdown.glycemicScore,
                color: Cal.warn,
                explanation: glycemicExplanation
            )
        }
        .glassCard()
    }

    private func componentRow(label: String, detail: String, score: Int, color: Color, explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Cal.textPrimary)
                    Text(detail)
                        .font(.mono(10))
                        .foregroundStyle(Cal.textTertiary)
                }

                Spacer()

                Text("\(score)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor(score))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.04))
                        .frame(height: 6)
                    Capsule().fill(
                        LinearGradient(
                            colors: [color.opacity(0.6), color],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * min(Double(score) / 100.0, 1.0), height: 6)
                    .shadow(color: color.opacity(0.3), radius: 4)
                }
            }
            .frame(height: 6)

            Text(explanation)
                .font(.system(size: 12))
                .foregroundStyle(Cal.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(Color.white.opacity(0.04))
                .padding(.top, 4)
        }
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RECOMMENDATIONS")
                .font(.label())
                .tracking(2)
                .foregroundStyle(Cal.textTertiary)

            if breakdown.recommendations.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Cal.good)
                    Text("Looking good! No major issues detected.")
                        .font(.system(size: 14))
                        .foregroundStyle(Cal.textSecondary)
                }
            } else {
                ForEach(breakdown.recommendations) { rec in
                    recRow(rec)
                }
            }
        }
        .glassCard()
    }

    private func recRow(_ rec: ScoreRecommendation) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: rec.icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(recCategoryColor(rec.category))
                .frame(width: 34, height: 34)
                .background(recCategoryColor(rec.category).opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(rec.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Cal.textPrimary)
                    Spacer()
                    Text(rec.category.rawValue)
                        .font(.mono(9))
                        .foregroundStyle(Cal.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Cal.bgSubtle, in: Capsule())
                }

                Text(rec.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Cal.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A+", "A": return Cal.good
        case "B+", "B": return Cal.accent
        case "C+", "C": return Cal.warn
        default: return Cal.low
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return Cal.good }
        if score >= 50 { return Cal.warn }
        return Cal.low
    }

    private func recCategoryColor(_ cat: ScoreRecommendation.ScoreCategory) -> Color {
        switch cat {
        case .calorie: return Cal.accent
        case .macro: return Cal.protein
        case .micro: return Cal.vitaminWater
        case .glycemic: return Cal.warn
        }
    }

    // MARK: - Component Explanations

    private var calorieExplanation: String {
        let consumed = entries.reduce(0.0) { $0 + $1.calories }
        if profile.mode == .tracker {
            guard consumed > 0 else { return "Log food to start tracking." }
            return "You've eaten \(Int(consumed)) kcal today. In tracker mode, calorie score is neutral — switch to Limit mode in settings to score against a goal."
        }
        let target = profile.calorieGoal
        guard target > 0 && consumed > 0 else {
            return "Log food to see how your intake compares to your \(Int(target)) kcal goal."
        }
        let pct = Int(consumed / target * 100)
        return "You've eaten \(Int(consumed)) of \(Int(target)) kcal (\(pct)%). Scoring rewards 85-115% of your calorie goal."
    }

    private var macroExplanation: String {
        let cal = entries.reduce(0.0) { $0 + $1.calories }
        guard cal > 100 else { return "Not enough data to evaluate macros." }
        let protein = entries.reduce(0.0) { $0 + $1.protein }
        let fiber = entries.reduce(0.0) { $0 + $1.dietaryFiber }
        return "Protein: \(Int(protein))g (target: \(Int(profile.weightKg * 0.8))g+), Fiber: \(Int(fiber))g (target: 25g+). Evaluates carb/fat/protein ratios, sat fat, sodium, and added sugar."
    }

    private var microExplanation: String {
        "\(score.nutrientsCovered) of \(score.totalNutrients) tracked nutrients are above 50% DV. This is the largest component — eat diverse whole foods to maximize it."
    }

    private var glycemicExplanation: String {
        if let gi = score.estimatedGI {
            let label = gi <= 55 ? "low" : (gi <= 69 ? "medium" : "high")
            return "Estimated average GI: \(Int(gi)) (\(label)). Daily GL: \(Int(score.dailyGL))g. Lower GI means steadier blood sugar and sustained energy."
        }
        return "Not enough carbohydrate data to estimate glycemic impact."
    }
}
