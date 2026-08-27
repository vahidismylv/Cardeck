import UIKit

public final class CDKCardDismissInteraction: UIPercentDrivenInteractiveTransition,
                                              UIGestureRecognizerDelegate {

    private static let completionThreshold: CGFloat = 0.4

    private static let completionVelocity: CGFloat = 800

    private static let travelFraction: CGFloat = 0.6

    public private(set) var isActive = false

    var animatorProvider: (() -> UIViewPropertyAnimator?)?

    private let haptics: CDKHapticsServiceProtocol
    private weak var detail: CDKCardDetailViewController?
    private weak var scrollView: UIScrollView?
    private var isDriving = false

    private var ownsRunningDismissal = false

    public init(haptics: CDKHapticsServiceProtocol) {
        self.haptics = haptics
        super.init()

        wantsInteractiveStart = true
    }

    public func attach(to detail: CDKCardDetailViewController) {
        self.detail = detail
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pan.delegate = self
        detail.view.addGestureRecognizer(pan)
        scrollView = detail.view.cdkFirstScrollView
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let detail else { return }
        let translation = gesture.translation(in: detail.view)
        let velocity = gesture.velocity(in: detail.view)
        let distance = max(detail.view.bounds.height * Self.travelFraction, 1)

        switch gesture.state {
        case .began:
            interceptRunningAnimator()
        case .changed:
            guard isDriving else {
                startDrivingIfPossible(gesture, translation: translation, in: detail)
                return
            }
            let progress = (max(0, translation.y) / distance).cdkClamped(0, 1)
            update(progress)
            haptics.updateDrag(progress: Double(progress))
        case .ended, .cancelled, .failed:
            guard isDriving else { return }
            let progress = (max(0, translation.y) / distance).cdkClamped(0, 1)
            complete(progress: progress, velocity: velocity, distance: distance)
        default:
            break
        }
    }

    func dismissalDidEnd() {
        ownsRunningDismissal = false
        isDriving = false
        isActive = false
        scrollView?.isScrollEnabled = true
    }

    private func interceptRunningAnimator() {
        guard ownsRunningDismissal,
              let animator = animatorProvider?(), animator.isRunning else { return }
        pause()
        isDriving = true
        isActive = true
    }

    private func startDrivingIfPossible(
        _ gesture: UIPanGestureRecognizer,
        translation: CGPoint,
        in detail: CDKCardDetailViewController
    ) {
        guard translation.y > 0, translation.y > abs(translation.x), isScrollAtTop else { return }

        guard !ownsRunningDismissal,
              detail.transitionCoordinator == nil,
              !detail.isBeingPresented,
              !detail.isBeingDismissed,
              detail.presentingViewController != nil else { return }
        ownsRunningDismissal = true
        isDriving = true
        isActive = true
        haptics.beginDrag()

        scrollView?.panGestureRecognizer.isEnabled = false
        scrollView?.panGestureRecognizer.isEnabled = true
        scrollView?.isScrollEnabled = false

        gesture.setTranslation(.zero, in: detail.view)
        detail.dismiss(animated: true)
    }

    private func complete(progress: CGFloat, velocity: CGPoint, distance: CGFloat) {
        haptics.endDrag()

        isDriving = false
        isActive = false
        scrollView?.isScrollEnabled = true
        let shouldFinish = progress > Self.completionThreshold
            || velocity.y > Self.completionVelocity

        let remaining = max(distance * (shouldFinish ? (1 - progress) : progress), 1)
        timingCurve = UISpringTimingParameters(
            mass: CDKTheme.Motion.transitionMass,
            stiffness: CDKTheme.Motion.transitionStiffness,
            damping: CDKTheme.Motion.transitionDamping,
            initialVelocity: CGVector(dx: 0, dy: abs(velocity.y) / remaining)
        )
        if shouldFinish {
            finish()
        } else {
            cancel()
        }
    }

    private var isScrollAtTop: Bool {
        guard let scrollView else { return true }
        return scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 0.5
    }

    public func gestureRecognizer(
        _ gesture: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {

        other === scrollView?.panGestureRecognizer
    }
}

extension UIView {

    var cdkFirstScrollView: UIScrollView? {
        if let scrollView = self as? UIScrollView { return scrollView }
        for subview in subviews {
            if let found = subview.cdkFirstScrollView { return found }
        }
        return nil
    }
}
