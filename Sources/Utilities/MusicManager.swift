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

// MARK: - Enums

enum RepeatMode: String {
    case off
    case one
    case all
}

/// Controls system media playback
/// Uses MediaRemote for commands, DistributedNotificationCenter for now playing info
class MusicManager: ObservableObject {
    static let shared = MusicManager()
    
    @Published var nowPlaying: NowPlaying = .empty
    @Published var isShuffling: Bool = false
    @Published var repeatMode: RepeatMode = .off
    
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
    
    // MARK: - Polling (fallback for initial state + shuffle/repeat)
    
    private func startPolling() {
        // Poll every 2 seconds
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.fetchViaScript()
        }
        fetchViaScript() // Initial fetch
    }
    
    private func fetchViaScript() {
        let app = SettingsManager.shared.musicApp
        let appName = app == "Apple Music" ? "Music" : app
        
        // Use AppleScript to fetch shuffle/repeat state + fallback metadata
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Script logic varies slightly by app
            let script: String
            if appName == "Spotify" {
                script = """
                tell application "System Events"
                    if (name of processes) contains "Spotify" then
                        tell application "Spotify"
                            try
                                set trackName to name of current track
                                set artistName to artist of current track
                                set playState to (player state is playing)
                                set shuffleState to (shuffling)
                                set repeatState to (repeating)
                                return artistName & "|||" & trackName & "|||" & (playState as string) & "|||" & (shuffleState as string) & "|||" & (repeatState as string)
                            on error
                                return "|||false|||false|||false"
                            end try
                        end tell
                    else
                        return "|||false|||false|||false"
                    end if
                end tell
                """
            } else { // Music
                script = """
                tell application "System Events"
                    if (name of processes) contains "Music" then
                        tell application "Music"
                            try
                                set trackName to name of current track
                                set artistName to artist of current track
                                set playState to (player state is playing)
                                set shuffleState to (shuffle enabled)
                                set repeatState to (song repeat as string)
                                return artistName & "|||" & trackName & "|||" & (playState as string) & "|||" & (shuffleState as string) & "|||" & repeatState
                            on error
                                return "|||false|||false|||off"
                            end try
                        end tell
                    else
                        return "|||false|||false|||off"
                    end if
                end tell
                """
            }
            
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script),
               let result = appleScript.executeAndReturnError(&error).stringValue {
                let parts = result.components(separatedBy: "|||")
                if parts.count >= 5 {
                    // Update metadata if needed (fallback)
                    if self?.nowPlaying == .empty {
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
                    
                    // Update shuffle/repeat state
                    let shuffling = parts[3] == "true"
                    let repeatStr = parts[4] // "true"/"false" for Spotify, "off"/"one"/"all" for Music
                    
                    let newRepeatMode: RepeatMode
                    if appName == "Spotify" {
                        // Spotify returns boolean for repeating (usually toggles all/off via script)
                        newRepeatMode = (repeatStr == "true") ? .all : .off
                    } else {
                        switch repeatStr {
                        case "one": newRepeatMode = .one
                        case "all": newRepeatMode = .all
                        default: newRepeatMode = .off
                        }
                    }
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.isShuffling = shuffling
                        self?.repeatMode = newRepeatMode
                    }
                }
            }
        }
    }
    
    // MARK: - App-Specific Controls (AppleScript)
    
    private func executeAppleScript(_ source: String) {
        print("[MusicManager] Executing AppleScript: \(source)")
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: source) {
                let result = scriptObject.executeAndReturnError(&error)
                if let error = error {
                    print("❌ AppleScript error: \(error)")
                } else {
                    print("✅ AppleScript executed successfully. Result: \(result)")
                }
            } else {
                print("❌ Failed to create NSAppleScript")
            }
        }
    }
    
    // MARK: - Controls
    
    func togglePlayPause() {
        let app = SettingsManager.shared.musicApp
        switch app {
        case "Spotify": executeAppleScript("tell application \"Spotify\" to playpause")
        case "Apple Music": executeAppleScript("tell application \"Music\" to playpause")
        default: if let sendCommand = getMRSendCommand() { _ = sendCommand(kMRTogglePlayPause, nil) }
        }
        
        // Optimistic update
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.nowPlaying = NowPlaying(artist: self.nowPlaying.artist, title: self.nowPlaying.title, isPlaying: !self.nowPlaying.isPlaying)
        }
    }
    
    func nextTrack() {
        let app = SettingsManager.shared.musicApp
        switch app {
        case "Spotify": executeAppleScript("tell application \"Spotify\" to next track")
        case "Apple Music": executeAppleScript("tell application \"Music\" to next track")
        default: if let sendCommand = getMRSendCommand() { _ = sendCommand(kMRNextTrack, nil) }
        }
    }
    
    func previousTrack() {
        let app = SettingsManager.shared.musicApp
        switch app {
        case "Spotify": executeAppleScript("tell application \"Spotify\" to previous track")
        case "Apple Music": executeAppleScript("tell application \"Music\" to previous track")
        default: if let sendCommand = getMRSendCommand() { _ = sendCommand(kMRPreviousTrack, nil) }
        }
    }
    
    func toggleShuffle() {
        let app = SettingsManager.shared.musicApp
        switch app {
        case "Spotify": executeAppleScript("tell application \"Spotify\" to set shuffling to not shuffling")
        case "Apple Music": executeAppleScript("tell application \"Music\" to set shuffle enabled to not shuffle enabled")
        default: break // MediaRemote shuffle toggle is complex/unsupported via simple command
        }
        
        // Optimistic update
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isShuffling.toggle()
        }
    }
    
    func toggleRepeat() {
        let app = SettingsManager.shared.musicApp
        switch app {
        case "Spotify":
            // Spotify AppleScript often just toggles repeating (bool)
            executeAppleScript("tell application \"Spotify\" to set repeating to not repeating")
            DispatchQueue.main.async { [weak self] in
                self?.repeatMode = (self?.repeatMode == .off) ? .all : .off
            }
        case "Apple Music":
            // Cycle: off -> all -> one -> off
            let script = """
            tell application "Music"
                if song repeat is off then
                    set song repeat to all
                else if song repeat is all then
                    set song repeat to one
                else
                    set song repeat to off
                end if
            end tell
            """
            executeAppleScript(script)
            // Ideally we wait for poll, but optimistic:
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch self.repeatMode {
                case .off: self.repeatMode = .all
                case .all: self.repeatMode = .one
                case .one: self.repeatMode = .off
                }
            }
        default: break
        }
    }
}

