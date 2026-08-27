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
        step: CGFloat,
        pinnedStep: CGFloat,
        limit: CGFloat
    ) -> CGFloat {
        guard progress > 0 else { return 0 }
        let amplitude = step - pinnedStep
        let clamped = min(progress, limit)
        if clamped <= 1 {
            let eased = 1 - pow(1 - clamped, 3)
            return pinnedStep * clamped + amplitude / 3 * eased
        }
        let firstStep = pinnedStep + amplitude / 3
        return firstStep + pinnedStep * (clamped - 1)
    }
}
