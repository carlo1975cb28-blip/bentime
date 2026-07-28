import SwiftUI
import Combine
import UniformTypeIdentifiers
import VLCKit

/// Main view model managing video playback state through VLCKit.
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

    /// Available subtitle tracks (external + embedded).
    @Published var subtitleTracks: [SubtitleTrack] = []

    /// Currently selected subtitle track ID. Nil means subtitles are off.
    @Published var selectedSubtitleTrackID: String? = nil

    /// Embedded subtitle track names from VLCKit.
    @Published var embeddedSubtitleNames: [Int: String] = [:]

    /// Currently selected embedded subtitle index (-1 means disabled).
    @Published var selectedEmbeddedSubtitleIndex: Int = -1

    /// Error message to display to the user. Nil when no error.
    @Published var errorMessage: String? = nil

    /// Whether to show the error alert.
    @Published var showError: Bool = false

    // MARK: - VLCKit Properties

    private(set) var mediaPlayer: VLCMediaPlayer = VLCMediaPlayer()
    private var timeObserverTimer: Timer?
    private var externalSubtitleTracks: [SubtitleTrack] = []

    // MARK: - Initialization

    override init() {
        super.init()
        setupPlayer()
    }

    deinit {
        stop()
        timeObserverTimer?.invalidate()
    }

    // MARK: - Setup

    private func setupPlayer() {
        mediaPlayer.delegate = self
        mediaPlayer.audio?.volume = Int32(volume * 100)
        startTimeObserver()
    }

    private func startTimeObserver() {
        timeObserverTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimeAndSubtitles()
        }
    }

    private func updateTimeAndSubtitles() {
        guard isMediaLoaded else { return }

        let time = Double(mediaPlayer.time.intValue) / 1000.0
        let totalDuration = Double(mediaPlayer.media?.length.intValue ?? 0) / 1000.0

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !self.isSeeking {
                self.currentTime = max(0, time)
            }
            if totalDuration > 0 {
                self.duration = totalDuration
            }
            self.updateCurrentSubtitle()
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

        let media = VLCMedia(url: url)
        mediaPlayer.media = media

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.mediaTitle = url.deletingPathExtension().lastPathComponent
            self.isMediaLoaded = true
            self.currentTime = 0
            self.duration = 0
            self.subtitleTracks = self.externalSubtitleTracks
            self.selectedEmbeddedSubtitleIndex = -1
        }

        // Start playback
        mediaPlayer.play()
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = true
        }

        // Look for subtitle file with same name in same directory
        autoLoadMatchingSubtitle(for: url)
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
                self.selectedEmbeddedSubtitleIndex = -1
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
        if trackID != nil {
            selectedEmbeddedSubtitleIndex = -1
            // Disable VLCKit embedded subtitles
            mediaPlayer.currentVideoSubTitleIndex = -1
        }
        updateCurrentSubtitle()
    }

    /// Selects an embedded subtitle track by VLC index.
    func selectEmbeddedSubtitle(_ index: Int) {
        selectedEmbeddedSubtitleIndex = index
        selectedSubtitleTrackID = nil
        mediaPlayer.currentVideoSubTitleIndex = Int32(index)
        currentSubtitleText = ""
    }

    /// Disables all subtitles.
    func disableSubtitles() {
        selectedSubtitleTrackID = nil
        selectedEmbeddedSubtitleIndex = -1
        mediaPlayer.currentVideoSubTitleIndex = -1
        currentSubtitleText = ""
    }

    /// Updates the current subtitle text based on playback time.
    private func updateCurrentSubtitle() {
        guard let trackID = selectedSubtitleTrackID,
              let track = subtitleTracks.first(where: { $0.id == trackID }) else {
            if selectedEmbeddedSubtitleIndex == -1 {
                currentSubtitleText = ""
            }
            return
        }

        let entry = track.activeEntry(at: currentTime)
        currentSubtitleText = entry?.text ?? ""
    }

    // MARK: - Playback Controls

    func play() {
        mediaPlayer.play()
        isPlaying = true
    }

    func pause() {
        mediaPlayer.pause()
        isPlaying = false
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
        let position = Float(seconds / duration)
        mediaPlayer.position = min(max(position, 0), 1)
        currentTime = seconds
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

    func setVolume(_ newVolume: Float) {
        volume = min(max(newVolume, 0), 1)
        mediaPlayer.audio?.volume = Int32(volume * 100)
        if volume > 0 {
            isMuted = false
        }
    }

    func toggleMute() {
        isMuted.toggle()
        mediaPlayer.audio?.volume = isMuted ? 0 : Int32(volume * 100)
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
                self.refreshEmbeddedSubtitles()
            case .paused:
                self.isPlaying = false
            case .stopped, .ended:
                self.isPlaying = false
            case .error:
                self.isPlaying = false
                self.isMediaLoaded = false
                self.surfaceError("Failed to load or play the media file. The format may be unsupported or the file may be corrupted.")
            default:
                break
            }
        }
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        // Time updates handled by timer for smoother UI
    }

    /// Refreshes the list of embedded subtitle tracks from VLCKit.
    private func refreshEmbeddedSubtitles() {
        guard let subtitleIndexes = mediaPlayer.videoSubTitlesIndexes as? [Int],
              let subtitleNames = mediaPlayer.videoSubTitlesNames as? [String] else {
            return
        }

        var embedded: [Int: String] = [:]
        for (index, name) in zip(subtitleIndexes, subtitleNames) {
            if index != -1 { // -1 is "Disable" option
                embedded[index] = name.isEmpty ? "Track \(index)" : name
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.embeddedSubtitleNames = embedded
        }
    }
}
