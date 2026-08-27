import UIKit

public final class CDKStackRevealAnimator {

    private weak var collectionView: UICollectionView?
    private weak var layout: CDKCardStackLayout?
    private var animator: UIViewPropertyAnimator?

    public init(collectionView: UICollectionView, layout: CDKCardStackLayout) {
        self.collectionView = collectionView
        self.layout = layout
    }

    public func reveal(around item: Int) {
        layout?.revealAnchorItem = item
        animate(to: 1)
    }

    public func collapse() {
        animate(to: 0)
    }

    public func reset() {
        animator?.stopAnimation(true)
        animator = nil
        layout?.revealProgress = 0
        layout?.revealAnchorItem = nil
        collectionView?.layoutIfNeeded()
    }

    private func animate(to target: CGFloat) {
        guard let layout, let collectionView, layout.revealProgress != target else { return }
        animator?.stopAnimation(true)
        let animator = CDKTheme.Motion.transition()
        animator.addAnimations {
            layout.revealProgress = target
            collectionView.layoutIfNeeded()
        }
        animator.addCompletion { [weak self] _ in
            self?.animator = nil
            guard target == 0 else { return }
            layout.revealAnchorItem = nil
        }
        self.animator = animator
        animator.startAnimation()
    }
}
