import SwiftUI
import AVFoundation

/// Custom NSView that hosts an AVPlayerLayer for reliable video rendering.
class VideoLayerView: NSView {
    var playerLayer: AVPlayerLayer

    init(player: AVPlayer) {
        self.playerLayer = AVPlayerLayer(player: player)
        super.init(frame: .zero)
        wantsLayer = true
        playerLayer.videoGravity = .resizeAspect
        layer?.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }

    func updatePlayer(_ player: AVPlayer) {
        playerLayer.player = player
    }
}

/// NSViewRepresentable wrapping a custom view with AVPlayerLayer for rendering video output.
struct VideoPlayerView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> VideoLayerView {
        let view = VideoLayerView(player: player)
        return view
    }

    func updateNSView(_ nsView: VideoLayerView, context: Context) {
        if nsView.playerLayer.player !== player {
            nsView.updatePlayer(player)
        }
    }

    static func dismantleNSView(_ nsView: VideoLayerView, coordinator: ()) {
        nsView.playerLayer.player = nil
    }
}
