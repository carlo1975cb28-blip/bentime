import SwiftUI
import AVKit

/// Video player view using SwiftUI's native VideoPlayer.
/// We overlay a clear view to intercept interactions (our custom controls handle input).
struct VideoPlayerView: View {
    let player: AVPlayer

    var body: some View {
        VideoPlayer(player: player)
            .allowsHitTesting(false) // Let our custom controls handle all interaction
    }
}
