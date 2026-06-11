import SwiftUI
import WidgetKit

@main
struct DropletWidgetBundle: WidgetBundle {
    var body: some Widget {
        DropletTodayWidget()
        DropletStreakGardenWidget()
        DropletTimerBucketWidget()
    }
}
