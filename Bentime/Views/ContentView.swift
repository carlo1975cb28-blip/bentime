import SwiftUI

/// Main content view of the Bentime application.
/// Contains the video player, subtitle overlay, player controls, and drag-and-drop support.
struct ContentView: View {
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @State private var showControls: Bool = true
    @State private var controlsHideTimer: Timer?

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            if playerViewModel.isMediaLoaded {
                // Video player
                VideoPlayerView(player: playerViewModel.mediaPlayer)
                    .ignoresSafeArea()

                // Subtitle overlay
                SubtitleOverlayView(text: playerViewModel.currentSubtitleText)

                // Controls overlay
                if showControls {
                    VStack {
                        Spacer()
                        PlayerControlsView()
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                    .transition(.opacity)
                }
            } else {
                // Empty state with drop prompt
                VStack(spacing: 16) {
                    Image(systemName: "film")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    Text("Drop a video file here or use File > Open")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("Supports MP4, MKV, AVI, MOV, and more")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.7))
                }
            }

            // Drag overlay
            if playerViewModel.isDraggingOver {
                DropOverlayView()
            }
        }
        .frame(minWidth: 640, minHeight: 400)
        .onDrop(of: [.fileURL], isTargeted: $playerViewModel.isDraggingOver) { providers in
            handleDrop(providers: providers)
        }
        .onTapGesture {
            if playerViewModel.isMediaLoaded {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls.toggle()
                }
                resetControlsTimer()
            }
        }
        .onHover { hovering in
            if playerViewModel.isMediaLoaded && hovering {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls = true
                }
                resetControlsTimer()
            }
        }
        .background(KeyEventHandlerView {
            handleKeyEvent($0)
        })
    }

    // MARK: - Drag and Drop

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    return
                }
                DispatchQueue.main.async {
                    playerViewModel.handleFileDrop(urls: [url])
                }
            }
        }
        return true
    }

    // MARK: - Controls Visibility

    private func resetControlsTimer() {
        controlsHideTimer?.invalidate()
        controlsHideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            if playerViewModel.isPlaying {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls = false
                }
            }
        }
    }

    // MARK: - Keyboard Shortcuts

    private func handleKeyEvent(_ event: NSEvent) {
        switch event.keyCode {
        case 49: // Space
            playerViewModel.togglePlayPause()
        case 124: // Right arrow
            playerViewModel.skipForward()
        case 123: // Left arrow
            playerViewModel.skipBackward()
        case 126: // Up arrow
            playerViewModel.setVolume(playerViewModel.volume + 0.1)
        case 125: // Down arrow
            playerViewModel.setVolume(playerViewModel.volume - 0.1)
        case 46: // M key
            playerViewModel.toggleMute()
        default:
            break
        }
    }
}

/// A view that intercepts key events for the player.
struct KeyEventHandlerView: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onKeyDown = onKeyDown
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.onKeyDown = onKeyDown
    }
}

/// Custom NSView that captures keyboard events.
class KeyCaptureView: NSView {
    var onKeyDown: ((NSEvent) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        onKeyDown?(event)
    }
}
