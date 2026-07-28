# Bentime

A native macOS video player application built with SwiftUI and VLCKit. Bentime supports playback of MP4, MKV, and many other video formats, along with comprehensive subtitle support including external `.srt` and `.ass/.ssa` files as well as embedded subtitle tracks.

## Features

- **Wide Format Support**: Play MP4, MKV, AVI, MOV, WMV, FLV, WebM, and more thanks to VLCKit
- **MKV Native Playback**: Full Matroska container support including multiple audio and subtitle tracks
- **Subtitle Support**:
  - External `.srt` (SubRip) subtitle files
  - External `.ass` / `.ssa` (Advanced SubStation Alpha) subtitle files
  - Embedded subtitle tracks in MKV files
  - Auto-detection of subtitle files matching video filename
- **Drag and Drop**: Drop video or subtitle files directly onto the player window
- **Keyboard Controls**: Space (play/pause), arrow keys (seek/volume), M (mute)
- **Clean UI**: Auto-hiding transport controls with seek bar, volume slider, and subtitle selector
- **macOS Native**: Built with SwiftUI for a native macOS experience

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Swift 5.9+

## Building

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/bentime.git
   cd bentime
   ```

2. Open the Xcode project:
   ```bash
   open Bentime.xcodeproj
   ```

3. Wait for Xcode to resolve the VLCKit package dependency (fetched via Swift Package Manager from `https://code.videolan.org/videolan/VLCKit.git`).

4. Select the "Bentime" scheme and a macOS target.

5. Build and run (Cmd+R).

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
- Select from embedded subtitle tracks (MKV files)

## Supported Formats

### Video
MP4, MKV, AVI, MOV, WMV, FLV, WebM, M4V, MPG, MPEG, TS, VOB, 3GP, OGV

### Subtitles
- `.srt` - SubRip (with HTML tag stripping)
- `.ass` / `.ssa` - Advanced SubStation Alpha (with style override stripping)
- Embedded tracks in MKV containers

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
    VideoPlayerView.swift       - NSViewRepresentable wrapping VLCVideoView
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
```

## Dependencies

- [VLCKit](https://code.videolan.org/videolan/VLCKit) - Provides media playback engine supporting MKV and many other formats that AVFoundation cannot handle natively.

## License

MIT License
