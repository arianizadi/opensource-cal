import Foundation
import HealthKit
import Observation

@MainActor
@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()
    var isAuthorized = false
    var isAvailable: Bool

    private init() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }

    // All nutrition types we want to write
    private var allNutritionTypes: Set<HKSampleType> {
        let identifiers: [HKQuantityTypeIdentifier] = [
            .dietaryEnergyConsumed,
            .dietaryFatTotal,
            .dietaryFatSaturated,
            .dietaryCholesterol,
            .dietarySodium,
            .dietaryCarbohydrates,
            .dietaryFiber,
            .dietarySugar,
            .dietaryProtein,
            .dietaryVitaminA,
            .dietaryVitaminC,
            .dietaryVitaminD,
            .dietaryVitaminE,
            .dietaryVitaminK,
            .dietaryThiamin,
            .dietaryRiboflavin,
            .dietaryNiacin,
            .dietaryPantothenicAcid,
            .dietaryVitaminB6,
            .dietaryBiotin,
            .dietaryFolate,
            .dietaryVitaminB12,
            .dietaryCalcium,
            .dietaryPhosphorus,
            .dietaryMagnesium,
            .dietaryPotassium,
            .dietaryChloride,
            .dietaryIron,
            .dietaryZinc,
            .dietaryCopper,
            .dietaryManganese,
            .dietarySelenium,
            .dietaryIodine,
        ]
        var types = Set<HKSampleType>()
        for id in identifiers {
            if let type = HKQuantityType.quantityType(forIdentifier: id) {
                types.insert(type)
            }
        }
        if let foodType = HKCorrelationType.correlationType(forIdentifier: .food) {
            types.insert(foodType)
        }
        return types
    }

    func requestAuthorization() async {
        guard isAvailable else { return }

        do {
            try await healthStore.requestAuthorization(toShare: allNutritionTypes, read: [])
            isAuthorized = true
        } catch {
            print("HealthKit authorization failed: \(error)")
        }
    }

    func saveFoodEntry(_ entry: FoodEntry) async {
        guard isAvailable, isAuthorized else { return }

        let date = entry.date
        var samples: [HKQuantitySample] = []

        func add(_ identifier: HKQuantityTypeIdentifier, value: Double, unit: HKUnit) {
            guard value > 0, let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return }
            let quantity = HKQuantity(unit: unit, doubleValue: value)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
            samples.append(sample)
        }

        let gram = HKUnit.gram()
        let mg = HKUnit.gramUnit(with: .milli)
        let mcg = HKUnit.gramUnit(with: .micro)
        let kcal = HKUnit.kilocalorie()

        // Macros
        add(.dietaryEnergyConsumed, value: entry.calories, unit: kcal)
        add(.dietaryFatTotal, value: entry.totalFat, unit: gram)
        add(.dietaryFatSaturated, value: entry.saturatedFat, unit: gram)
        add(.dietaryCholesterol, value: entry.cholesterol, unit: mg)
        add(.dietarySodium, value: entry.sodium, unit: mg)
        add(.dietaryCarbohydrates, value: entry.totalCarbohydrates, unit: gram)
        add(.dietaryFiber, value: entry.dietaryFiber, unit: gram)
        add(.dietarySugar, value: entry.totalSugars, unit: gram)
        add(.dietaryProtein, value: entry.protein, unit: gram)

        // Vitamins
        add(.dietaryVitaminA, value: entry.vitaminA, unit: mcg)
        add(.dietaryVitaminC, value: entry.vitaminC, unit: mg)
        add(.dietaryVitaminD, value: entry.vitaminD, unit: mcg)
        add(.dietaryVitaminE, value: entry.vitaminE, unit: mg)
        add(.dietaryVitaminK, value: entry.vitaminK, unit: mcg)
        add(.dietaryThiamin, value: entry.thiamine, unit: mg)
        add(.dietaryRiboflavin, value: entry.riboflavin, unit: mg)
        add(.dietaryNiacin, value: entry.niacin, unit: mg)
        add(.dietaryPantothenicAcid, value: entry.pantothenicAcid, unit: mg)
        add(.dietaryVitaminB6, value: entry.vitaminB6, unit: mg)
        add(.dietaryBiotin, value: entry.biotin, unit: mcg)
        add(.dietaryFolate, value: entry.folate, unit: mcg)
        add(.dietaryVitaminB12, value: entry.vitaminB12, unit: mcg)

        // Minerals
        add(.dietaryCalcium, value: entry.calcium, unit: mg)
        add(.dietaryPhosphorus, value: entry.phosphorus, unit: mg)
        add(.dietaryMagnesium, value: entry.magnesium, unit: mg)
        add(.dietaryPotassium, value: entry.potassium, unit: mg)
        add(.dietaryChloride, value: entry.chloride, unit: mg)
        add(.dietaryIron, value: entry.iron, unit: mg)
        add(.dietaryZinc, value: entry.zinc, unit: mg)
        add(.dietaryCopper, value: entry.copper, unit: mg)
        add(.dietaryManganese, value: entry.manganese, unit: mg)
        add(.dietarySelenium, value: entry.selenium, unit: mcg)
        add(.dietaryIodine, value: entry.iodine, unit: mcg)

        guard !samples.isEmpty else { return }

        // Create a food correlation to group all nutritional samples
        guard let foodType = HKCorrelationType.correlationType(forIdentifier: .food) else { return }
        var metadata: [String: Any] = [:]
        if !entry.name.isEmpty {
            metadata[HKMetadataKeyFoodType] = entry.name
        }

        let foodCorrelation = HKCorrelation(
            type: foodType,
            start: date,
            end: date,
            objects: Set(samples),
            metadata: metadata.isEmpty ? nil : metadata
        )

        do {
            try await healthStore.save(foodCorrelation)
        } catch {
            print("Failed to save to HealthKit: \(error)")
        }
    }
}
