import UIKit

public final class CDKCardTransitionController: NSObject,
                                                UIViewControllerTransitioningDelegate {

    private let card: CDKCardSnapshot
    private weak var wallet: CDKWalletViewController?
    private let interaction: CDKCardDismissInteraction

    private var dismissAnimator: CDKCardTransitionAnimator?

    public init(
        card: CDKCardSnapshot,
        wallet: CDKWalletViewController?,
        haptics: CDKHapticsServiceProtocol
    ) {
        self.card = card
        self.wallet = wallet
        self.interaction = CDKCardDismissInteraction(haptics: haptics)
        super.init()
    }

    public func attach(to detail: CDKCardDetailViewController) {
        interaction.attach(to: detail)
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {

        guard !UIAccessibility.isReduceMotionEnabled else { return nil }
        return CDKCardTransitionAnimator(direction: .present, card: card, wallet: wallet)
    }

    public func animationController(
        forDismissed dismissed: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        guard !UIAccessibility.isReduceMotionEnabled else { return nil }
        let animator = CDKCardTransitionAnimator(
            direction: .dismiss, card: card, wallet: wallet
        )
        dismissAnimator = animator
        interaction.animatorProvider = { [weak animator] in animator?.propertyAnimator }

        animator.onCompleted = { [weak self] _ in self?.interaction.dismissalDidEnd() }
        return animator
    }

    public func interactionControllerForDismissal(
        using animator: any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)? {
        interaction.isActive ? interaction : nil
    }
}
