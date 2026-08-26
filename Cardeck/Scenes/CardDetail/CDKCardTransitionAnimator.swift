//
//  CDKCardTransitionAnimator.swift
//  Cardeck
//

import UIKit

/// Анимация перехода карты между стопкой и детальным экраном.
///
/// В `containerView` летит настоящая карта: ``CDKCardMaterialView`` переносится
/// из ячейки (снимок заморозил бы голограмму), а поверх него — те же подписи,
/// что и в стопке. Без подписей карта на всё время полёта оставалась безымянной,
/// и название «моргало» в конце перехода.
final class CDKCardTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    enum Direction { case present, dismiss }

    let direction: Direction
    private let card: CDKCardSnapshot
    private weak var wallet: CDKWalletViewController?

    /// Текущий аниматор перехода — интерактивное закрытие ставит его на паузу.
    private(set) var propertyAnimator: UIViewPropertyAnimator?

    /// Вызывается по фактическому завершению перехода в любую сторону.
    var onCompleted: ((UIViewAnimatingPosition) -> Void)?

    init(direction: Direction, card: CDKCardSnapshot, wallet: CDKWalletViewController?) {
        self.direction = direction
        self.card = card
        self.wallet = wallet
    }

    func transitionDuration(
        using transitionContext: (any UIViewControllerContextTransitioning)?
    ) -> TimeInterval {
        CDKTheme.Motion.transitionDuration
    }

    func animateTransition(using context: any UIViewControllerContextTransitioning) {
        let animator = interruptibleAnimator(using: context)
        animator.startAnimation()
    }

    func interruptibleAnimator(
        using context: any UIViewControllerContextTransitioning
    ) -> any UIViewImplicitlyAnimating {
        if let propertyAnimator { return propertyAnimator }
        let animator = direction == .present
            ? makePresentAnimator(context)
            : makeDismissAnimator(context)
        animator.addCompletion { [weak self] position in
            self?.propertyAnimator = nil
            self?.onCompleted?(position)
        }
        propertyAnimator = animator
        return animator
    }

    // MARK: - Открытие

    private func makePresentAnimator(
        _ context: any UIViewControllerContextTransitioning
    ) -> UIViewPropertyAnimator {
        let container = context.containerView
        let animator = CDKTheme.Motion.transition()

        guard let detail = context.viewController(forKey: .to) as? CDKCardDetailViewController,
              let wallet,
              let cell = wallet.cell(for: card),
              let material = cell.detachMaterialView() else {
            return makeFallbackAnimator(context, animator: animator)
        }

        detail.view.frame = context.finalFrame(for: detail)
        container.addSubview(detail.view)
        detail.view.layoutIfNeeded()
        detail.view.alpha = 0
        detail.cardView.setLabelsVisible(false)
        prepareContent(of: detail)

        let startFrame = wallet.collectionView.convert(cell.frame, to: container)
        let targetFrame = detail.cardView.convert(detail.cardView.bounds, to: container)
        let flying = makeFlyingCard(
            material: material,
            frame: startFrame,
            cornerRadius: CDKTheme.Radius.card,
            in: container
        )
        cell.alpha = 0
        wallet.animateNeighbours(of: card, away: true)

        animator.addAnimations {
            flying.frame = targetFrame
            detail.view.alpha = 1
        }
        flying.cornerRadius = CDKTheme.Radius.cardExpanded
        material.animateCornerRadius(
            from: CDKTheme.Radius.card,
            to: CDKTheme.Radius.cardExpanded
        )
        revealContent(of: detail)

        animator.addCompletion { position in
            _ = flying.detachMaterial()
            flying.removeFromSuperview()
            if position == .end {
                detail.cardView.attach(material)
                detail.cardView.setLabelsVisible(true)
                context.completeTransition(true)
            } else {
                cell.reclaimMaterialView(material)
                cell.alpha = 1
                wallet.animateNeighbours(of: self.card, away: false)
                detail.view.removeFromSuperview()
                context.completeTransition(false)
            }
        }
        return animator
    }

    // MARK: - Закрытие

    private func makeDismissAnimator(
        _ context: any UIViewControllerContextTransitioning
    ) -> UIViewPropertyAnimator {
        let container = context.containerView
        let animator = CDKTheme.Motion.transition()

        guard let detail = context.viewController(forKey: .from) as? CDKCardDetailViewController,
              let wallet else {
            return makeFallbackAnimator(context, animator: animator)
        }
        wallet.revealCard(card)
        guard let cell = wallet.cell(for: card),
              let material = detail.cardView.detachMaterial() else {
            return makeFallbackAnimator(context, animator: animator)
        }

        let startFrame = detail.cardView.convert(detail.cardView.bounds, to: container)
        let targetFrame = wallet.collectionView.convert(cell.frame, to: container)
        let flying = makeFlyingCard(
            material: material,
            frame: startFrame,
            cornerRadius: CDKTheme.Radius.cardExpanded,
            in: container
        )
        cell.alpha = 0

        // Контент гаснет внутри основного аниматора, а не отдельным: при отмене
        // жеста UIKit разворачивает именно этот аниматор, и всё, что анимировано
        // снаружи, осталось бы в погашенном состоянии.
        animator.addAnimations {
            flying.frame = targetFrame
            detail.view.alpha = 0
            for view in detail.animatableContent {
                view.alpha = 0
                view.transform = CGAffineTransform(translationX: 0, y: 24)
            }
        }
        flying.cornerRadius = CDKTheme.Radius.card
        material.animateCornerRadius(
            from: CDKTheme.Radius.cardExpanded,
            to: CDKTheme.Radius.card
        )
        wallet.animateNeighbours(of: card, away: false)

        animator.addCompletion { position in
            _ = flying.detachMaterial()
            flying.removeFromSuperview()
            if position == .end {
                cell.reclaimMaterialView(material)
                cell.alpha = 1
                detail.view.removeFromSuperview()
                context.completeTransition(true)
            } else {
                detail.cardView.attach(material)
                detail.cardView.setLabelsVisible(true)
                detail.view.alpha = 1
                detail.restoreAfterCancelledDismissal()
                cell.alpha = 0
                wallet.animateNeighbours(of: self.card, away: true)
                context.completeTransition(false)
            }
        }
        return animator
    }

    // MARK: - Общее

    /// Собирает карту, которая летит в `containerView`: материал плюс подписи.
    private func makeFlyingCard(
        material: CDKCardMaterialView,
        frame: CGRect,
        cornerRadius: CGFloat,
        in container: UIView
    ) -> CDKDetailCardView {
        let flying = CDKDetailCardView()
        flying.cornerRadius = cornerRadius
        flying.configure(with: card)
        flying.translatesAutoresizingMaskIntoConstraints = true
        flying.frame = frame
        container.addSubview(flying)
        flying.attach(material)
        flying.layoutIfNeeded()
        return flying
    }

    private func prepareContent(of detail: CDKCardDetailViewController) {
        for view in detail.animatableContent {
            view.alpha = 0
            view.transform = CGAffineTransform(translationX: 0, y: 24)
        }
    }

    /// Контент детального экрана появляется вторым аниматором с задержкой:
    /// карта успевает долететь, и только потом под ней проявляется панель кода.
    private func revealContent(of detail: CDKCardDetailViewController) {
        let animator = CDKTheme.Motion.transition()
        animator.addAnimations {
            for view in detail.animatableContent {
                view.alpha = 1
                view.transform = .identity
            }
        }
        animator.startAnimation(afterDelay: CDKTheme.Motion.contentDelay)
    }
}
