import SwiftUI
import AppKit

/// Video player view using VLCKit for rendering.
/// Vends the ViewModel-owned NSView as the drawable surface, ensuring
/// a stable lifecycle that is not affected by SwiftUI view recreation.
struct VideoPlayerView: NSViewRepresentable {
    @EnvironmentObject var playerViewModel: PlayerViewModel

    func makeNSView(context: Context) -> NSView {
        // Return the ViewModel-owned view directly. This ensures the drawable
        // is never recreated behind VLCKit's back when SwiftUI re-evaluates
        // the view hierarchy.
        return playerViewModel.videoOutputView
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // No-op: the ViewModel owns and manages the view's lifecycle.
        // VLCKit's drawable is set once during player setup and remains stable.
    }
}
