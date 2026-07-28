# Bentime

A native macOS video player application built with SwiftUI and AVFoundation. Bentime supports playback of MP4, MOV, M4V, and other formats supported by Apple's AVPlayer, along with comprehensive external subtitle support including `.srt` and `.ass/.ssa` files.

## Features

- **Native Playback**: Uses Apple's AVFoundation/AVKit for hardware-accelerated video playback
- **Format Support**: Play MP4, MOV, M4V, and other formats natively supported by macOS AVPlayer
- **MKV Support**: macOS 13+ includes system-level codec support for many MKV files
- **Subtitle Support**:
  - External `.srt` (SubRip) subtitle files
  - External `.ass` / `.ssa` (Advanced SubStation Alpha) subtitle files
  - Auto-detection of subtitle files matching video filename
- **Drag and Drop**: Drop video or subtitle files directly onto the player window
- **Keyboard Controls**: Space (play/pause), arrow keys (seek/volume), M (mute)
- **Clean UI**: Auto-hiding transport controls with seek bar, volume slider, and subtitle selector
- **Zero Dependencies**: Built entirely with system frameworks - no external packages required
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

3. Select the "Bentime" scheme and a macOS target.

4. Build and run (Cmd+R).

No external dependencies to resolve - the project uses only system frameworks (AVFoundation, AVKit, SwiftUI, UniformTypeIdentifiers).

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

### Video (via AVFoundation)

Natively supported: MP4, MOV, M4V, MPEG, and other formats supported by Apple's AVPlayer.

Additional format support (MKV, AVI, etc.) depends on system-level codecs available on macOS 13+. Users can extend format support by installing third-party codec packages.

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
    PlayerViewModel.swift       - Playback state management via AVFoundation
  Views/
    ContentView.swift           - Main window with drag-and-drop
    VideoPlayerView.swift       - NSViewRepresentable wrapping AVPlayerView
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

None. Bentime uses only Apple system frameworks:
- **AVFoundation** - Media playback engine
- **AVKit** - AVPlayerView for video rendering
- **SwiftUI** - User interface
- **UniformTypeIdentifiers** - File type identification

## License

MIT License
