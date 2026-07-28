import SwiftUI
import Combine
import UniformTypeIdentifiers
import AVFoundation
import AVKit

/// Main view model managing video playback state through AVFoundation.
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

    // MARK: - AVFoundation Properties

    /// The AVPlayer instance used for media playback.
    let player: AVPlayer = AVPlayer()

    private var timeObserverToken: Any?
    private var statusObservation: NSKeyValueObservation?
    private var durationObservation: NSKeyValueObservation?
    private var timeControlStatusObservation: NSKeyValueObservation?
    private var externalSubtitleTracks: [SubtitleTrack] = []
    private var subtitleUpdateTimer: Timer?

    // MARK: - Initialization

    override init() {
        super.init()
        setupPlayer()
    }

    deinit {
        removeTimeObserver()
        subtitleUpdateTimer?.invalidate()
        statusObservation?.invalidate()
        durationObservation?.invalidate()
        timeControlStatusObservation?.invalidate()
    }

    // MARK: - Setup

    private func setupPlayer() {
        player.volume = volume
        addTimeObserver()
        observeTimeControlStatus()
    }

    /// Adds a periodic time observer to track playback position.
    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            if !self.isSeeking {
                self.currentTime = CMTimeGetSeconds(time)
            }
            self.updateCurrentSubtitle()
        }
    }

    /// Removes the periodic time observer.
    private func removeTimeObserver() {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    /// Observes the player's timeControlStatus to update isPlaying state.
    private func observeTimeControlStatus() {
        timeControlStatusObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch player.timeControlStatus {
                case .playing:
                    self.isPlaying = true
                case .paused:
                    self.isPlaying = false
                case .waitingToPlayAtSpecifiedRate:
                    // Buffering - keep current state
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    /// Sets up KVO observations on the current player item for status and duration.
    private func observePlayerItem(_ item: AVPlayerItem) {
        statusObservation?.invalidate()
        durationObservation?.invalidate()

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch item.status {
                case .readyToPlay:
                    let seconds = CMTimeGetSeconds(item.duration)
                    if seconds.isFinite && seconds > 0 {
                        self.duration = seconds
                    }
                case .failed:
                    self.isPlaying = false
                    self.isMediaLoaded = false
                    let errorDesc = item.error?.localizedDescription ?? "Unknown error"
                    self.surfaceError("Failed to load media: \(errorDesc)")
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }

        durationObservation = item.observe(\.duration, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let seconds = CMTimeGetSeconds(item.duration)
                if seconds.isFinite && seconds > 0 {
                    self.duration = seconds
                }
            }
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

        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        observePlayerItem(playerItem)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.mediaTitle = url.deletingPathExtension().lastPathComponent
            self.isMediaLoaded = true
            self.currentTime = 0
            self.duration = 0
            self.subtitleTracks = self.externalSubtitleTracks
        }

        // Start playback
        player.play()

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
        currentSubtitleText = entry?.text ?? ""
    }

    // MARK: - Playback Controls

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func stop() {
        player.pause()
        player.seek(to: .zero)
        isPlaying = false
        currentTime = 0
        currentSubtitleText = ""
    }

    /// Seeks to a specific time in seconds.
    func seek(to seconds: TimeInterval) {
        guard duration > 0 else { return }
        let targetTime = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isSeeking = false
            }
        }
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
        player.volume = volume
        if volume > 0 {
            isMuted = false
        }
    }

    func toggleMute() {
        isMuted.toggle()
        player.volume = isMuted ? 0 : volume
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
