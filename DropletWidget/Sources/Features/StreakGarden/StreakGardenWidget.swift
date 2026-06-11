import SwiftUI
import WidgetKit

struct DropletStreakGardenWidget: Widget {
    let kind = DropletWidgetKind.streakGarden

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakGardenProvider()) { entry in
            StreakGardenWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    StreakGardenWidgetBackground(
                        theme: Theme(rawValue: entry.themeRawValue) ?? .dark,
                        showsGradient: entry.gradientEnabled
                    )
                }
        }
        .configurationDisplayName("Droplet Streak Garden")
        .description("A monthly droplet heatmap that shines with your selected theme and turns gold after 125% of your goal.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

#if DEBUG
#Preview(as: .systemMedium) {
    DropletStreakGardenWidget()
} timeline: {
    StreakGardenEntry.preview
}
#endif
