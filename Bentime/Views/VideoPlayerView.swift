import SwiftUI
import AppKit

/// Video player view using VLCKit for rendering.
/// Creates an NSView that VLCMediaPlayer uses as its drawable surface.
struct VideoPlayerView: NSViewRepresentable {
    @EnvironmentObject var playerViewModel: PlayerViewModel

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor

        // Set this view as the VLCMediaPlayer's drawable
        playerViewModel.videoDrawable = view

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Ensure the drawable is still set (handles view recreation)
        if playerViewModel.videoDrawable !== nsView {
            playerViewModel.videoDrawable = nsView
        }
    }
}
