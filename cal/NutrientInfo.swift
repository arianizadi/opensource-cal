import Foundation

struct NutrientInfo: Identifiable {
    let id = UUID()
    let name: String
    let unit: String
    let dailyValue: Double
    let category: NutrientCategory
    let keyPath: KeyPath<FoodEntry, Double>

    var shortName: String {
        switch name {
        case "Pantothenic Acid": return "B5"
        case "Total Carbohydrates": return "Carbs"
        case "Total Fat": return "Fat"
        case "Dietary Fiber": return "Fiber"
        case "Total Sugars": return "Sugars"
        case "Added Sugars": return "Added Sugar"
        case "Polyunsaturated Fat": return "Polyunsat. Fat"
        case "Monounsaturated Fat": return "Monounsat. Fat"
        default: return name
        }
    }
}

enum NutrientCategory: String, CaseIterable {
    case macro = "Macronutrients"
    case fatSolubleVitamin = "Fat-Soluble Vitamins"
    case waterSolubleVitamin = "Water-Soluble Vitamins"
    case macromineral = "Macrominerals"
    case traceMineral = "Trace Minerals"
    case other = "Other"
}

struct NutrientDatabase {
    static let all: [NutrientInfo] = macros + fatSolubleVitamins + waterSolubleVitamins + macrominerals + traceMinerals + others

    static let macros: [NutrientInfo] = [
        NutrientInfo(name: "Calories", unit: "kcal", dailyValue: 2000, category: .macro, keyPath: \.calories),
        NutrientInfo(name: "Total Fat", unit: "g", dailyValue: 78, category: .macro, keyPath: \.totalFat),
        NutrientInfo(name: "Saturated Fat", unit: "g", dailyValue: 20, category: .macro, keyPath: \.saturatedFat),
        NutrientInfo(name: "Trans Fat", unit: "g", dailyValue: 2, category: .macro, keyPath: \.transFat),
        NutrientInfo(name: "Polyunsaturated Fat", unit: "g", dailyValue: 22, category: .macro, keyPath: \.polyunsaturatedFat),
        NutrientInfo(name: "Monounsaturated Fat", unit: "g", dailyValue: 22, category: .macro, keyPath: \.monounsaturatedFat),
        NutrientInfo(name: "Cholesterol", unit: "mg", dailyValue: 300, category: .macro, keyPath: \.cholesterol),
        NutrientInfo(name: "Sodium", unit: "mg", dailyValue: 2300, category: .macro, keyPath: \.sodium),
        NutrientInfo(name: "Total Carbohydrates", unit: "g", dailyValue: 275, category: .macro, keyPath: \.totalCarbohydrates),
        NutrientInfo(name: "Dietary Fiber", unit: "g", dailyValue: 28, category: .macro, keyPath: \.dietaryFiber),
        NutrientInfo(name: "Total Sugars", unit: "g", dailyValue: 50, category: .macro, keyPath: \.totalSugars),
        NutrientInfo(name: "Added Sugars", unit: "g", dailyValue: 50, category: .macro, keyPath: \.addedSugars),
        NutrientInfo(name: "Protein", unit: "g", dailyValue: 50, category: .macro, keyPath: \.protein),
    ]

    static let fatSolubleVitamins: [NutrientInfo] = [
        NutrientInfo(name: "Vitamin A", unit: "mcg", dailyValue: 900, category: .fatSolubleVitamin, keyPath: \.vitaminA),
        NutrientInfo(name: "Vitamin D", unit: "mcg", dailyValue: 20, category: .fatSolubleVitamin, keyPath: \.vitaminD),
        NutrientInfo(name: "Vitamin E", unit: "mg", dailyValue: 15, category: .fatSolubleVitamin, keyPath: \.vitaminE),
        NutrientInfo(name: "Vitamin K", unit: "mcg", dailyValue: 120, category: .fatSolubleVitamin, keyPath: \.vitaminK),
    ]

    static let waterSolubleVitamins: [NutrientInfo] = [
        NutrientInfo(name: "Vitamin C", unit: "mg", dailyValue: 90, category: .waterSolubleVitamin, keyPath: \.vitaminC),
        NutrientInfo(name: "Thiamine", unit: "mg", dailyValue: 1.2, category: .waterSolubleVitamin, keyPath: \.thiamine),
        NutrientInfo(name: "Riboflavin", unit: "mg", dailyValue: 1.3, category: .waterSolubleVitamin, keyPath: \.riboflavin),
        NutrientInfo(name: "Niacin", unit: "mg", dailyValue: 16, category: .waterSolubleVitamin, keyPath: \.niacin),
        NutrientInfo(name: "Pantothenic Acid", unit: "mg", dailyValue: 5, category: .waterSolubleVitamin, keyPath: \.pantothenicAcid),
        NutrientInfo(name: "Vitamin B6", unit: "mg", dailyValue: 1.7, category: .waterSolubleVitamin, keyPath: \.vitaminB6),
        NutrientInfo(name: "Biotin", unit: "mcg", dailyValue: 30, category: .waterSolubleVitamin, keyPath: \.biotin),
        NutrientInfo(name: "Folate", unit: "mcg", dailyValue: 400, category: .waterSolubleVitamin, keyPath: \.folate),
        NutrientInfo(name: "Vitamin B12", unit: "mcg", dailyValue: 2.4, category: .waterSolubleVitamin, keyPath: \.vitaminB12),
    ]

    static let macrominerals: [NutrientInfo] = [
        NutrientInfo(name: "Calcium", unit: "mg", dailyValue: 1300, category: .macromineral, keyPath: \.calcium),
        NutrientInfo(name: "Phosphorus", unit: "mg", dailyValue: 1250, category: .macromineral, keyPath: \.phosphorus),
        NutrientInfo(name: "Magnesium", unit: "mg", dailyValue: 420, category: .macromineral, keyPath: \.magnesium),
        NutrientInfo(name: "Potassium", unit: "mg", dailyValue: 4700, category: .macromineral, keyPath: \.potassium),
        NutrientInfo(name: "Chloride", unit: "mg", dailyValue: 2300, category: .macromineral, keyPath: \.chloride),
    ]

    static let traceMinerals: [NutrientInfo] = [
        NutrientInfo(name: "Iron", unit: "mg", dailyValue: 18, category: .traceMineral, keyPath: \.iron),
        NutrientInfo(name: "Zinc", unit: "mg", dailyValue: 11, category: .traceMineral, keyPath: \.zinc),
        NutrientInfo(name: "Copper", unit: "mg", dailyValue: 0.9, category: .traceMineral, keyPath: \.copper),
        NutrientInfo(name: "Manganese", unit: "mg", dailyValue: 2.3, category: .traceMineral, keyPath: \.manganese),
        NutrientInfo(name: "Selenium", unit: "mcg", dailyValue: 55, category: .traceMineral, keyPath: \.selenium),
        NutrientInfo(name: "Iodine", unit: "mcg", dailyValue: 150, category: .traceMineral, keyPath: \.iodine),
        NutrientInfo(name: "Fluoride", unit: "mg", dailyValue: 4, category: .traceMineral, keyPath: \.fluoride),
        NutrientInfo(name: "Chromium", unit: "mcg", dailyValue: 35, category: .traceMineral, keyPath: \.chromium),
        NutrientInfo(name: "Molybdenum", unit: "mcg", dailyValue: 45, category: .traceMineral, keyPath: \.molybdenum),
    ]

    static let others: [NutrientInfo] = [
        NutrientInfo(name: "Choline", unit: "mg", dailyValue: 550, category: .other, keyPath: \.choline),
        NutrientInfo(name: "Caffeine", unit: "mg", dailyValue: 400, category: .other, keyPath: \.caffeine),
        NutrientInfo(name: "Water", unit: "mL", dailyValue: 3700, category: .other, keyPath: \.water),
    ]

    static func totalForEntries(_ entries: [FoodEntry], nutrient: NutrientInfo) -> Double {
        entries.reduce(0) { $0 + $1[keyPath: nutrient.keyPath] }
    }

    static func percentDV(_ value: Double, nutrient: NutrientInfo) -> Double {
        guard nutrient.dailyValue > 0 else { return 0 }
        return value / nutrient.dailyValue
    }
}
