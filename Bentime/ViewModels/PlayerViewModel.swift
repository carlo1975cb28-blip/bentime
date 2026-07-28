import SwiftUI
import Combine
import UniformTypeIdentifiers
import VLCKit

/// Main view model managing video playback state through VLCKit.
/// Uses VLCMediaPlayer for broad format support (MKV, MP4, AVI, WebM, etc.).
class PlayerViewModel: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 1.0
    @Published var isMuted: Bool = false
    @Published var isMediaLoaded: Bool = false
    @Published var mediaTitle: String = "Bentime"
    @Published var currentSubtitleText: String = ""
    @Published var isFullscreen: Bool = false
    @Published var isDraggingOver: Bool = false
    @Published var isSeeking: Bool = false

    /// Available subtitle tracks (external loaded from file).
    @Published var subtitleTracks: [SubtitleTrack] = []

    /// Currently selected subtitle track ID. Nil means subtitles are off.
    @Published var selectedSubtitleTrackID: String? = nil

    /// Error message to display to the user. Nil when no error.
    @Published var errorMessage: String? = nil

    /// Whether to show the error alert.
    @Published var showError: Bool = false

    // MARK: - VLCKit Properties

    /// The VLCMediaPlayer instance used for media playback.
    let mediaPlayer: VLCMediaPlayer = VLCMediaPlayer()

    /// The NSView that VLCKit renders video into. Owned by the ViewModel
    /// to avoid lifecycle issues with SwiftUI view recreation.
    lazy var videoOutputView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        return view
    }()

    private var externalSubtitleTracks: [SubtitleTrack] = []
    private var subtitleUpdateTimer: Timer?
    private var previousVolume: Int32 = 100

    // MARK: - Initialization

    override init() {
        super.init()
        setupPlayer()
    }

    deinit {
        mediaPlayer.delegate = nil
        subtitleUpdateTimer?.invalidate()
        mediaPlayer.stop()
    }

    // MARK: - Setup

    private func setupPlayer() {
        mediaPlayer.delegate = self
        mediaPlayer.drawable = videoOutputView
        mediaPlayer.audio?.volume = 100  // VLCKit uses 0-200, 100 = normal
        previousVolume = 100

        // Timer for subtitle synchronization
        subtitleUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateCurrentSubtitle()
        }
    }

    // MARK: - File Opening

    /// Presents an NSOpenPanel to select a video file.
    func openFilePanel() {
        let panel = NSOpenPanel()
        panel.title = "Open Video File"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        panel.allowedContentTypes = [
            UTType.mpeg4Movie,
            UTType.movie,
            UTType.quickTimeMovie,
            UTType.avi,
            UTType(filenameExtension: "mkv") ?? .movie,
            UTType(filenameExtension: "webm") ?? .movie,
            UTType(filenameExtension: "flv") ?? .movie,
            UTType(filenameExtension: "wmv") ?? .movie,
            UTType(filenameExtension: "m4v") ?? .mpeg4Movie,
            UTType(filenameExtension: "ts") ?? .movie,
            UTType(filenameExtension: "vob") ?? .movie,
            UTType(filenameExtension: "3gp") ?? .movie,
            UTType(filenameExtension: "ogv") ?? .movie
        ]

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.openVideo(url: url)
        }
    }

    /// Presents an NSOpenPanel to select a subtitle file.
    func openSubtitleFilePanel() {
        let panel = NSOpenPanel()
        panel.title = "Open Subtitle File"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        panel.allowedContentTypes = [
            UTType(filenameExtension: "srt") ?? .plainText,
            UTType(filenameExtension: "ass") ?? .plainText,
            UTType(filenameExtension: "ssa") ?? .plainText
        ]

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.loadExternalSubtitle(url: url)
        }
    }

    /// Opens a video file from the given URL.
    func openVideo(url: URL) {
        stop()

        // Start accessing security-scoped resource if needed
        let accessGranted = url.startAccessingSecurityScopedResource()

        let media = VLCMedia(url: url)

        // Parse media on a background thread to avoid blocking the UI.
        // VLCKit's parse(withOptions:timeout:) is synchronous and can block
        // for up to the timeout duration on slow media or network mounts.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            media.parse(withOptions: VLCMediaParsingOptions(VLCMediaParseLocal), timeout: 3000)

            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    if accessGranted { url.stopAccessingSecurityScopedResource() }
                    return
                }

                // Check parsedStatus to surface errors for unplayable files
                if media.parsedStatus == .failed {
                    self.surfaceError("Unable to open file: the media could not be parsed. The file may be corrupted or in an unsupported format.")
                    if accessGranted { url.stopAccessingSecurityScopedResource() }
                    return
                }

                self.mediaPlayer.media = media
                self.mediaTitle = url.deletingPathExtension().lastPathComponent
                self.isMediaLoaded = true
                self.currentTime = 0
                self.duration = 0
                self.subtitleTracks = self.externalSubtitleTracks

                self.mediaPlayer.play()
                self.autoLoadMatchingSubtitle(for: url)
            }
        }
    }

    /// Attempts to auto-load a subtitle file with the same base name as the video.
    private func autoLoadMatchingSubtitle(for videoURL: URL) {
        let directory = videoURL.deletingLastPathComponent()
        let baseName = videoURL.deletingPathExtension().lastPathComponent

        for ext in SupportedFormats.subtitleExtensions {
            let subtitleURL = directory.appendingPathComponent("\(baseName).\(ext)")
            if FileManager.default.fileExists(atPath: subtitleURL.path) {
                loadExternalSubtitle(url: subtitleURL)
                break
            }
        }
    }

    // MARK: - Subtitle Management

    /// Loads an external subtitle file.
    func loadExternalSubtitle(url: URL) {
        do {
            let track = try SubtitleParser.parse(url: url)
            externalSubtitleTracks.append(track)

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.subtitleTracks = self.externalSubtitleTracks
                self.selectedSubtitleTrackID = track.id
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.surfaceError("Failed to load subtitle file: \(error.localizedDescription)")
            }
        }
    }

    /// Selects a subtitle track by ID, or nil to disable subtitles.
    func selectSubtitleTrack(_ trackID: String?) {
        selectedSubtitleTrackID = trackID
        updateCurrentSubtitle()
    }

    /// Disables all subtitles.
    func disableSubtitles() {
        selectedSubtitleTrackID = nil
        currentSubtitleText = ""
    }

    /// Updates the current subtitle text based on playback time.
    private func updateCurrentSubtitle() {
        guard let trackID = selectedSubtitleTrackID,
              let track = subtitleTracks.first(where: { $0.id == trackID }) else {
            if selectedSubtitleTrackID == nil {
                currentSubtitleText = ""
            }
            return
        }

        let entry = track.activeEntry(at: currentTime)
        let newText = entry?.text ?? ""
        if newText != currentSubtitleText {
            currentSubtitleText = newText
        }
    }

    // MARK: - Playback Controls

    func play() {
        mediaPlayer.play()
    }

    func pause() {
        mediaPlayer.pause()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func stop() {
        mediaPlayer.stop()
        isPlaying = false
        currentTime = 0
        currentSubtitleText = ""
    }

    /// Seeks to a specific time in seconds.
    func seek(to seconds: TimeInterval) {
        guard duration > 0 else { return }
        let targetMilliseconds = Int32(seconds * 1000)
        mediaPlayer.time = VLCTime(int: targetMilliseconds)
        currentTime = seconds
        isSeeking = false
    }

    /// Skips forward by the specified number of seconds.
    func skipForward(_ seconds: TimeInterval = 10) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }

    /// Skips backward by the specified number of seconds.
    func skipBackward(_ seconds: TimeInterval = 10) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }

    // MARK: - Volume

    /// Sets the volume. Accepts a value between 0.0 and 1.0.
    func setVolume(_ newVolume: Float) {
        volume = min(max(newVolume, 0), 1)
        let vlcVolume = Int32(volume * 100)
        mediaPlayer.audio?.volume = vlcVolume
        previousVolume = vlcVolume
        if volume > 0 {
            isMuted = false
        }
    }

    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            mediaPlayer.audio?.volume = 0
        } else {
            mediaPlayer.audio?.volume = previousVolume
        }
    }

    // MARK: - Error Handling

    /// Surfaces an error message to the user via the published error state.
    func surfaceError(_ message: String) {
        errorMessage = message
        showError = true
    }

    /// Dismisses the currently displayed error.
    func dismissError() {
        showError = false
        errorMessage = nil
    }

    // MARK: - Drag and Drop

    /// Handles a file drop, opening video or loading subtitle as appropriate.
    func handleFileDrop(urls: [URL]) {
        for url in urls {
            let ext = url.pathExtension.lowercased()
            if SupportedFormats.isVideoFile(ext) {
                openVideo(url: url)
                return
            } else if SupportedFormats.isSubtitleFile(ext) {
                loadExternalSubtitle(url: url)
                return
            }
        }
    }
}

// MARK: - VLCMediaPlayerDelegate

extension PlayerViewModel: VLCMediaPlayerDelegate {

    func mediaPlayerStateChanged(_ aNotification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch self.mediaPlayer.state {
            case .playing:
                self.isPlaying = true
            case .paused:
                self.isPlaying = false
            case .stopped:
                self.isPlaying = false
            case .ended:
                self.isPlaying = false
                self.currentTime = self.duration
            case .error:
                self.isPlaying = false
                self.surfaceError("An error occurred during playback.")
            default:
                break
            }
        }
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Update current time from VLCKit (milliseconds to seconds)
            if !self.isSeeking {
                let timeMs = self.mediaPlayer.time?.intValue ?? 0
                self.currentTime = TimeInterval(timeMs) / 1000.0
            }

            // Update duration if not yet known
            if self.duration <= 0 {
                if let length = self.mediaPlayer.media?.length {
                    let lengthMs = length.intValue
                    if lengthMs > 0 {
                        self.duration = TimeInterval(lengthMs) / 1000.0
                    }
                }
            }
        }
    }
}
