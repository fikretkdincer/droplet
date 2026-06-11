import Foundation
import AVFoundation
import AppKit

/// Available ambient sound types (built-in)
enum AmbientSound: String, CaseIterable, Identifiable {
    case none = "None"
    case forest = "Forest"
    case train = "Train"
    case library = "Library"
    case crickets = "Crickets"

    var id: String { rawValue }

    var filename: String? {
        switch self {
        case .none: return nil
        case .forest: return "forest"
        case .train: return "train"
        case .library: return "library"
        case .crickets: return "cricket"
        }
    }

    var icon: String {
        switch self {
        case .none: return "🔇"
        case .forest: return "🌲"
        case .train: return "🚂"
        case .library: return "📚"
        case .crickets: return "🦗"
        }
    }
}

/// Custom user-imported sound
struct CustomSound: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    let filename: String

    var icon: String { "🎵" }
}

/// Manages ambient sound playback with seamless looping
class SoundManager: ObservableObject {
    static let shared = SoundManager()

    @Published var currentSound: AmbientSound = .none
    @Published var currentCustomSound: CustomSound? = nil
    @Published var currentGeneratedNoise: GeneratedNoise? = nil
    @Published var volume: Float = 0.5
    @Published var isPlaying: Bool = false
    @Published var customSounds: [CustomSound] = []

    private var audioPlayer: AVAudioPlayer?
    private var focusNoiseEngine: FocusNoiseEngine?

    var canTogglePlayback: Bool {
        currentGeneratedNoise != nil || currentCustomSound != nil || currentSound != .none
    }

    var currentSelectionTitle: String {
        if let currentGeneratedNoise {
            return currentGeneratedNoise.rawValue
        }

        if let currentCustomSound {
            return currentCustomSound.name
        }

        if currentSound != .none {
            return currentSound.rawValue
        }

        return "No sound selected"
    }

    /// Directory for custom sounds
    private var customSoundsDirectory: URL {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return FileManager.default.temporaryDirectory.appendingPathComponent("droplet/Sounds", isDirectory: true)
        }
        let soundsDir = appSupport.appendingPathComponent("droplet/Sounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)
        return soundsDir
    }

    private init() {
        loadCustomSounds()
        loadSavedPreferences()
    }

    // MARK: - Persistence

    private func loadSavedPreferences() {
        // Load volume
        if UserDefaults.standard.object(forKey: "soundVolume") == nil {
            volume = 0.5
        } else {
            volume = max(0, min(1, UserDefaults.standard.float(forKey: "soundVolume")))
        }

        // Load current sound
        if let savedSound = UserDefaults.standard.string(forKey: "ambientSound"),
           let sound = AmbientSound(rawValue: savedSound) {
            currentSound = sound
        }

        // Load custom sound if selected
        if let customSoundId = UserDefaults.standard.string(forKey: "customSoundId"),
           let customSound = customSounds.first(where: { $0.id == customSoundId }) {
            currentCustomSound = customSound
            currentSound = .none
        }

        if let generatedNoiseRaw = UserDefaults.standard.string(forKey: "generatedNoise"),
           let generatedNoise = GeneratedNoise(rawValue: generatedNoiseRaw) {
            currentGeneratedNoise = generatedNoise
            currentCustomSound = nil
            currentSound = .none
        }
    }

    private func loadCustomSounds() {
        if let data = UserDefaults.standard.data(forKey: "customSounds"),
           let sounds = try? JSONDecoder().decode([CustomSound].self, from: data) {
            customSounds = sounds
        }
    }

    private func saveCustomSounds() {
        if let data = try? JSONEncoder().encode(customSounds) {
            UserDefaults.standard.set(data, forKey: "customSounds")
        }
    }

    // MARK: - Import Custom Sound

    func importSound() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.mp3, .audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select an audio file to import"
        panel.prompt = "Import"

        guard panel.runModal() == .OK, let sourceURL = panel.url else { return }

        // Generate unique filename
        let id = UUID().uuidString
        let ext = sourceURL.pathExtension
        let destFilename = "\(id).\(ext)"
        let destURL = customSoundsDirectory.appendingPathComponent(destFilename)

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)

            // Use original filename (without extension) as default name
            let defaultName = sourceURL.deletingPathExtension().lastPathComponent

            // Prompt for custom name
            let alert = NSAlert()
            alert.messageText = "Name this sound"
            alert.informativeText = "Enter a name for your custom sound:"
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")

            let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            input.stringValue = defaultName
            alert.accessoryView = input

            if alert.runModal() == .alertFirstButtonReturn {
                let name = input.stringValue.isEmpty ? defaultName : input.stringValue
                let customSound = CustomSound(id: id, name: name, filename: destFilename)
                customSounds.append(customSound)
                saveCustomSounds()

                // Play the newly imported sound
                playCustom(customSound)
            } else {
                // User cancelled, remove the copied file
                try? FileManager.default.removeItem(at: destURL)
            }
        } catch {
            print("❌ Failed to import sound: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete Custom Sound

    func deleteCustomSound(_ sound: CustomSound) {
        // Stop if currently playing
        if currentCustomSound?.id == sound.id {
            clearSelection()
        }

        // Remove file
        let fileURL = customSoundsDirectory.appendingPathComponent(sound.filename)
        try? FileManager.default.removeItem(at: fileURL)

        // Remove from list
        customSounds.removeAll { $0.id == sound.id }
        saveCustomSounds()
    }

    // MARK: - Playback

    /// Select a built-in ambient sound without starting playback.
    func selectAmbient(_ sound: AmbientSound) {
        stop()
        currentSound = sound
        currentCustomSound = nil
        currentGeneratedNoise = nil

        if sound == .none {
            UserDefaults.standard.removeObject(forKey: "ambientSound")
        } else {
            UserDefaults.standard.set(sound.rawValue, forKey: "ambientSound")
        }
        UserDefaults.standard.removeObject(forKey: "customSoundId")
        UserDefaults.standard.removeObject(forKey: "generatedNoise")
    }

    /// Select a generated noise preset without starting playback.
    func selectGenerated(_ noise: GeneratedNoise) {
        stop()
        currentSound = .none
        currentCustomSound = nil
        currentGeneratedNoise = noise
        UserDefaults.standard.set(noise.rawValue, forKey: "generatedNoise")
        UserDefaults.standard.removeObject(forKey: "ambientSound")
        UserDefaults.standard.removeObject(forKey: "customSoundId")
    }

    /// Play a built-in ambient sound
    func play(_ sound: AmbientSound) {
        stop()
        currentSound = sound
        currentCustomSound = nil
        currentGeneratedNoise = nil
        UserDefaults.standard.set(sound.rawValue, forKey: "ambientSound")
        UserDefaults.standard.removeObject(forKey: "customSoundId")
        UserDefaults.standard.removeObject(forKey: "generatedNoise")

        guard let filename = sound.filename else {
            isPlaying = false
            return
        }

        // Try to find the sound file in the bundle
        let extensions = ["mp3", "m4a", "aac", "wav"]
        var soundURL: URL?

        for ext in extensions {
            if let url = Bundle.main.url(forResource: filename, withExtension: ext, subdirectory: "Sounds") {
                soundURL = url
                break
            }
            if let url = Bundle.main.url(forResource: filename, withExtension: ext) {
                soundURL = url
                break
            }
        }

        guard let url = soundURL else {
            print("⚠️ Sound file not found: \(filename)")
            isPlaying = false
            return
        }

        playURL(url)
    }

    /// Play a custom sound
    func playCustom(_ sound: CustomSound) {
        stop()
        currentSound = .none
        currentCustomSound = sound
        currentGeneratedNoise = nil
        UserDefaults.standard.set(sound.id, forKey: "customSoundId")
        UserDefaults.standard.removeObject(forKey: "ambientSound")
        UserDefaults.standard.removeObject(forKey: "generatedNoise")

        let url = customSoundsDirectory.appendingPathComponent(sound.filename)
        playURL(url)
    }

    /// Play a generated static focus-noise preset.
    func playGenerated(_ noise: GeneratedNoise) {
        stop()
        currentSound = .none
        currentCustomSound = nil
        currentGeneratedNoise = noise
        UserDefaults.standard.set(noise.rawValue, forKey: "generatedNoise")
        UserDefaults.standard.removeObject(forKey: "ambientSound")
        UserDefaults.standard.removeObject(forKey: "customSoundId")

        do {
            let engine = FocusNoiseEngine()
            try engine.start(noise: noise, volume: volume)
            focusNoiseEngine = engine
            isPlaying = true
        } catch {
            print("Error playing generated noise: \(error.localizedDescription)")
            focusNoiseEngine = nil
            isPlaying = false
        }
    }

    func clearSelection() {
        stop()
        currentSound = .none
        currentCustomSound = nil
        currentGeneratedNoise = nil
        UserDefaults.standard.removeObject(forKey: "ambientSound")
        UserDefaults.standard.removeObject(forKey: "customSoundId")
        UserDefaults.standard.removeObject(forKey: "generatedNoise")
    }

    private func playURL(_ url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            print("🔊 Playing: \(url.lastPathComponent)")
        } catch {
            print("❌ Error playing sound: \(error.localizedDescription)")
            isPlaying = false
        }
    }

    /// Stop current playback
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        focusNoiseEngine?.stop()
        focusNoiseEngine = nil
        isPlaying = false
    }

    /// Toggle playback
    func toggle() {
        if isPlaying {
            stop()
        } else if let custom = currentCustomSound {
            playCustom(custom)
        } else if let generatedNoise = currentGeneratedNoise {
            playGenerated(generatedNoise)
        } else if currentSound != .none {
            play(currentSound)
        }
    }

    /// Update volume
    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        audioPlayer?.volume = volume
        focusNoiseEngine?.volume = volume
        UserDefaults.standard.set(volume, forKey: "soundVolume")
    }
}
