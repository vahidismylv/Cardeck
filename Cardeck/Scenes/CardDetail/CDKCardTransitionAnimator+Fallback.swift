//
//  CDKCardTransitionAnimator+Fallback.swift
//  Cardeck
//

import UIKit

/// Запасной путь перехода.
extension CDKCardTransitionAnimator {

    /// Резервная анимация, если ячейку-источник найти не удалось.
    ///
    /// Такое возможно, когда стопка перестроилась под нами; лучше показать
    /// честное растворение, чем уронить переход.
    func makeFallbackAnimator(
        _ context: any UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) -> UIViewPropertyAnimator {
        let container = context.containerView
        let isPresenting = direction == .present
        let key: UITransitionContextViewControllerKey = isPresenting ? .to : .from
        guard let viewController = context.viewController(forKey: key) else {
            context.completeTransition(true)
            return animator
        }
        if isPresenting {
            viewController.view.frame = context.finalFrame(for: viewController)
            container.addSubview(viewController.view)
            viewController.view.alpha = 0
        }
        animator.addAnimations { viewController.view.alpha = isPresenting ? 1 : 0 }
        animator.addCompletion { position in
            let finished = position == .end
            if !isPresenting, finished {
                viewController.view.removeFromSuperview()
            }
            context.completeTransition(finished)
        }
        return animator
    }
}
