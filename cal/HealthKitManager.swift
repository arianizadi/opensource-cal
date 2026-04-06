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
            .dietaryFatPolyunsaturated,
            .dietaryFatMonounsaturated,
            .dietaryChromium,
            .dietaryMolybdenum,
            .dietaryCaffeine,
            .dietaryWater,
        ]
        var types = Set<HKSampleType>()
        for id in identifiers {
            if let type = HKQuantityType.quantityType(forIdentifier: id) {
                types.insert(type)
            }
        }
        return types
    }

    // Types we want to read (body measurements)
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        if let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMass)
        }
        return types
    }

    func requestAuthorization() async {
        guard isAvailable else { return }

        do {
            try await healthStore.requestAuthorization(toShare: allNutritionTypes, read: readTypes)
            isAuthorized = true
        } catch {
            print("HealthKit authorization failed: \(error)")
        }
    }

    // MARK: - Weight Reading

    struct WeightSample: Identifiable {
        let id = UUID()
        let date: Date
        let kg: Double
    }

    /// Fetch weight samples from HealthKit for the given number of days
    func fetchWeightSamples(days: Int) async -> [WeightSample] {
        guard isAvailable else { return [] }

        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return [] }

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                guard let samples = results as? [HKQuantitySample], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                let weightSamples = samples.map { sample in
                    WeightSample(
                        date: sample.startDate,
                        kg: sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                    )
                }
                continuation.resume(returning: weightSamples)
            }
            healthStore.execute(query)
        }
    }

    /// Returns the HealthKit UUID string so we can delete later
    func saveFoodEntry(_ entry: FoodEntry) async -> String? {
        guard isAvailable, isAuthorized else { return nil }

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
        add(.dietaryFatPolyunsaturated, value: entry.polyunsaturatedFat, unit: gram)
        add(.dietaryFatMonounsaturated, value: entry.monounsaturatedFat, unit: gram)
        add(.dietaryChromium, value: entry.chromium, unit: mcg)
        add(.dietaryMolybdenum, value: entry.molybdenum, unit: mcg)
        add(.dietaryCaffeine, value: entry.caffeine, unit: mg)
        add(.dietaryWater, value: entry.water, unit: HKUnit.literUnit(with: .milli))

        guard !samples.isEmpty else { return nil }

        // Create a food correlation to group all nutritional samples
        guard let foodType = HKCorrelationType.correlationType(forIdentifier: .food) else { return nil }
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
            return foodCorrelation.uuid.uuidString
        } catch {
            print("Failed to save to HealthKit: \(error)")
            return nil
        }
    }

    func deleteFoodEntry(healthKitID: String) async {
        guard isAvailable, isAuthorized else { return }
        guard let uuid = UUID(uuidString: healthKitID) else { return }

        guard let foodType = HKCorrelationType.correlationType(forIdentifier: .food) else { return }
        let predicate = HKQuery.predicateForObject(with: uuid)

        do {
            // Fetch the correlation first, then delete it and its child samples
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let query = HKCorrelationQuery(type: foodType, predicate: predicate, samplePredicates: nil) { _, results, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let correlation = results?.first else {
                        continuation.resume()
                        return
                    }
                    // Delete child samples and the correlation
                    let allObjects = Array(correlation.objects) + [correlation]
                    self.healthStore.delete(allObjects) { _, deleteError in
                        if let deleteError {
                            continuation.resume(throwing: deleteError)
                        } else {
                            continuation.resume()
                        }
                    }
                }
                healthStore.execute(query)
            }
        } catch {
            print("Failed to delete from HealthKit: \(error)")
        }
    }
}
