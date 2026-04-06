import SwiftUI
import SwiftData

@main
struct calWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchDashboardView()
        }
        .modelContainer(SharedModelContainer.container)
    }
}
