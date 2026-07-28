import SwiftUI

/// Overlay view that renders subtitle text on top of the video.
struct SubtitleOverlayView: View {
    let text: String

    /// Font size for subtitle text.
    private let fontSize: CGFloat = 22

    /// Text color for subtitles.
    private let textColor: Color = .white

    /// Background color behind subtitle text.
    private let backgroundColor: Color = Color.black.opacity(0.6)

    /// Corner radius for subtitle background.
    private let cornerRadius: CGFloat = 6

    /// Bottom padding from the video edge.
    private let bottomPadding: CGFloat = 60

    var body: some View {
        VStack {
            Spacer()

            if !text.isEmpty {
                Text(text)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(backgroundColor)
                    )
                    .padding(.horizontal, 40)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
        }
        .padding(.bottom, bottomPadding)
        .allowsHitTesting(false)
    }
}
