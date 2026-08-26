//
//  CDKCardTransitionController.swift
//  Cardeck
//

import UIKit

/// Делегат перехода карты: собирает аниматор и интерактивное закрытие.
///
/// Живёт столько же, сколько детальный экран, поэтому координатор обязан
/// держать на него сильную ссылку — иначе переход развалится на полпути.
public final class CDKCardTransitionController: NSObject,
                                                UIViewControllerTransitioningDelegate {

    private let card: CDKCardSnapshot
    private weak var wallet: CDKWalletViewController?
    private let interaction: CDKCardDismissInteraction

    private var dismissAnimator: CDKCardTransitionAnimator?

    /// Создаёт контроллер перехода для конкретной карты.
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

    /// Подключает жест протягивания к детальному экрану.
    public func attach(to detail: CDKCardDetailViewController) {
        interaction.attach(to: detail)
    }

    // MARK: - UIViewControllerTransitioningDelegate

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        // Reduce Motion: полёт карты заменяется растворением средствами системы.
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
        // Пока переход не завершился, жест считает закрытие своим и может его
        // перехватить; после завершения владение обязательно снимается.
        animator.onCompleted = { [weak self] _ in self?.interaction.dismissalDidEnd() }
        return animator
    }

    public func interactionControllerForDismissal(
        using animator: any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)? {
        interaction.isActive ? interaction : nil
    }
}
