import Foundation
import SwiftData

@Model
final class FoodEntry {
    var name: String
    var date: Date
    var servingSize: String

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
        fluoride: Double = 0
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
    }
}
