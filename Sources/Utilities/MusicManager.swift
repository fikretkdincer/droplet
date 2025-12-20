import Foundation
import AppKit

/// Supported music applications
enum MusicApp: String, CaseIterable, Identifiable {
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
    
    var id: String { rawValue }
}

/// Music playback state
struct NowPlaying: Equatable {
    let artist: String
    let title: String
    let isPlaying: Bool
    
    static let empty = NowPlaying(artist: "", title: "", isPlaying: false)
    
    var displayText: String {
        guard !artist.isEmpty || !title.isEmpty else { return "" }
        if artist.isEmpty { return title }
        if title.isEmpty { return artist }
        return "\(artist) - \(title)"
    }
    
    var hasContent: Bool {
        return !artist.isEmpty || !title.isEmpty
    }
}

// MARK: - MediaRemote Private Framework (for commands only)

private let mediaRemoteBundle: CFBundle? = {
    let path = "/System/Library/PrivateFrameworks/MediaRemote.framework"
    return CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: path))
}()

// Command types for MRMediaRemoteSendCommand
private let kMRTogglePlayPause: Int = 2
private let kMRNextTrack: Int = 4
private let kMRPreviousTrack: Int = 5

private typealias MRSendCommandType = @convention(c) (Int, AnyObject?) -> Bool

private func getMRSendCommand() -> MRSendCommandType? {
    guard let bundle = mediaRemoteBundle else { return nil }
    guard let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommand" as CFString) else { return nil }
    return unsafeBitCast(ptr, to: MRSendCommandType.self)
}

/// Controls system media playback
/// Uses MediaRemote for commands, DistributedNotificationCenter for now playing info
class MusicManager: ObservableObject {
    static let shared = MusicManager()
    
    @Published var nowPlaying: NowPlaying = .empty
    private var pollTimer: Timer?
    
    private init() {
        // Listen for Spotify playback state changes
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleSpotifyNotification(_:)),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )
        
        startPolling()
    }
    
    deinit {
        pollTimer?.invalidate()
        DistributedNotificationCenter.default().removeObserver(self)
    }
    
    @objc private func handleSpotifyNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        let artist = userInfo["Artist"] as? String ?? ""
        let title = userInfo["Name"] as? String ?? ""
        let state = userInfo["Player State"] as? String ?? ""
        
        DispatchQueue.main.async { [weak self] in
            let newPlaying = NowPlaying(
                artist: artist,
                title: title,
                isPlaying: state == "Playing"
            )
            if self?.nowPlaying != newPlaying {
                self?.nowPlaying = newPlaying
            }
        }
    }
    
    // MARK: - Polling (fallback for initial state)
    
    private func startPolling() {
        // Poll every 2 seconds as backup
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.fetchNowPlayingViaScript()
        }
        fetchNowPlayingViaScript() // Initial fetch
    }
    
    private func fetchNowPlayingViaScript() {
        // Use AppleScript only if we haven't received notification data
        guard nowPlaying == .empty else { return }
        
        let app = SettingsManager.shared.musicApp
        let appName = app == "Apple Music" ? "Music" : app
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let script = """
            tell application "System Events"
                if (name of processes) contains "\(appName)" then
                    tell application "\(appName)"
                        try
                            set trackName to name of current track
                            set artistName to artist of current track
                            set playState to (player state is playing)
                            return artistName & "|||" & trackName & "|||" & (playState as string)
                        on error
                            return "|||false"
                        end try
                    end tell
                else
                    return "|||false"
                end if
            end tell
            """
            
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script),
               let result = appleScript.executeAndReturnError(&error).stringValue {
                let parts = result.components(separatedBy: "|||")
                if parts.count >= 3 {
                    let newPlaying = NowPlaying(
                        artist: parts[0],
                        title: parts[1],
                        isPlaying: parts[2] == "true"
                    )
                    DispatchQueue.main.async {
                        if self?.nowPlaying != newPlaying {
                            self?.nowPlaying = newPlaying
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Controls using MediaRemote
    
    func togglePlayPause() {
        if let sendCommand = getMRSendCommand() {
            _ = sendCommand(kMRTogglePlayPause, nil)
        }
        // Update state immediately for responsiveness
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let newPlaying = NowPlaying(
                artist: self.nowPlaying.artist,
                title: self.nowPlaying.title,
                isPlaying: !self.nowPlaying.isPlaying
            )
            self.nowPlaying = newPlaying
        }
    }
    
    func nextTrack() {
        if let sendCommand = getMRSendCommand() {
            _ = sendCommand(kMRNextTrack, nil)
        }
    }
    
    func previousTrack() {
        if let sendCommand = getMRSendCommand() {
            _ = sendCommand(kMRPreviousTrack, nil)
        }
    }
}

