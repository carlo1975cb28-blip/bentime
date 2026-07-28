import SwiftUI

/// Transport controls for the video player including play/pause, seek, volume, and subtitle selection.
struct PlayerControlsView: View {
    @EnvironmentObject var playerViewModel: PlayerViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Seek bar
            seekBar

            // Controls row
            HStack(spacing: 16) {
                // Time display
                timeDisplay

                Spacer()

                // Transport buttons
                transportButtons

                Spacer()

                // Right side controls
                rightControls
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(radius: 4)
        )
    }

    // MARK: - Seek Bar

    private var seekBar: some View {
        HStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { playerViewModel.currentTime },
                    set: { newValue in
                        playerViewModel.isSeeking = true
                        playerViewModel.currentTime = newValue
                    }
                ),
                in: 0...max(playerViewModel.duration, 1),
                onEditingChanged: { editing in
                    if !editing {
                        playerViewModel.seek(to: playerViewModel.currentTime)
                        playerViewModel.isSeeking = false
                    }
                }
            )
            .controlSize(.small)
        }
    }

    // MARK: - Time Display

    private var timeDisplay: some View {
        HStack(spacing: 4) {
            Text(TimeFormatter.formatShort(playerViewModel.currentTime, totalDuration: playerViewModel.duration))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.white)
            Text("/")
                .font(.caption)
                .foregroundColor(.gray)
            Text(TimeFormatter.formatShort(playerViewModel.duration, totalDuration: playerViewModel.duration))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)
        }
    }

    // MARK: - Transport Buttons

    private var transportButtons: some View {
        HStack(spacing: 20) {
            // Skip backward
            Button(action: { playerViewModel.skipBackward() }) {
                Image(systemName: "gobackward.10")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .foregroundColor(.white)

            // Play/Pause
            Button(action: { playerViewModel.togglePlayPause() }) {
                Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title)
            }
            .buttonStyle(.plain)
            .foregroundColor(.white)

            // Skip forward
            Button(action: { playerViewModel.skipForward() }) {
                Image(systemName: "goforward.10")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .foregroundColor(.white)

            // Stop
            Button(action: { playerViewModel.stop() }) {
                Image(systemName: "stop.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .foregroundColor(.white)
        }
    }

    // MARK: - Right Controls

    private var rightControls: some View {
        HStack(spacing: 12) {
            // Volume
            volumeControl

            // Subtitle selector
            subtitleMenu
        }
    }

    // MARK: - Volume Control

    private var volumeControl: some View {
        HStack(spacing: 6) {
            Button(action: { playerViewModel.toggleMute() }) {
                Image(systemName: volumeIcon)
                    .font(.body)
            }
            .buttonStyle(.plain)
            .foregroundColor(.white)

            Slider(
                value: Binding(
                    get: { playerViewModel.isMuted ? 0 : playerViewModel.volume },
                    set: { playerViewModel.setVolume($0) }
                ),
                in: 0...1
            )
            .frame(width: 80)
            .controlSize(.small)
        }
    }

    private var volumeIcon: String {
        if playerViewModel.isMuted || playerViewModel.volume == 0 {
            return "speaker.slash.fill"
        } else if playerViewModel.volume < 0.33 {
            return "speaker.wave.1.fill"
        } else if playerViewModel.volume < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }

    // MARK: - Subtitle Menu

    private var subtitleMenu: some View {
        Menu {
            Button("Off") {
                playerViewModel.disableSubtitles()
            }

            if !playerViewModel.subtitleTracks.isEmpty {
                Divider()
                Section("External Subtitles") {
                    ForEach(playerViewModel.subtitleTracks) { track in
                        Button(track.name) {
                            playerViewModel.selectSubtitleTrack(track.id)
                        }
                    }
                }
            }

            if !playerViewModel.embeddedSubtitleNames.isEmpty {
                Divider()
                Section("Embedded Subtitles") {
                    ForEach(Array(playerViewModel.embeddedSubtitleNames.keys.sorted()), id: \.self) { index in
                        Button(playerViewModel.embeddedSubtitleNames[index] ?? "Track \(index)") {
                            playerViewModel.selectEmbeddedSubtitle(index)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "captions.bubble")
                .font(.body)
                .foregroundColor(.white)
        }
        .menuStyle(.borderlessButton)
        .frame(width: 30)
    }
}
