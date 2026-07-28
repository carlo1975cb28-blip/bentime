import SwiftUI

/// Visual indicator shown when a user drags a file over the application window.
struct DropOverlayView: View {
    @State private var isAnimating: Bool = false

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            // Drop zone indicator
            VStack(spacing: 20) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.white)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                Text("Drop to Open")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text("Video or Subtitle File")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.6), style: StrokeStyle(lineWidth: 3, dash: [10]))
            )
        }
        .allowsHitTesting(false)
        .onAppear {
            isAnimating = true
        }
    }
}
