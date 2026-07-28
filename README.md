# Bentime

A native macOS video player application built with SwiftUI and VLCKit. Bentime supports playback of virtually any video format -- MP4, MKV (all codecs), AVI, WMV, FLV, WebM, and more -- along with comprehensive external subtitle support including `.srt` and `.ass/.ssa` files.

## Features

- **Universal Playback**: Uses VLCKit for broad codec support, including formats that AVFoundation cannot handle
- **Format Support**: Play MP4, MKV (any codec), AVI, WMV, FLV, WebM, MOV, M4V, TS, VOB, OGV, 3GP, and more
- **Subtitle Support**:
  - External `.srt` (SubRip) subtitle files
  - External `.ass` / `.ssa` (Advanced SubStation Alpha) subtitle files
  - Auto-detection of subtitle files matching video filename
- **Drag and Drop**: Drop video or subtitle files directly onto the player window
- **Keyboard Controls**: Space (play/pause), arrow keys (seek/volume), M (mute)
- **Clean UI**: Auto-hiding transport controls with seek bar, volume slider, and subtitle selector
- **macOS Native**: Built with SwiftUI for a native macOS experience

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Swift 5.9+
- VLCKit 3.7.3 (see setup instructions below)

## Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/bentime.git
cd bentime
```

### 2. Download VLCKit Framework

The VLCKit binary framework is not included in the repository due to its size. Download it using one of these methods:

**Option A: One-liner (recommended)**

```bash
cd Frameworks && \
curl -L "https://download.videolan.org/pub/cocoapods/prod/VLCKit-3.7.3-319ed2c0-79128878.tar.xz" | tar xJ --strip-components=1 "VLCKit - binary package/VLCKit.xcframework"
```

**Option B: Manual download**

1. Download from: https://download.videolan.org/pub/cocoapods/prod/VLCKit-3.7.3-319ed2c0-79128878.tar.xz
2. Extract the archive
3. Copy `VLCKit - binary package/VLCKit.xcframework` into the `Frameworks/` directory

See `Frameworks/DOWNLOAD.md` for detailed instructions.

### 3. Build and Run

1. Open the Xcode project:
   ```bash
   open Bentime.xcodeproj
   ```

2. Select the "Bentime" scheme and a macOS target.

3. Build and run (Cmd+R).

## Usage

### Opening Files

- **Menu**: File > Open File... (Cmd+O)
- **Drag and Drop**: Drag a video file onto the application window
- **Subtitles**: File > Open Subtitle File... (Cmd+Shift+S) or drag a subtitle file onto the window

### Playback Controls

| Key / Action | Function |
|---|---|
| Space | Play / Pause |
| Right Arrow | Skip forward 10 seconds |
| Left Arrow | Skip backward 10 seconds |
| Up Arrow | Volume up |
| Down Arrow | Volume down |
| M | Toggle mute |
| Cmd+O | Open video file |
| Cmd+Shift+S | Open subtitle file |

### Subtitle Selection

Click the subtitle icon (captions bubble) in the player controls to:
- Disable subtitles
- Select from loaded external subtitle files

## Supported Formats

### Video (via VLCKit)

VLCKit provides native support for virtually all video formats and codecs:

- **Containers**: MP4, MKV, AVI, WMV, FLV, WebM, MOV, M4V, TS, VOB, OGV, 3GP, MPEG, and more
- **Video Codecs**: H.264, H.265/HEVC, VP8, VP9, AV1, MPEG-2, MPEG-4, Theora, DivX, and more
- **Audio Codecs**: AAC, MP3, FLAC, Vorbis, Opus, AC3, DTS, PCM, and more

### Subtitles

- `.srt` - SubRip (with HTML tag stripping)
- `.ass` / `.ssa` - Advanced SubStation Alpha (with style override stripping)

## Architecture

The application follows the MVVM (Model-View-ViewModel) architecture:

```
Bentime/
  BentimeApp.swift              - App entry point (@main)
  Models/
    Subtitle.swift              - Subtitle data models
    SubtitleParser.swift        - .srt and .ass/.ssa parser
  ViewModels/
    PlayerViewModel.swift       - Playback state management via VLCKit
  Views/
    ContentView.swift           - Main window with drag-and-drop
    VideoPlayerView.swift       - NSViewRepresentable wrapping NSView for VLCKit
    PlayerControlsView.swift    - Transport controls UI
    SubtitleOverlayView.swift   - Subtitle text overlay
    DropOverlayView.swift       - Drag-and-drop visual indicator
  Utilities/
    TimeFormatter.swift         - HH:MM:SS formatting
    SupportedFormats.swift      - File extension constants
  Resources/
    Assets.xcassets/            - App icons and colors
  Info.plist                    - App metadata and UTI declarations
  Bentime.entitlements          - Runtime permissions
Frameworks/
  VLCKit.xcframework/           - VLCKit binary (not in git, see DOWNLOAD.md)
  DOWNLOAD.md                   - Framework download instructions
```

## Dependencies

- **VLCKit 3.7.3** - Video playback engine (local binary framework)
- **SwiftUI** - User interface (system framework)
- **UniformTypeIdentifiers** - File type identification (system framework)
- **AppKit** - NSView for VLCKit drawable (system framework)

## Entitlements

The app requires the following entitlements for VLCKit compatibility (already configured):

- `com.apple.security.cs.allow-unsigned-executable-memory` - Required by VLCKit's internal codec execution
- `com.apple.security.cs.disable-library-validation` - Required to load the VLCKit framework

## License

MIT License
