# droplet 

A minimalist Pomodoro timer for macOS, built with Swift and SwiftUI.

> **Built with AI** - This application was developed using AI-assisted coding.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

-  **Pomodoro Timer** - Work → Break → Long Break cycle
-  **6 Beautiful Themes** - Dark, Light, Beige, Frog, Cherry Blossom, Poppy
-  **Ambient Sounds** - Forest, Train, Library, Cricket (seamless looping)
-  **Glow Effects** - Optional glowing timer and progress bar
-  **Notifications** - Native macOS alerts when sessions end
-  **Menu Bar Only** - Lives in your menu bar, no dock icon
-  **Launch at Login** - Start automatically with your Mac
-  **Customizable** - Adjust durations, workflows, font size

## Installation

### Option 1: DMG Installer
1. Download `droplet-installer.dmg`
2. Open the DMG
3. Drag `droplet` to `Applications`
4. Launch from Applications or Spotlight

> [!IMPORTANT]
> **macOS Security Warning**
> Since this app is not notarized with Apple, macOS will show: *"Apple could not verify droplet is free of malware"*
>
> **To open the app:**
> - **Right-click** (or Control+click) the app → click **Open** → click **Open** again
> - This is a one-time approval; the app will open normally after that

### Option 2: Build from Source
```bash
git clone https://github.com/fikretkdincer/droplet.git
cd droplet
./build.sh
open droplet.app
```

## Usage

| Action | Effect |
|--------|--------|
| **Click** | Start/Pause timer |
| **Double-click** | Reset current session |
| **Right-click** | Open settings menu |
| **Menu bar icon** | Toggle window visibility |

## Settings (Right-Click Menu)

- **Sounds** - Select ambient sound & volume
- **Work/Break/Long Break Duration** - Customize timing
- **Workflows Before Long Break** - Set cycle count
- **Auto-start Next Session** - Automatic transitions
- **Always on Top** - Keep window visible
- **Launch at Login** - Start with macOS
- **Theme** - Choose color scheme
- **Visuals** - Font size & glow effects

## Building

Requirements:
- macOS 13.0+
- Swift 5.9+

```bash
# Build the app
./build.sh

# Create DMG installer
./create-dmg.sh
```

## Project Structure

```
droplet/
├── Sources/
│   ├── DropletApp.swift        # Main app & menu bar
│   ├── Models/
│   │   ├── Theme.swift         # Color themes
│   │   └── TimerState.swift    # Timer states
│   ├── ViewModels/
│   │   └── PomodoroViewModel.swift
│   ├── Views/
│   │   └── TimerView.swift     # UI & settings menu
│   └── Utilities/
│       ├── NotificationManager.swift
│       ├── SettingsManager.swift
│       ├── SoundManager.swift
│       └── LaunchAtLoginManager.swift
├── Resources/
│   ├── Info.plist
│   ├── AppIcon.icns
│   └── Sounds/                 # Ambient audio files
├── Package.swift
├── build.sh
└── create-dmg.sh
```

## License

MIT License - feel free to use and modify.

---

Made with AI assistance
