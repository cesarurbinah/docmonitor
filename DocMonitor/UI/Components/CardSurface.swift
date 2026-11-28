import SwiftUI

extension View {
    @ViewBuilder
    func cardSurface(cornerRadius: CGFloat = 12) -> some View {
        if #available(macOS 27, *) {
            background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.white.opacity(AppSurface.cardFill))
                    .strokeBorder(.white.opacity(AppSurface.cardStroke), lineWidth: 0.5)
            )
        } else {
            glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}
