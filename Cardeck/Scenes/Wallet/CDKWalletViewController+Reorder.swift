//
//  CDKWalletViewController+Reorder.swift
//  Cardeck
//

import UIKit

/// Перетаскивание карт в стопке.
///
/// Карта поднимается системным лифтом до масштаба ``CDKTheme/Card/liftedScale``
/// и получает усиленную тень; при защёлкивании в новую позицию играет паттерн snap.
extension CDKWalletViewController: UICollectionViewDragDelegate {

    public func collectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: any UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        guard model.isReorderingEnabled, let card = model.card(at: indexPath.item) else {
            return []
        }
        stackLayout.liftedIndexPath = indexPath
        (collectionView.cellForItem(at: indexPath) as? CDKCardCell)?.setLifted(true)
        hapticsService.beginDrag()
        hapticsService.updateDrag(progress: 0.5)

        let provider = NSItemProvider(object: card.id.uuidString as NSString)
        let item = UIDragItem(itemProvider: provider)
        item.localObject = card
        return [item]
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        dragPreviewParametersForItemAt indexPath: IndexPath
    ) -> UIDragPreviewParameters? {
        previewParameters(for: collectionView, at: indexPath)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        dragSessionDidEnd session: any UIDragSession
    ) {
        endLift(in: collectionView)
    }

    /// Скруглённый контур превью: без него система рисует прямоугольную подложку.
    private func previewParameters(
        for collectionView: UICollectionView,
        at indexPath: IndexPath
    ) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return nil }
        let parameters = UIDragPreviewParameters()
        let path = UIBezierPath(
            roundedRect: cell.bounds,
            cornerRadius: CDKTheme.Radius.card
        )
        parameters.visiblePath = path
        parameters.shadowPath = path
        parameters.backgroundColor = .clear
        return parameters
    }

    /// Снимает подъём с карты и гасит непрерывную отдачу.
    private func endLift(in collectionView: UICollectionView) {
        if let lifted = stackLayout.liftedIndexPath {
            (collectionView.cellForItem(at: lifted) as? CDKCardCell)?.setLifted(false)
        }
        stackLayout.liftedIndexPath = nil
        hapticsService.endDrag()
    }
}

extension CDKWalletViewController: UICollectionViewDropDelegate {

    public func collectionView(
        _ collectionView: UICollectionView,
        canHandle session: any UIDropSession
    ) -> Bool {
        model.isReorderingEnabled
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: any UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        guard session.localDragSession != nil else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        performDropWith coordinator: any UICollectionViewDropCoordinator
    ) {
        guard let item = coordinator.items.first,
              let source = item.sourceIndexPath else {
            endLift(in: collectionView)
            return
        }
        let destination = coordinator.destinationIndexPath
            ?? IndexPath(item: max(model.cards.count - 1, 0), section: 0)

        model.move(from: source.item, to: destination.item)
        coordinator.drop(item.dragItem, toItemAt: destination)
        hapticsService.playSnap()
        endLift(in: collectionView)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        dropPreviewParametersForItemAt indexPath: IndexPath
    ) -> UIDragPreviewParameters? {
        previewParameters(for: collectionView, at: indexPath)
    }
}
