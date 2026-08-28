import UIKit

public nonisolated enum CDKCardStackGeometry {

    public static func cardSize(
        in bounds: CGSize,
        horizontalInset: CGFloat,
        topInset: CGFloat,
        bottomSafeArea: CGFloat
    ) -> CGSize {
        let widthLimited = max(bounds.width - horizontalInset * 2, 1)
        let availableHeight = bounds.height - topInset - bottomSafeArea - CDKTheme.Spacing.l
        let heightLimited = max(availableHeight, 1) * CDKTheme.Card.aspectRatio
        let width = min(widthLimited, heightLimited).rounded()
        return CGSize(width: width, height: CDKTheme.Card.height(forWidth: width))
    }

    public static func revealShift(step: Int) -> CGFloat {
        120 + CGFloat(max(step - 1, 0)) * 20
    }

    public static func displacement(
        progress: CGFloat,
        pinnedStep: CGFloat,
        limit: CGFloat
    ) -> CGFloat {
        guard progress > 0 else { return 0 }
        return pinnedStep * min(progress, limit)
    }
}
