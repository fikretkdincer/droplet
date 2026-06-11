import SwiftUI

struct TimerBucketDroplet: View {
    let fill: Double
    let fillColor: Color
    let rimColor: Color
    let isRunning: Bool
    let pausedOpacity: Double

    var body: some View {
        ZStack {
            Image(systemName: "drop.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(rimColor.opacity(0.12))

            GeometryReader { proxy in
                let height = proxy.size.height
                let fillHeight = height * min(max(fill, 0), 1)

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ZStack(alignment: .top) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        fillColor.opacity(0.74),
                                        fillColor,
                                        Color.white.opacity(0.28)
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )

                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: proxy.size.width * 0.74, height: 5)
                            .offset(y: -2)
                    }
                    .frame(height: fillHeight)
                }
            }
            .mask(
                Image(systemName: "drop.fill")
                    .resizable()
                    .scaledToFit()
            )

            Image(systemName: "drop.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.clear)
                .overlay(
                    Image(systemName: "drop")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(rimColor.opacity(0.32))
                )
                .shadow(color: fillColor.opacity(isRunning ? 0.42 : 0.16), radius: isRunning ? 8 : 3, x: 0, y: 0)
                .opacity(pausedOpacity)
        }
    }
}

struct TimerBucketWidgetBackground: View {
    let theme: Theme
    var showsGradient: Bool = true

    var body: some View {
        ZStack {
            theme.backgroundColor

            if showsGradient {
                LinearGradient(
                    colors: [
                        theme.textColor.opacity(themeIsDark ? 0.10 : 0.16),
                        .clear,
                        theme.workAccent.opacity(themeIsDark ? 0.18 : 0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
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
