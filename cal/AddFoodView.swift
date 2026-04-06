import SwiftUI
import SwiftData
import WidgetKit

struct AddFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    private var healthKit = HealthKitManager.shared

    @State private var name = ""
    @State private var servingSize = ""
    @State private var values: [String: String] = [:]
    @State private var showMicros = false

    var scannedData: [String: Double]?
    var onSave: (() -> Void)?

    init(scannedData: [String: Double]? = nil, onSave: (() -> Void)? = nil) {
        self.scannedData = scannedData
        self.onSave = onSave
    }

    private static let macroFields: [(key: String, label: String, unit: String)] = [
        ("saturatedFat", "Sat. Fat", "g"),
        ("transFat", "Trans Fat", "g"),
        ("polyunsaturatedFat", "Polyunsat. Fat", "g"),
        ("monounsaturatedFat", "Monounsat. Fat", "g"),
        ("cholesterol", "Cholesterol", "mg"),
        ("sodium", "Sodium", "mg"),
        ("dietaryFiber", "Fiber", "g"),
        ("totalSugars", "Sugars", "g"),
        ("addedSugars", "Added Sugars", "g"),
    ]

    private static let vitaminFields: [(key: String, label: String, unit: String)] = [
        ("vitaminA", "Vitamin A", "mcg"),
        ("vitaminC", "Vitamin C", "mg"),
        ("vitaminD", "Vitamin D", "mcg"),
        ("vitaminE", "Vitamin E", "mg"),
        ("vitaminK", "Vitamin K", "mcg"),
        ("thiamine", "B1 Thiamine", "mg"),
        ("riboflavin", "B2 Riboflavin", "mg"),
        ("niacin", "B3 Niacin", "mg"),
        ("pantothenicAcid", "B5 Pantothenic", "mg"),
        ("vitaminB6", "B6", "mg"),
        ("biotin", "B7 Biotin", "mcg"),
        ("folate", "B9 Folate", "mcg"),
        ("vitaminB12", "B12", "mcg"),
    ]

    private static let mineralFields: [(key: String, label: String, unit: String)] = [
        ("calcium", "Calcium", "mg"),
        ("iron", "Iron", "mg"),
        ("magnesium", "Magnesium", "mg"),
        ("phosphorus", "Phosphorus", "mg"),
        ("potassium", "Potassium", "mg"),
        ("zinc", "Zinc", "mg"),
        ("copper", "Copper", "mg"),
        ("manganese", "Manganese", "mg"),
        ("selenium", "Selenium", "mcg"),
        ("iodine", "Iodine", "mcg"),
        ("chloride", "Chloride", "mg"),
        ("fluoride", "Fluoride", "mg"),
        ("chromium", "Chromium", "mcg"),
        ("molybdenum", "Molybdenum", "mcg"),
    ]

    private static let otherFields: [(key: String, label: String, unit: String)] = [
        ("choline", "Choline", "mg"),
        ("caffeine", "Caffeine", "mg"),
        ("water", "Water", "mL"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    foodInfoSection
                    macroSection
                    microSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(Cal.bg)
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Cal.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveEntry()
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .tint(Cal.accent)
                    .disabled(val("calories").isEmpty && name.isEmpty)
                }
            }
            .onAppear {
                populateFromScan()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    private var foodInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FOOD INFO")
                .font(.label())
                .tracking(2)
                .foregroundStyle(Cal.textTertiary)

            formField("Name", text: $name, placeholder: "What did you eat?")
            formField("Serving", text: $servingSize, placeholder: "e.g. 1 cup, 28g")
        }
        .glassCard()
    }

    private var macroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MACRONUTRIENTS")
                .font(.label())
                .tracking(2)
                .foregroundStyle(Cal.textTertiary)

            nutrientField("Calories", key: "calories", unit: "kcal")

            HStack(spacing: 8) {
                compactField("Protein", key: "protein", unit: "g", color: Cal.protein)
                compactField("Carbs", key: "totalCarbohydrates", unit: "g", color: Cal.carbs)
                compactField("Fat", key: "totalFat", unit: "g", color: Cal.fat)
            }

            ForEach(Self.macroFields, id: \.key) { field in
                nutrientField(field.label, key: field.key, unit: field.unit)
            }
        }
        .glassCard()
    }

    private var microSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.4)) {
                    showMicros.toggle()
                }
            } label: {
                HStack {
                    Text("MICRONUTRIENTS")
                        .font(.label())
                        .tracking(2)
                        .foregroundStyle(Cal.textTertiary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Cal.textTertiary)
                        .rotationEffect(.degrees(showMicros ? 90 : 0))
                }
            }

            if showMicros {
                microContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassCard()
    }

    private var microContent: some View {
        VStack(spacing: 12) {
            microHeader("Vitamins", color: Cal.vitaminFat)
            ForEach(Self.vitaminFields, id: \.key) { field in
                nutrientField(field.label, key: field.key, unit: field.unit)
            }
            microHeader("Minerals", color: Cal.mineral)
            ForEach(Self.mineralFields, id: \.key) { field in
                nutrientField(field.label, key: field.key, unit: field.unit)
            }
            microHeader("Other", color: Cal.accent)
            ForEach(Self.otherFields, id: \.key) { field in
                nutrientField(field.label, key: field.key, unit: field.unit)
            }
        }
    }

    // MARK: - Form Components

    private func formField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Cal.textTertiary)
            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .foregroundStyle(Cal.textPrimary)
                .padding(12)
                .background(Cal.bgSubtle, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func nutrientField(_ label: String, key: String, unit: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Cal.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                TextField("0", text: binding(for: key))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.mono(14))
                    .foregroundStyle(Cal.textPrimary)
                    .frame(width: 64)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(Cal.bgSubtle, in: RoundedRectangle(cornerRadius: 8))

                Text(unit)
                    .font(.mono(11))
                    .foregroundStyle(Cal.textTertiary)
                    .frame(width: 34, alignment: .leading)
            }
        }
    }

    private func compactField(_ label: String, key: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Cal.textTertiary)
            }
            ZStack(alignment: .trailing) {
                TextField("0", text: binding(for: key))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Cal.textPrimary)
                    .padding(.horizontal, 16)

                Text(unit)
                    .font(.mono(10))
                    .foregroundStyle(Cal.textTertiary)
                    .padding(.trailing, 8)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Cal.bgSubtle, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func microHeader(_ title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1)
                .fill(color)
                .frame(width: 3, height: 12)
            Text(title.uppercased())
                .font(.label())
                .tracking(1)
                .foregroundStyle(Cal.textTertiary)
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { values[key, default: ""] },
            set: { values[key] = $0 }
        )
    }

    private func val(_ key: String) -> String {
        values[key, default: ""]
    }

    private func num(_ key: String) -> Double {
        Double(values[key, default: ""]) ?? 0
    }

    // MARK: - Data

    private func populateFromScan() {
        guard let data = scannedData else { return }
        for (key, value) in data {
            values[key] = formatValue(value)
        }

        let microKeys = Self.vitaminFields.map(\.key) + Self.mineralFields.map(\.key) + Self.otherFields.map(\.key)
        if microKeys.contains(where: { data[$0] != nil && data[$0]! > 0 }) {
            showMicros = true
        }
    }

    private func formatValue(_ value: Double) -> String {
        if value == value.rounded() { return "\(Int(value))" }
        return String(format: "%.1f", value)
    }

    private func saveEntry() {
        let entry = FoodEntry(
            name: name,
            date: .now,
            servingSize: servingSize,
            calories: num("calories"),
            totalFat: num("totalFat"),
            saturatedFat: num("saturatedFat"),
            transFat: num("transFat"),
            cholesterol: num("cholesterol"),
            sodium: num("sodium"),
            totalCarbohydrates: num("totalCarbohydrates"),
            dietaryFiber: num("dietaryFiber"),
            totalSugars: num("totalSugars"),
            addedSugars: num("addedSugars"),
            protein: num("protein"),
            vitaminA: num("vitaminA"),
            vitaminD: num("vitaminD"),
            vitaminE: num("vitaminE"),
            vitaminK: num("vitaminK"),
            vitaminC: num("vitaminC"),
            thiamine: num("thiamine"),
            riboflavin: num("riboflavin"),
            niacin: num("niacin"),
            pantothenicAcid: num("pantothenicAcid"),
            vitaminB6: num("vitaminB6"),
            biotin: num("biotin"),
            folate: num("folate"),
            vitaminB12: num("vitaminB12"),
            calcium: num("calcium"),
            phosphorus: num("phosphorus"),
            magnesium: num("magnesium"),
            potassium: num("potassium"),
            chloride: num("chloride"),
            iron: num("iron"),
            zinc: num("zinc"),
            copper: num("copper"),
            manganese: num("manganese"),
            selenium: num("selenium"),
            iodine: num("iodine"),
            fluoride: num("fluoride"),
            chromium: num("chromium"),
            molybdenum: num("molybdenum"),
            choline: num("choline"),
            polyunsaturatedFat: num("polyunsaturatedFat"),
            monounsaturatedFat: num("monounsaturatedFat"),
            caffeine: num("caffeine"),
            water: num("water")
        )
        modelContext.insert(entry)
        WidgetCenter.shared.reloadAllTimelines()
        onSave?()

        Task {
            if let hkID = await healthKit.saveFoodEntry(entry) {
                entry.healthKitID = hkID
            }
        }
    }
}
