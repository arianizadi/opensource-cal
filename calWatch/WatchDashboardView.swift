import SwiftUI
import SwiftData

struct WatchDashboardView: View {
    @Query private var allEntries: [FoodEntry]

    private var todaysEntries: [FoodEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: .now) }
    }

    private var calories: Double {
        todaysEntries.reduce(0) { $0 + $1.calories }
    }

    private var protein: Double {
        todaysEntries.reduce(0) { $0 + $1.protein }
    }

    private var carbs: Double {
        todaysEntries.reduce(0) { $0 + $1.totalCarbohydrates }
    }

    private var fat: Double {
        todaysEntries.reduce(0) { $0 + $1.totalFat }
    }

    private var dailyScore: DailyScore {
        DailyScore.score(entries: todaysEntries)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Grade + Score
                HStack {
                    ZStack {
                        Circle()
                            .stroke(gradeColor.opacity(0.3), lineWidth: 4)
                            .frame(width: 44, height: 44)
                        Circle()
                            .trim(from: 0, to: Double(dailyScore.overallScore) / 100.0)
                            .stroke(gradeColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 44, height: 44)
                        Text(dailyScore.grade)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(gradeColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(calories))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("kcal today")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider()

                // Macros
                HStack(spacing: 0) {
                    watchMacro("P", value: protein, color: .blue)
                    watchMacro("C", value: carbs, color: .pink)
                    watchMacro("F", value: fat, color: .purple)
                }

                // Nutrient coverage
                VStack(spacing: 4) {
                    HStack {
                        Text("Nutrients")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(dailyScore.nutrientsCovered)/\(dailyScore.totalNutrients)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }

                    ProgressView(value: Double(dailyScore.nutrientsCovered), total: Double(max(dailyScore.totalNutrients, 1)))
                        .tint(gradeColor)
                }

                Text("\(todaysEntries.count) meals")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Cal")
    }

    private func watchMacro(_ letter: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(letter)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text("\(Int(value))g")
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity)
    }

    private var gradeColor: Color {
        switch dailyScore.grade {
        case "A+", "A": return .green
        case "B+", "B": return .purple
        case "C+", "C": return .orange
        default: return .red
        }
    }
}
