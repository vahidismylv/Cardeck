import UIKit

extension CDKWalletViewController {

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

    func rebuildCards() {
        for cell in collectionView.visibleCells {
            guard let cardCell = cell as? CDKCardCell else { continue }
            cardCell.prepareForReuse()
        }
        model.reload()
    }

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
