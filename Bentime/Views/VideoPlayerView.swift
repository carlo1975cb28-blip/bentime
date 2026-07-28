import SwiftUI
import AVKit

/// NSViewRepresentable wrapping AVPlayerView for rendering video output.
struct VideoPlayerView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.player = player
        playerView.controlsStyle = .none // We use our own custom controls
        playerView.showsFullScreenToggleButton = false
        playerView.autoresizingMask = [.width, .height]
        return playerView
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        // Update player reference if it changes
        if nsView.player !== player {
            nsView.player = player
        }
    }

    static func dismantleNSView(_ nsView: AVPlayerView, coordinator: ()) {
        nsView.player = nil
    }
}
