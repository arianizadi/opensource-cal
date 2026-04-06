import SwiftUI
import SwiftData
import WidgetKit

struct FoodLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodEntry.date, order: .reverse) private var allEntries: [FoodEntry]
    @State private var selectedDate: Date = .now
    @State private var showingAddFood = false
    @State private var showingScanner = false
    @State private var showingSavedMeals = false

    private var todaysEntries: [FoodEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var totalCalories: Double {
        todaysEntries.reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        NavigationStack {
            List {
                if !todaysEntries.isEmpty {
                    Section {
                        summaryBar
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowSeparator(.hidden)
                }

                if todaysEntries.isEmpty {
                    Section {
                        emptyState
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    Section {
                        ForEach(todaysEntries) { entry in
                            ZStack {
                                NavigationLink {
                                    FoodDetailView(entry: entry, onDelete: {
                                        deleteEntry(entry)
                                    })
                                } label: {
                                    EmptyView()
                                }
                                .opacity(0)

                                FoodEntryCard(entry: entry)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                deleteEntry(todaysEntries[index])
                            }
                        }
                    }
                }

                Section {
                    Spacer(minLength: 80)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Cal.bg)
            .environment(\.defaultMinListRowHeight, 1)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .labelsHidden()
                        .tint(Cal.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingAddFood = true
                        } label: {
                            Label("Manual Entry", systemImage: "pencil")
                        }
                        Button {
                            showingScanner = true
                        } label: {
                            Label("Scan Label", systemImage: "camera")
                        }
                        Button {
                            showingSavedMeals = true
                        } label: {
                            Label("Saved Meals", systemImage: "bookmark")
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Cal.bgElevated)
                                .frame(width: 32, height: 32)
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Cal.accent)
                        }
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingAddFood) {
                AddFoodView()
            }
            .fullScreenCover(isPresented: $showingScanner) {
                NutritionScannerView()
            }
            .sheet(isPresented: $showingSavedMeals) {
                SavedMealsView()
            }
        }
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(todaysEntries.count) items")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Cal.textSecondary)
                Text("logged today")
                    .font(.label())
                    .foregroundStyle(Cal.textTertiary)
            }

            Spacer()

            Text("\(Int(totalCalories))")
                .font(.displaySmall())
                .foregroundStyle(Cal.accent)
            Text(" kcal")
                .font(.mono(12))
                .foregroundStyle(Cal.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Cal.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 60)

            ZStack {
                Circle()
                    .fill(Cal.accentSoft)
                    .frame(width: 100, height: 100)
                Image(systemName: "fork.knife")
                    .font(.system(size: 36))
                    .foregroundStyle(Cal.accent)
            }

            VStack(spacing: 6) {
                Text("No food logged")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Cal.textPrimary)
                Text("Tap + to add food or scan a label")
                    .font(.system(size: 14))
                    .foregroundStyle(Cal.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Delete

    private func deleteEntry(_ entry: FoodEntry) {
        let hkID = entry.healthKitID
        withAnimation(.spring(response: 0.3)) {
            modelContext.delete(entry)
        }
        WidgetCenter.shared.reloadAllTimelines()
        if let hkID {
            Task {
                await HealthKitManager.shared.deleteFoodEntry(healthKitID: hkID)
            }
        }
    }
}

// MARK: - Food Entry Card

struct FoodEntryCard: View {
    let entry: FoodEntry

    var body: some View {
        HStack(spacing: 14) {
            // Calorie badge
            VStack(spacing: 0) {
                Text("\(Int(entry.calories))")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Cal.accent)
                Text("kcal")
                    .font(.mono(9))
                    .foregroundStyle(Cal.textTertiary)
            }
            .frame(width: 56)

            // Divider
            RoundedRectangle(cornerRadius: 0.5)
                .fill(Color.white.opacity(0.06))
                .frame(width: 1, height: 36)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.name.isEmpty ? "Unnamed Food" : entry.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Cal.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    macroTag("P", value: entry.protein, color: Cal.protein)
                    macroTag("C", value: entry.totalCarbohydrates, color: Cal.carbs)
                    macroTag("F", value: entry.totalFat, color: Cal.fat)
                }
            }

            Spacer()

            if !entry.servingSize.isEmpty {
                Text(entry.servingSize)
                    .font(.mono(10))
                    .foregroundStyle(Cal.textTertiary)
                    .lineLimit(1)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Cal.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Cal.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
        )
    }

    private func macroTag(_ label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Text("\(label) \(Int(value))g")
                .font(.mono(10))
                .foregroundStyle(Cal.textSecondary)
        }
    }
}

// MARK: - Food Detail View

struct FoodDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let entry: FoodEntry
    var onDelete: (() -> Void)?
    @State private var showSavedConfirmation = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Hero card
                VStack(spacing: 12) {
                    Text("\(Int(entry.calories))")
                        .font(.displayLarge())
                        .foregroundStyle(Cal.accent)
                    Text("KILOCALORIES")
                        .font(.label())
                        .tracking(2)
                        .foregroundStyle(Cal.textTertiary)

                    if !entry.servingSize.isEmpty {
                        Text(entry.servingSize)
                            .font(.mono(12))
                            .foregroundStyle(Cal.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Cal.bgSubtle, in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .glassCard()

                // Macros
                detailSection("Macronutrients") {
                    detailRow("Total Fat", value: entry.totalFat, unit: "g")
                    detailRow("  Saturated Fat", value: entry.saturatedFat, unit: "g")
                    detailRow("  Trans Fat", value: entry.transFat, unit: "g")
                    detailRow("Cholesterol", value: entry.cholesterol, unit: "mg")
                    detailRow("Sodium", value: entry.sodium, unit: "mg")
                    detailRow("Total Carbs", value: entry.totalCarbohydrates, unit: "g")
                    detailRow("  Dietary Fiber", value: entry.dietaryFiber, unit: "g")
                    detailRow("  Total Sugars", value: entry.totalSugars, unit: "g")
                    detailRow("  Added Sugars", value: entry.addedSugars, unit: "g")
                    detailRow("Protein", value: entry.protein, unit: "g")
                }

                // Vitamins
                detailSection("Vitamins") {
                    detailRow("Vitamin A", value: entry.vitaminA, unit: "mcg")
                    detailRow("Vitamin C", value: entry.vitaminC, unit: "mg")
                    detailRow("Vitamin D", value: entry.vitaminD, unit: "mcg")
                    detailRow("Vitamin E", value: entry.vitaminE, unit: "mg")
                    detailRow("Vitamin K", value: entry.vitaminK, unit: "mcg")
                    detailRow("Thiamine (B1)", value: entry.thiamine, unit: "mg")
                    detailRow("Riboflavin (B2)", value: entry.riboflavin, unit: "mg")
                    detailRow("Niacin (B3)", value: entry.niacin, unit: "mg")
                    detailRow("B5", value: entry.pantothenicAcid, unit: "mg")
                    detailRow("Vitamin B6", value: entry.vitaminB6, unit: "mg")
                    detailRow("Biotin (B7)", value: entry.biotin, unit: "mcg")
                    detailRow("Folate (B9)", value: entry.folate, unit: "mcg")
                    detailRow("Vitamin B12", value: entry.vitaminB12, unit: "mcg")
                }

                // Minerals
                detailSection("Minerals") {
                    detailRow("Calcium", value: entry.calcium, unit: "mg")
                    detailRow("Iron", value: entry.iron, unit: "mg")
                    detailRow("Magnesium", value: entry.magnesium, unit: "mg")
                    detailRow("Phosphorus", value: entry.phosphorus, unit: "mg")
                    detailRow("Potassium", value: entry.potassium, unit: "mg")
                    detailRow("Zinc", value: entry.zinc, unit: "mg")
                    detailRow("Copper", value: entry.copper, unit: "mg")
                    detailRow("Manganese", value: entry.manganese, unit: "mg")
                    detailRow("Selenium", value: entry.selenium, unit: "mcg")
                    detailRow("Iodine", value: entry.iodine, unit: "mcg")
                    detailRow("Chloride", value: entry.chloride, unit: "mg")
                    detailRow("Fluoride", value: entry.fluoride, unit: "mg")
                }

                // Action buttons
                VStack(spacing: 10) {
                    Button {
                        let template = MealTemplate(from: entry)
                        modelContext.insert(template)
                        showSavedConfirmation = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Save as Template")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Cal.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(Cal.accent)
                    }

                    Button(role: .destructive) {
                        onDelete?()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .medium))
                            Text("Delete Entry")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Cal.low.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(Cal.low)
                    }
                }
                .padding(.top, 8)
                .overlay {
                    if showSavedConfirmation {
                        savedToast
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation { showSavedConfirmation = false }
                                }
                            }
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
        .background(Cal.bg)
        .navigationTitle(entry.name.isEmpty ? "Food Details" : entry.name)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var savedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Cal.good)
            Text("Saved as template")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Cal.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .environment(\.colorScheme, .dark)
    }

    private func detailSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.label())
                .tracking(2)
                .foregroundStyle(Cal.textTertiary)

            content()
        }
        .glassCard()
    }

    private func detailRow(_ name: String, value: Double, unit: String) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 13, weight: name.hasPrefix("  ") ? .regular : .medium))
                .foregroundStyle(name.hasPrefix("  ") ? Cal.textSecondary : Cal.textPrimary)
            Spacer()
            if value > 0 {
                Text("\(value < 1 ? String(format: "%.1f", value) : "\(Int(value))") \(unit)")
                    .font(.mono(13))
                    .foregroundStyle(Cal.textSecondary)
            } else {
                Text("-")
                    .font(.mono(13))
                    .foregroundStyle(Cal.textTertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
