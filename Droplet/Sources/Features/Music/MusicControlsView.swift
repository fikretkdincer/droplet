import SwiftUI

struct MusicControlsView: View {
    @ObservedObject var musicManager = MusicManager.shared
    @ObservedObject var settings = SettingsManager.shared

    var isFullscreen = false
    var scale: CGFloat = 1

    var body: some View {
        HStack(spacing: 8 * scale) {
            if !musicManager.nowPlaying.displayText.isEmpty {
                Text(musicManager.nowPlaying.displayText)
                    .font(.system(size: 9 * scale))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 4)
            }

            if settings.showMusicControls {
                controls
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12 * scale) {
            Button(action: { musicManager.toggleShuffle() }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 10 * scale))
                    .foregroundColor(musicManager.isShuffling ? settings.selectedTheme.workAccent : settings.selectedTheme.textColor.opacity(0.5))
            }
            .buttonStyle(.plain)
            .help("Shuffle")

            Button(action: { musicManager.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 12 * scale))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
            }
            .buttonStyle(.plain)

            Button(action: { musicManager.togglePlayPause() }) {
                Image(systemName: musicManager.nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14 * scale))
                    .foregroundColor(settings.selectedTheme.textColor)
            }
            .buttonStyle(.plain)

            Button(action: { musicManager.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 12 * scale))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
            }
            .buttonStyle(.plain)

            Button(action: { musicManager.toggleRepeat() }) {
                Image(systemName: musicManager.repeatMode == .one ? "repeat.1" : "repeat")
                    .font(.system(size: 10 * scale))
                    .foregroundColor(musicManager.repeatMode != .off ? settings.selectedTheme.workAccent : settings.selectedTheme.textColor.opacity(0.5))
            }
            .buttonStyle(.plain)
            .help("Repeat")
        }
    }
}
