//
//  CDKStackRevealAnimator.swift
//  Cardeck
//

import UIKit

/// Разводит стопку в стороны на время перехода карты.
///
/// Смещение живёт в раскладке, а не в трансформах ячеек: `UICollectionView`
/// переприменяет `layoutAttributes` на каждом проходе вёрстки и стёр бы любой
/// трансформ, выставленный снаружи, — из-за чего соседние карты просто стояли
/// на месте, пока карта улетала.
///
/// Анимирует Core Animation, а не покадровый `CADisplayLink`: на старте перехода
/// главный поток занят поднятием детального экрана, и покадровый драйвер там
/// голодает — карта улетала плавно, а стопка дёргалась одним рывком в конце.
/// Расплата за это — общий тайминг на все карты: разлёт волной задаётся только
/// разной дистанцией, а не разным временем старта.
public final class CDKStackRevealAnimator {

    private weak var collectionView: UICollectionView?
    private weak var layout: CDKCardStackLayout?
    private var animator: UIViewPropertyAnimator?

    /// Создаёт аниматор для стопки.
    public init(collectionView: UICollectionView, layout: CDKCardStackLayout) {
        self.collectionView = collectionView
        self.layout = layout
    }

    /// Разводит стопку вокруг карты с указанным индексом.
    public func reveal(around item: Int) {
        layout?.revealAnchorItem = item
        animate(to: 1)
    }

    /// Собирает стопку обратно.
    public func collapse() {
        animate(to: 0)
    }

    /// Мгновенно возвращает стопку в исходное состояние.
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
