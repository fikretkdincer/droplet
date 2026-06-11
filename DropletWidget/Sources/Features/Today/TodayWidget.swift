import SwiftUI
import WidgetKit

struct DropletTodayWidget: Widget {
    let kind = DropletWidgetKind.today

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayWidgetProvider()) { entry in
            TodayWidgetView(entry: entry)
                .widgetURL(DropletWidgetDeepLink.openURL)
                .containerBackground(for: .widget) {
                    TimerBucketWidgetBackground(
                        theme: Theme(rawValue: entry.themeRawValue) ?? .dark,
                        showsGradient: entry.gradientEnabled
                    )
                }
        }
        .configurationDisplayName("Droplet Today")
        .description("A themed glance at today's focus minutes, daily goal progress, and current streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

#if DEBUG
#Preview(as: .systemSmall) {
    DropletTodayWidget()
} timeline: {
    TodayWidgetEntry.preview
}

#Preview(as: .systemMedium) {
    DropletTodayWidget()
} timeline: {
    TodayWidgetEntry.preview
}
#endif
