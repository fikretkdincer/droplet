![droplet header](Resources/header.png)

Built with Swift and SwiftUI.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- 🍅 **Pomodoro Timer** - Work → Break → Long Break cycle
- 🎵 **Music Integration** - Control Spotify & Apple Music (Play/Pause, Next, Previous, Shuffle, Repeat) with Now Playing info
- 🎨 **8 Beautiful Themes** - Dark, Light, Beige, Beige+, Navy, Frog, Blossom, Poppy
- 🎧 **Ambient Sounds** - Forest, Train, Library, Cricket (seamless looping)
- ✨ **Glow Effects** - Optional glowing timer and progress bar
- 🔔 **Notifications** - Native macOS alerts when sessions end
- � **Goal Tracker** - Set daily goals, track weekly progress with visual charts
- 🎶 **Custom Sounds** - Import your own MP3 files as focus sounds
- �📌 **Menu Bar Only** - Lives in your menu bar, no dock icon
- 🚀 **Launch at Login** - Start automatically with your Mac
- ⚙️ **Customizable** - Adjust durations, workflows, font size

## Installation

### Download Latest Release

**[📥 Download droplet](https://github.com/fikretkdincer/droplet/releases/latest)**

1. Download `droplet-installer.dmg` from the latest release
2. Open the DMG
3. Drag `droplet` to `Applications`
4. Launch from Applications or Spotlight

> [!IMPORTANT]
> **macOS Security Warning**
> Since this app is not notarized with Apple, macOS will show: *"Apple could not verify droplet is free of malware"*
>
> **To open the app (choose one):**
> - **Right-click** (or Control+click) the app → click **Open** → click **Open** again
> - Or go to **System Settings → Privacy & Security** → scroll down → click **Open Anyway**
>
> This is a one-time approval; the app will open normally after that.

> [!NOTE]
> **Music Control Permissions**
> When you first use the music controls, macOS will ask: *"Droplet wants to control Spotify/Music"*.
> Click **OK** to allow Droplet to play/pause, skip tracks, and toggle shuffle/repeat in your chosen music app.

### Build from Source
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

## License

MIT License - feel free to use and modify.

---

Made with AI assistance
