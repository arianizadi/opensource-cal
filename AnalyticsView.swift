import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query(sort: \FoodEntry.date, order: .reverse) private var entries: [FoodEntry]
    @State private var selectedPeriod: TimePeriod = .week
    @State private var weightSamples: [HealthKitManager.WeightSample] = []
    private var healthKit = HealthKitManager.shared
    private var profile = UserProfile.shared

    enum TimePeriod: String, CaseIterable {
        case week = "7D"
        case twoWeeks = "14D"
        case month = "30D"

        var days: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 14
            case .month: return 30
            }
        }
    }

    private var summaries: [DailyNutrientSummary] {
        AnalyticsEngine.dailySummaries(from: entries, days: selectedPeriod.days)
    }

    private var gaps: [NutrientGap] {
        AnalyticsEngine.nutrientGaps(from: entries, days: selectedPeriod.days)
    }

    private var scoredFoods: [FoodScore] {
        AnalyticsEngine.scoredFoods(from: entries)
    }

    private var weightTrend: [WeightDataPoint] {
        AnalyticsEngine.weightTrend(from: weightSamples, useImperial: profile.useImperial)
    }

    private var deficits: [DeficitDay] {
        AnalyticsEngine.dailyDeficits(from: entries, profile: profile, days: selectedPeriod.days)
    }

    private var correlations: [WeeklyCorrelation] {
        AnalyticsEngine.weeklyCorrelations(entries: entries, weights: weightSamples, profile: profile)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                periodPicker
                calorieTrendCard
                macroTrendCard
                weightTrendCard
                deficitCard
                correlationCard
                topFoodsCard
                worstFoodsCard
                nutrientGapsCard
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .background(Cal.bg)
        .scrollIndicators(.hidden)
        .task {
            await loadWeight()
        }
        .onChange(of: selectedPeriod) {
            Task { await loadWeight() }
        }
    }

    private func loadWeight() async {
        weightSamples = await healthKit.fetchWeightSamples(days: selectedPeriod.days + 7)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Analytics")
                    .font(.displaySmall())
                    .foregroundStyle(Cal.textPrimary)
                Text("Nutrition insights")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Cal.textSecondary)
            }
            Spacer()
        }
        .padding(.top, 16)
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        HStack(spacing: 4) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(selectedPeriod == period ? Cal.textPrimary : Cal.textTertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedPeriod == period ? Cal.bgElevated : .clear)
                        )
                }
            }
        }
        .padding(4)
        .background(Capsule().fill(Cal.bgCard))
    }

    // MARK: - Calorie Trend

    private var calorieTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("CALORIES")
                    .font(.label())
                    .tracking(1.2)
                    .foregroundStyle(Cal.textSecondary)
                Spacer()
                if let avg = averageCalories {
                    Text("avg \(Int(avg))")
                        .font(.mono(12))
                        .foregroundStyle(Cal.textTertiary)
                }
            }

            if summaries.isEmpty {
                emptyState
            } else {
                Chart(summaries) { day in
                    AreaMark(
                        x: .value("Date", day.date, unit: .day),
                        y: .value("Calories", day.calories)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Cal.glowPurple.opacity(0.3), Cal.glowPurple.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Date", day.date, unit: .day),
                        y: .value("Calories", day.calories)
                    )
                    .foregroundStyle(Cal.glowPurple)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", day.date, unit: .day),
                        y: .value("Calories", day.calories)
                    )
                    .foregroundStyle(Cal.glowPurple)
                    .symbolSize(day.calories > 0 ? 20 : 0)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(.dateTime.weekday(.narrow)))
                                    .font(.system(size: 10))
                                    .foregroundStyle(Cal.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))")
                                    .font(.mono(10))
                                    .foregroundStyle(Cal.textTertiary)
                            }
                        }
                    }
                }
                .frame(height: 160)
            }
        }
        .glassCard()
    }

    // MARK: - Macro Trend

    private var macroTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MACROS")
                .font(.label())
                .tracking(1.2)
                .foregroundStyle(Cal.textSecondary)

            if summaries.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(summaries) { day in
                        LineMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Grams", day.protein),
                            series: .value("Macro", "Protein")
                        )
                        .foregroundStyle(Cal.protein)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Grams", day.carbs),
                            series: .value("Macro", "Carbs")
                        )
                        .foregroundStyle(Cal.carbs)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Grams", day.fat),
                            series: .value("Macro", "Fat")
                        )
                        .foregroundStyle(Cal.fat)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(.dateTime.weekday(.narrow)))
                                    .font(.system(size: 10))
                                    .foregroundStyle(Cal.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))g")
                                    .font(.mono(10))
                                    .foregroundStyle(Cal.textTertiary)
                            }
                        }
                    }
                }
                .chartForegroundStyleScale([
                    "Protein": Cal.protein,
                    "Carbs": Cal.carbs,
                    "Fat": Cal.fat
                ])
                .chartLegend(.hidden)
                .frame(height: 160)

                HStack(spacing: 16) {
                    macroLegend(color: Cal.protein, label: "Protein")
                    macroLegend(color: Cal.carbs, label: "Carbs")
                    macroLegend(color: Cal.fat, label: "Fat")
                }
            }
        }
        .glassCard()
    }

    // MARK: - Weight Trend

    private var weightTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("WEIGHT")
                    .font(.label())
                    .tracking(1.2)
                    .foregroundStyle(Cal.textSecondary)
                Spacer()
                if let latest = weightTrend.last {
                    let val = profile.useImperial ? latest.lbs : latest.kg
                    let unit = profile.useImperial ? "lbs" : "kg"
                    Text("\(String(format: "%.1f", val)) \(unit)")
                        .font(.mono(12))
                        .foregroundStyle(Cal.textTertiary)
                }
            }

            if weightTrend.count < 2 {
                weightEmptyState
            } else {
                let values = weightTrend.map { profile.useImperial ? $0.lbs : $0.kg }
                let minVal = (values.min() ?? 0) - 1
                let maxVal = (values.max() ?? 0) + 1
                let unit = profile.useImperial ? "lbs" : "kg"

                Chart(weightTrend) { point in
                    let val = profile.useImperial ? point.lbs : point.kg

                    AreaMark(
                        x: .value("Date", point.date),
                        yStart: .value("Weight", minVal),
                        yEnd: .value("Weight", val)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Cal.glowCyan.opacity(0.25), Cal.glowCyan.opacity(0.03)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", val)
                    )
                    .foregroundStyle(Cal.glowCyan)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", val)
                    )
                    .foregroundStyle(Cal.glowCyan)
                    .symbolSize(24)
                }
                .chartYScale(domain: minVal...maxVal)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.system(size: 10))
                                    .foregroundStyle(Cal.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(String(format: "%.0f", v))")
                                    .font(.mono(10))
                                    .foregroundStyle(Cal.textTertiary)
                            }
                        }
                    }
                }
                .frame(height: 160)

                if weightTrend.count >= 2 {
                    let first = profile.useImperial ? weightTrend.first!.lbs : weightTrend.first!.kg
                    let last = profile.useImperial ? weightTrend.last!.lbs : weightTrend.last!.kg
                    let change = last - first
                    let sign = change >= 0 ? "+" : ""
                    HStack {
                        Text("Change over period")
                            .font(.system(size: 12))
                            .foregroundStyle(Cal.textTertiary)
                        Spacer()
                        Text("\(sign)\(String(format: "%.1f", change)) \(unit)")
                            .font(.mono(13))
                            .foregroundStyle(change < 0 ? Cal.good : (change > 0 ? Cal.warn : Cal.textSecondary))
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Daily Deficit

    private var deficitCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("DAILY DEFICIT")
                    .font(.label())
                    .tracking(1.2)
                    .foregroundStyle(Cal.textSecondary)
                Spacer()
                let avgDeficit = deficits.filter { $0.calories > 0 }
                if !avgDeficit.isEmpty {
                    let avg = avgDeficit.reduce(0) { $0 + $1.deficit } / Double(avgDeficit.count)
                    Text("avg \(avg >= 0 ? "−" : "+")\(Int(abs(avg)))")
                        .font(.mono(12))
                        .foregroundStyle(Cal.textTertiary)
                }
            }

            let logged = deficits.filter { $0.calories > 0 }
            if logged.isEmpty {
                emptyState
            } else {
                Chart(logged) { day in
                    BarMark(
                        x: .value("Date", day.date, unit: .day),
                        y: .value("Deficit", day.deficit)
                    )
                    .foregroundStyle(day.deficit >= 0 ? Cal.good.opacity(0.7) : Cal.low.opacity(0.7))
                    .cornerRadius(3)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: selectedPeriod == .week ? .day : .weekOfYear)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(selectedPeriod == .week ? .dateTime.weekday(.narrow) : .dateTime.month(.abbreviated).day()))
                                    .font(.system(size: 10))
                                    .foregroundStyle(Cal.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))")
                                    .font(.mono(10))
                                    .foregroundStyle(Cal.textTertiary)
                            }
                        }
                    }
                }
                .frame(height: 140)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle().fill(Cal.good).frame(width: 6, height: 6)
                        Text("Under target")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Cal.textSecondary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Cal.low).frame(width: 6, height: 6)
                        Text("Over target")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Cal.textSecondary)
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Weekly Correlation (Actual vs Theoretical)

    private var correlationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DEFICIT vs WEIGHT CHANGE")
                    .font(.label())
                    .tracking(1.2)
                    .foregroundStyle(Cal.textSecondary)
                Text("Weekly: actual vs predicted from calories")
                    .font(.system(size: 11))
                    .foregroundStyle(Cal.textTertiary)
            }

            if correlations.isEmpty {
                VStack(spacing: 8) {
                    Text("Needs weight data + food logs")
                        .font(.system(size: 14))
                        .foregroundStyle(Cal.textTertiary)
                    Text("Log weight in the Health app and track food for 1+ weeks to see how your calorie deficit correlates with actual weight change.")
                        .font(.system(size: 12))
                        .foregroundStyle(Cal.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else {
                let useImp = profile.useImperial
                let factor = useImp ? 2.20462 : 1.0
                let unit = useImp ? "lbs" : "kg"

                Chart {
                    ForEach(correlations) { week in
                        BarMark(
                            x: .value("Week", week.weekStart, unit: .weekOfYear),
                            y: .value("Actual", week.weightChange * factor)
                        )
                        .foregroundStyle(Cal.glowCyan.opacity(0.7))
                        .cornerRadius(4)
                        .position(by: .value("Type", "Actual"))

                        BarMark(
                            x: .value("Week", week.weekStart, unit: .weekOfYear),
                            y: .value("Predicted", week.theoreticalChange * factor)
                        )
                        .foregroundStyle(Cal.glowPurple.opacity(0.5))
                        .cornerRadius(4)
                        .position(by: .value("Type", "Predicted"))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.system(size: 10))
                                    .foregroundStyle(Cal.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(String(format: "%.1f", v))")
                                    .font(.mono(10))
                                    .foregroundStyle(Cal.textTertiary)
                            }
                        }
                    }
                }
                .chartForegroundStyleScale([
                    "Actual": Cal.glowCyan,
                    "Predicted": Cal.glowPurple
                ])
                .chartLegend(.hidden)
                .frame(height: 160)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2).fill(Cal.glowCyan).frame(width: 12, height: 8)
                        Text("Actual (\(unit))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Cal.textSecondary)
                    }
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2).fill(Cal.glowPurple).frame(width: 12, height: 8)
                        Text("Predicted")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Cal.textSecondary)
                    }
                }

                Text("Predicted assumes 7,700 kcal deficit ≈ 1 kg loss. Actual results vary with water retention, metabolism, and activity.")
                    .font(.system(size: 11))
                    .foregroundStyle(Cal.textTertiary)
            }
        }
        .glassCard()
    }

    private var weightEmptyState: some View {
        VStack(spacing: 8) {
            Text("No weight data")
                .font(.system(size: 14))
                .foregroundStyle(Cal.textTertiary)
            Text("Log your weight in the Health app or a connected scale to see trends here.")
                .font(.system(size: 12))
                .foregroundStyle(Cal.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 20)
    }

    // MARK: - Top Foods

    private var topFoodsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("BEST FOODS")
                    .font(.label())
                    .tracking(1.2)
                    .foregroundStyle(Cal.textSecondary)
                Spacer()
                Text("by nutrition score")
                    .font(.system(size: 11))
                    .foregroundStyle(Cal.textTertiary)
            }

            if scoredFoods.isEmpty {
                emptyState
            } else {
                ForEach(Array(scoredFoods.prefix(5).enumerated()), id: \.offset) { index, score in
                    foodScoreRow(score: score, rank: index + 1)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Worst Foods

    private var worstFoodsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("NEEDS IMPROVEMENT")
                    .font(.label())
                    .tracking(1.2)
                    .foregroundStyle(Cal.textSecondary)
                Spacer()
                Text("lowest scores")
                    .font(.system(size: 11))
                    .foregroundStyle(Cal.textTertiary)
            }

            let worst = Array(scoredFoods.suffix(5).reversed())
            if worst.isEmpty {
                emptyState
            } else {
                ForEach(Array(worst.enumerated()), id: \.offset) { _, score in
                    foodScoreRow(score: score, rank: nil)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Nutrient Gaps

    private var nutrientGapsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("NUTRIENT GAPS")
                    .font(.label())
                    .tracking(1.2)
                    .foregroundStyle(Cal.textSecondary)
                Spacer()
                Text("\(selectedPeriod.days)-day avg")
                    .font(.system(size: 11))
                    .foregroundStyle(Cal.textTertiary)
            }

            if gaps.isEmpty {
                emptyState
            } else {
                ForEach(Array(gaps.prefix(8).enumerated()), id: \.offset) { _, gap in
                    gapRow(gap: gap)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Subviews

    private func foodScoreRow(score: FoodScore, rank: Int?) -> some View {
        HStack(spacing: 12) {
            if let rank {
                Text("#\(rank)")
                    .font(.mono(12))
                    .foregroundStyle(Cal.textTertiary)
                    .frame(width: 24)
            }

            gradeView(score.grade)

            VStack(alignment: .leading, spacing: 2) {
                Text(score.entry.name.isEmpty ? "Unnamed" : score.entry.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Cal.textPrimary)
                    .lineLimit(1)

                Text("\(Int(score.entry.calories)) kcal")
                    .font(.mono(11))
                    .foregroundStyle(Cal.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(score.overallScore)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor(score.overallScore))

                HStack(spacing: 8) {
                    Text("M:\(score.macroBalance)")
                        .font(.mono(9))
                        .foregroundStyle(Cal.textTertiary)
                    Text("N:\(score.microDensity)")
                        .font(.mono(9))
                        .foregroundStyle(Cal.textTertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func gradeView(_ grade: String) -> some View {
        Text(grade)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(gradeColor(grade))
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(gradeColor(grade).opacity(0.12))
            )
    }

    private func gapRow(gap: NutrientGap) -> some View {
        HStack(spacing: 12) {
            Text(gap.nutrient.shortName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Cal.textPrimary)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 6)

                    Capsule()
                        .fill(gapBarGradient(gap.averagePercent))
                        .frame(
                            width: max(geo.size.width * min(gap.averagePercent, 1.0), 2),
                            height: 6
                        )
                }
            }
            .frame(height: 6)

            Text("\(Int(gap.averagePercent * 100))%")
                .font(.mono(12))
                .foregroundStyle(gapColor(gap.averagePercent))
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 3)
    }

    private func macroLegend(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Cal.textSecondary)
        }
    }

    private var emptyState: some View {
        Text("Not enough data yet")
            .font(.system(size: 14))
            .foregroundStyle(Cal.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
    }

    // MARK: - Helpers

    private var averageCalories: Double? {
        let withData = summaries.filter { $0.calories > 0 }
        guard !withData.isEmpty else { return nil }
        return withData.reduce(0) { $0 + $1.calories } / Double(withData.count)
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return Cal.good
        case 60..<80: return Cal.protein
        case 40..<60: return Cal.warn
        default: return Cal.low
        }
    }

    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A+", "A": return Cal.good
        case "B+", "B": return Cal.protein
        case "C+", "C": return Cal.warn
        default: return Cal.low
        }
    }

    private func gapColor(_ percent: Double) -> Color {
        if percent >= 1.0 { return Cal.good }
        if percent >= 0.5 { return Cal.textSecondary }
        if percent >= 0.25 { return Cal.warn }
        return Cal.low
    }

    private func gapBarGradient(_ percent: Double) -> LinearGradient {
        let color = gapColor(percent)
        return LinearGradient(
            colors: [color.opacity(0.5), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
