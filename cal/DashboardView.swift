import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [FoodEntry]
    @State private var selectedDate: Date = .now
    @State private var appeared = false

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

                HStack(spacing: 16) {
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

    // MARK: - Calorie Ring

    private var calorieSection: some View {
        VStack(spacing: 4) {
            CalorieRingView(consumed: total(\.calories), goal: 2000)

            Text("\(Int(max(2000 - total(\.calories), 0))) remaining")
                .font(.mono(12))
                .foregroundStyle(Cal.textTertiary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glassCard()
    }

    // MARK: - Macros

    private var macroSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Macros")

            HStack(spacing: 0) {
                MacroRingView(
                    label: "Protein",
                    value: total(\.protein),
                    goal: 50,
                    unit: "g",
                    gradient: Cal.proteinGradient,
                    glowColor: Cal.protein,
                    size: 80
                )
                .frame(maxWidth: .infinity)

                MacroRingView(
                    label: "Carbs",
                    value: total(\.totalCarbohydrates),
                    goal: 275,
                    unit: "g",
                    gradient: Cal.carbsGradient,
                    glowColor: Cal.carbs,
                    size: 80
                )
                .frame(maxWidth: .infinity)

                MacroRingView(
                    label: "Fat",
                    value: total(\.totalFat),
                    goal: 78,
                    unit: "g",
                    gradient: Cal.fatGradient,
                    glowColor: Cal.fat,
                    size: 80
                )
                .frame(maxWidth: .infinity)
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
        ]
    }
}
