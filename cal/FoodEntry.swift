import Foundation
import SwiftData

// MARK: - Meal Template

@Model
final class MealTemplate {
    var name: String
    var servingSize: String
    var calories: Double
    var totalFat: Double
    var saturatedFat: Double
    var transFat: Double
    var cholesterol: Double
    var sodium: Double
    var totalCarbohydrates: Double
    var dietaryFiber: Double
    var totalSugars: Double
    var addedSugars: Double
    var protein: Double
    var vitaminA: Double
    var vitaminD: Double
    var vitaminE: Double
    var vitaminK: Double
    var vitaminC: Double
    var thiamine: Double
    var riboflavin: Double
    var niacin: Double
    var pantothenicAcid: Double
    var vitaminB6: Double
    var biotin: Double
    var folate: Double
    var vitaminB12: Double
    var calcium: Double
    var phosphorus: Double
    var magnesium: Double
    var potassium: Double
    var chloride: Double
    var iron: Double
    var zinc: Double
    var copper: Double
    var manganese: Double
    var selenium: Double
    var iodine: Double
    var fluoride: Double
    var chromium: Double
    var molybdenum: Double
    var choline: Double
    var polyunsaturatedFat: Double
    var monounsaturatedFat: Double
    var caffeine: Double
    var water: Double
    var timesUsed: Int
    var lastUsed: Date?

    init(from entry: FoodEntry) {
        self.name = entry.name
        self.servingSize = entry.servingSize
        self.calories = entry.calories
        self.totalFat = entry.totalFat
        self.saturatedFat = entry.saturatedFat
        self.transFat = entry.transFat
        self.cholesterol = entry.cholesterol
        self.sodium = entry.sodium
        self.totalCarbohydrates = entry.totalCarbohydrates
        self.dietaryFiber = entry.dietaryFiber
        self.totalSugars = entry.totalSugars
        self.addedSugars = entry.addedSugars
        self.protein = entry.protein
        self.vitaminA = entry.vitaminA
        self.vitaminD = entry.vitaminD
        self.vitaminE = entry.vitaminE
        self.vitaminK = entry.vitaminK
        self.vitaminC = entry.vitaminC
        self.thiamine = entry.thiamine
        self.riboflavin = entry.riboflavin
        self.niacin = entry.niacin
        self.pantothenicAcid = entry.pantothenicAcid
        self.vitaminB6 = entry.vitaminB6
        self.biotin = entry.biotin
        self.folate = entry.folate
        self.vitaminB12 = entry.vitaminB12
        self.calcium = entry.calcium
        self.phosphorus = entry.phosphorus
        self.magnesium = entry.magnesium
        self.potassium = entry.potassium
        self.chloride = entry.chloride
        self.iron = entry.iron
        self.zinc = entry.zinc
        self.copper = entry.copper
        self.manganese = entry.manganese
        self.selenium = entry.selenium
        self.iodine = entry.iodine
        self.fluoride = entry.fluoride
        self.chromium = entry.chromium
        self.molybdenum = entry.molybdenum
        self.choline = entry.choline
        self.polyunsaturatedFat = entry.polyunsaturatedFat
        self.monounsaturatedFat = entry.monounsaturatedFat
        self.caffeine = entry.caffeine
        self.water = entry.water
        self.timesUsed = 0
        self.lastUsed = nil
    }

    func toFoodEntry() -> FoodEntry {
        FoodEntry(
            name: name, servingSize: servingSize,
            calories: calories, totalFat: totalFat, saturatedFat: saturatedFat,
            transFat: transFat, cholesterol: cholesterol, sodium: sodium,
            totalCarbohydrates: totalCarbohydrates, dietaryFiber: dietaryFiber,
            totalSugars: totalSugars, addedSugars: addedSugars, protein: protein,
            vitaminA: vitaminA, vitaminD: vitaminD, vitaminE: vitaminE,
            vitaminK: vitaminK, vitaminC: vitaminC, thiamine: thiamine,
            riboflavin: riboflavin, niacin: niacin, pantothenicAcid: pantothenicAcid,
            vitaminB6: vitaminB6, biotin: biotin, folate: folate, vitaminB12: vitaminB12,
            calcium: calcium, phosphorus: phosphorus, magnesium: magnesium,
            potassium: potassium, chloride: chloride, iron: iron, zinc: zinc,
            copper: copper, manganese: manganese, selenium: selenium,
            iodine: iodine, fluoride: fluoride, chromium: chromium,
            molybdenum: molybdenum, choline: choline,
            polyunsaturatedFat: polyunsaturatedFat, monounsaturatedFat: monounsaturatedFat,
            caffeine: caffeine, water: water
        )
    }
}

// MARK: - Food Entry

@Model
final class FoodEntry {
    var name: String
    var date: Date
    var servingSize: String
    var healthKitID: String?

    // Macronutrients
    var calories: Double
    var totalFat: Double
    var saturatedFat: Double
    var transFat: Double
    var cholesterol: Double
    var sodium: Double
    var totalCarbohydrates: Double
    var dietaryFiber: Double
    var totalSugars: Double
    var addedSugars: Double
    var protein: Double

    // Vitamins - Fat Soluble
    var vitaminA: Double
    var vitaminD: Double
    var vitaminE: Double
    var vitaminK: Double

    // Vitamins - Water Soluble
    var vitaminC: Double
    var thiamine: Double      // B1
    var riboflavin: Double    // B2
    var niacin: Double        // B3
    var pantothenicAcid: Double // B5
    var vitaminB6: Double
    var biotin: Double        // B7
    var folate: Double        // B9
    var vitaminB12: Double

    // Macrominerals
    var calcium: Double
    var phosphorus: Double
    var magnesium: Double
    var potassium: Double
    var chloride: Double

    // Trace Minerals
    var iron: Double
    var zinc: Double
    var copper: Double
    var manganese: Double
    var selenium: Double
    var iodine: Double
    var fluoride: Double
    var chromium: Double
    var molybdenum: Double

    // Other
    var choline: Double
    var polyunsaturatedFat: Double
    var monounsaturatedFat: Double
    var caffeine: Double
    var water: Double

    init(
        name: String = "",
        date: Date = .now,
        servingSize: String = "",
        calories: Double = 0,
        totalFat: Double = 0,
        saturatedFat: Double = 0,
        transFat: Double = 0,
        cholesterol: Double = 0,
        sodium: Double = 0,
        totalCarbohydrates: Double = 0,
        dietaryFiber: Double = 0,
        totalSugars: Double = 0,
        addedSugars: Double = 0,
        protein: Double = 0,
        vitaminA: Double = 0,
        vitaminD: Double = 0,
        vitaminE: Double = 0,
        vitaminK: Double = 0,
        vitaminC: Double = 0,
        thiamine: Double = 0,
        riboflavin: Double = 0,
        niacin: Double = 0,
        pantothenicAcid: Double = 0,
        vitaminB6: Double = 0,
        biotin: Double = 0,
        folate: Double = 0,
        vitaminB12: Double = 0,
        calcium: Double = 0,
        phosphorus: Double = 0,
        magnesium: Double = 0,
        potassium: Double = 0,
        chloride: Double = 0,
        iron: Double = 0,
        zinc: Double = 0,
        copper: Double = 0,
        manganese: Double = 0,
        selenium: Double = 0,
        iodine: Double = 0,
        fluoride: Double = 0,
        chromium: Double = 0,
        molybdenum: Double = 0,
        choline: Double = 0,
        polyunsaturatedFat: Double = 0,
        monounsaturatedFat: Double = 0,
        caffeine: Double = 0,
        water: Double = 0
    ) {
        self.name = name
        self.date = date
        self.servingSize = servingSize
        self.calories = calories
        self.totalFat = totalFat
        self.saturatedFat = saturatedFat
        self.transFat = transFat
        self.cholesterol = cholesterol
        self.sodium = sodium
        self.totalCarbohydrates = totalCarbohydrates
        self.dietaryFiber = dietaryFiber
        self.totalSugars = totalSugars
        self.addedSugars = addedSugars
        self.protein = protein
        self.vitaminA = vitaminA
        self.vitaminD = vitaminD
        self.vitaminE = vitaminE
        self.vitaminK = vitaminK
        self.vitaminC = vitaminC
        self.thiamine = thiamine
        self.riboflavin = riboflavin
        self.niacin = niacin
        self.pantothenicAcid = pantothenicAcid
        self.vitaminB6 = vitaminB6
        self.biotin = biotin
        self.folate = folate
        self.vitaminB12 = vitaminB12
        self.calcium = calcium
        self.phosphorus = phosphorus
        self.magnesium = magnesium
        self.potassium = potassium
        self.chloride = chloride
        self.iron = iron
        self.zinc = zinc
        self.copper = copper
        self.manganese = manganese
        self.selenium = selenium
        self.iodine = iodine
        self.fluoride = fluoride
        self.chromium = chromium
        self.molybdenum = molybdenum
        self.choline = choline
        self.polyunsaturatedFat = polyunsaturatedFat
        self.monounsaturatedFat = monounsaturatedFat
        self.caffeine = caffeine
        self.water = water
    }
}
