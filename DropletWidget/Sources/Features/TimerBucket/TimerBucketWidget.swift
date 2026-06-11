import AppIntents
import SwiftUI
import WidgetKit

struct TimerBucketWidgetView: View {
    let entry: TimerBucketEntry

    private var theme: Theme {
        Theme(rawValue: entry.themeRawValue) ?? .dark
    }

    var body: some View {
        TimerBucketDroplet(
            fill: entry.liveFill(at: entry.date),
            fillColor: fillColor,
            rimColor: theme.textColor,
            isRunning: entry.isRunning,
            pausedOpacity: entry.pausedBlinkOpacity(at: entry.date)
        )
        .frame(width: 116, height: 132)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .widgetURL(DropletWidgetDeepLink.openURL)
    }

    private var fillColor: Color {
        entry.isBreak ? theme.breakAccent : theme.workAccent
    }

    private var themeIsDark: Bool {
        switch theme {
        case .light, .beige, .linen, .poppy, .blossom, .frog:
            return false
        default:
            return true
        }
    }
}

struct DropletTimerBucketWidget: Widget {
    let kind = DropletWidgetKind.timerBucket

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimerBucketProvider()) { entry in
            TimerBucketWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    TimerBucketWidgetBackground(
                        theme: Theme(rawValue: entry.themeRawValue) ?? .dark,
                        showsGradient: entry.gradientEnabled
                    )
                }
        }
        .configurationDisplayName("Droplet Timer Bucket")
        .description("A small droplet timer that fills through focus and drains through breaks.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

#if DEBUG
#Preview(as: .systemSmall) {
    DropletTimerBucketWidget()
} timeline: {
    TimerBucketEntry.preview
}
#endif
