//
//  CDKWalletViewController+Transition.swift
//  Cardeck
//

import UIKit

/// Поддержка перехода в детальный экран со стороны стопки.
extension CDKWalletViewController {

    /// Разводит или собирает соседние карты ниже источника.
    ///
    /// Работа делается раскладкой через ``CDKStackRevealAnimator``: трансформы,
    /// выставленные прямо на ячейках, стираются на следующем проходе вёрстки.
    /// При включённом Reduce Motion стопка не двигается вовсе.
    func animateNeighbours(of card: CDKCardSnapshot, away: Bool) {
        guard !UIAccessibility.isReduceMotionEnabled else {
            stackReveal.reset()
            return
        }
        guard away else {
            stackReveal.collapse()
            return
        }
        guard let index = model.cards.firstIndex(where: { $0.id == card.id }) else { return }
        stackReveal.reveal(around: index)
    }

    /// Приводит карту в видимую область — нужно перед закрытием детального экрана,
    /// если стопку успели прокрутить и ячейка-источник уехала за экран.
    func revealCard(_ card: CDKCardSnapshot) {
        guard cell(for: card) == nil,
              let index = model.cards.firstIndex(where: { $0.id == card.id }) else { return }
        collectionView.scrollToItem(
            at: IndexPath(item: index, section: 0),
            at: .centeredVertically,
            animated: false
        )
        collectionView.layoutIfNeeded()
    }

    /// Пересобирает все ячейки заново.
    ///
    /// Нужен после смены настройки голографического эффекта: материал выбирается
    /// один раз при создании ячейки и сам о переключении не узнает.
    func rebuildCards() {
        for cell in collectionView.visibleCells {
            guard let cardCell = cell as? CDKCardCell else { continue }
            cardCell.prepareForReuse()
        }
        model.reload()
    }

    /// Возвращает стопку в нормальное состояние после перехода.
    ///
    /// Страховка на случай прерванной анимации: собирает разъезд, поднимает
    /// прозрачность ячейки-источника и восстанавливает материал, если тот остался
    /// в контейнере перехода. Без этого одна сорвавшаяся анимация ломала бы стопку
    /// до перезапуска приложения.
    func resetNeighbours() {
        stackReveal.reset()
        for cell in collectionView.visibleCells {
            cell.transform = .identity
            cell.alpha = 1
            guard let cardCell = cell as? CDKCardCell, cardCell.materialView == nil,
                  let card = card(for: cardCell) else { continue }
            cardCell.configure(with: card)
        }
    }
}
