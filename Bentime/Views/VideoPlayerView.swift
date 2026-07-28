import SwiftUI
import VLCKit

/// NSViewRepresentable wrapping VLCVideoView for rendering video output.
struct VideoPlayerView: NSViewRepresentable {
    let player: VLCMediaPlayer

    func makeNSView(context: Context) -> VLCVideoView {
        let videoView = VLCVideoView()
        videoView.autoresizingMask = [.width, .height]
        videoView.fillScreen = true

        // Attach the player to this view
        player.drawable = videoView

        return videoView
    }

    func updateNSView(_ nsView: VLCVideoView, context: Context) {
        // Ensure player drawable is set (in case of view recreation)
        if player.drawable as? VLCVideoView !== nsView {
            player.drawable = nsView
        }
    }

    static func dismantleNSView(_ nsView: VLCVideoView, coordinator: ()) {
        // Clean up when view is removed
    }
}
