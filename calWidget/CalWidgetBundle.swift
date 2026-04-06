import WidgetKit
import SwiftUI

@main
struct CalWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalDailyWidget()
        CalLockScreenWidget()
    }
}
