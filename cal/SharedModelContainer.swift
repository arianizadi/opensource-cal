import Foundation
import SwiftData

enum SharedModelContainer {
    static let appGroupID = "group.com.ariandev.cal"

    static var container: ModelContainer = {
        let schema = Schema([FoodEntry.self])
        let config = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create shared ModelContainer: \(error)")
        }
    }()

    static var storeURL: URL {
        let base = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("cal.store")
    }
}
