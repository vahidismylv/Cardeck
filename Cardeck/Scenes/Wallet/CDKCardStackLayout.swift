//
//  CDKCardStackLayout.swift
//  Cardeck
//

import UIKit

/// Раскладка стопки карт.
///
/// Карты идут сверху вниз с базовым шагом ``CDKTheme/Card/stackStep``. Всё, что
/// уходит выше линии прижатия, сжимается в аккордеон: шаг плавно падает
/// с 62 pt до 14 pt, видимыми остаются четыре прижатые карты, остальные скрываются.
///
/// Базовые атрибуты считаются в ``prepare()`` и переиспользуются: при скролле
/// пересчитывается только зависящая от `contentOffset` часть и только для видимых
/// элементов.
public final class CDKCardStackLayout: UICollectionViewLayout {

    /// Базовые (не зависящие от прокрутки) атрибуты всех элементов.
    private var baseAttributes: [UICollectionViewLayoutAttributes] = []
    private var cachedBoundsSize: CGSize = .zero
    private var cachedItemCount = 0
    private var contentHeight: CGFloat = 0

    /// Ширина карты в текущей раскладке.
    public private(set) var cardSize: CGSize = .zero

    /// Индекс элемента, поднятого пальцем; у него усиленная тень и масштаб.
    public var liftedIndexPath: IndexPath? {
        didSet {
            guard liftedIndexPath != oldValue else { return }
            invalidateLayout()
        }
    }

    /// Индекс карты, вокруг которой стопка расходится на время перехода.
    public var revealAnchorItem: Int?

    /// Насколько стопка разошлась: 0 — на месте, 1 — карты ниже якоря убраны.
    public var revealProgress: CGFloat = 0 {
        didSet {
            guard revealProgress != oldValue else { return }
            invalidateLayout()
        }
    }

    /// Высота плавающего заголовка экрана: под ним прижимаются карты.
    public var headerHeight: CGFloat = 0 {
        didSet {
            guard headerHeight != oldValue else { return }
            baseAttributes.removeAll()
            invalidateLayout()
        }
    }

    // MARK: - Геометрия

    private var horizontalInset: CGFloat { CDKTheme.Card.stackHorizontalInset }
    /// Видимая полоса карты растёт вместе с Dynamic Type: при крупных размерах
    /// название с категорией в исходные 62 pt просто не помещаются.
    private var step: CGFloat {
        let metrics = UIFontMetrics(forTextStyle: .title2)
        return min(metrics.scaledValue(for: CDKTheme.Card.stackStep), CDKTheme.Card.stackStep * 2)
    }
    private var pinnedStep: CGFloat { CDKTheme.Card.pinnedStep }

    /// Высота аккордеона из прижатых карт.
    ///
    /// Прижатая стопка растёт вверх от линии прижатия, поэтому линия должна стоять
    /// ровно на эту высоту ниже заголовка — иначе аккордеон уезжает под него
    /// и его просто не видно.
    private var pileHeight: CGFloat {
        CDKCardStackGeometry.displacement(
            progress: CGFloat(CDKTheme.Card.maxPinnedCards),
            step: step,
            pinnedStep: pinnedStep,
            limit: CGFloat(CDKTheme.Card.maxPinnedCards)
        )
    }

    /// Отступ от верха экрана до позиции покоя первой карты.
    ///
    /// Совпадает с линией прижатия: в состоянии покоя ни одна карта не прижата.
    private var topInset: CGFloat {
        (collectionView?.safeAreaInsets.top ?? 0)
            + headerHeight
            + CDKTheme.Card.pinInset
            + pileHeight
    }

    private var bottomInset: CGFloat {
        (collectionView?.safeAreaInsets.bottom ?? 0) + CDKTheme.Spacing.xl * 2
    }

    /// Линия, на которой стоит последняя прижавшаяся карта, в координатах контента.
    private var pinLine: CGFloat {
        guard let collectionView else { return 0 }
        return collectionView.contentOffset.y + topInset
    }

    // MARK: - UICollectionViewLayout

    public override var collectionViewContentSize: CGSize {
        CGSize(width: collectionView?.bounds.width ?? 0, height: contentHeight)
    }

    public override func prepare() {
        super.prepare()
        guard let collectionView else { return }
        // Во время batch-обновления секций может ещё не быть — спрашивать нельзя.
        let count = collectionView.numberOfSections > 0
            ? collectionView.numberOfItems(inSection: 0)
            : 0
        let size = collectionView.bounds.size

        // Пересчёт только при смене размера или количества карт.
        guard size != cachedBoundsSize || count != cachedItemCount || baseAttributes.isEmpty
        else { return }

        cachedBoundsSize = size
        cachedItemCount = count

        cardSize = CDKCardStackGeometry.cardSize(
            in: size,
            horizontalInset: horizontalInset,
            topInset: topInset,
            bottomSafeArea: collectionView.safeAreaInsets.bottom
        )
        let cardOriginX = ((size.width - cardSize.width) / 2).rounded()

        baseAttributes = (0..<count).map { item in
            let indexPath = IndexPath(item: item, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = CGRect(
                x: cardOriginX,
                y: topInset + CGFloat(item) * step,
                width: cardSize.width,
                height: cardSize.height
            )
            attributes.zIndex = item
            return attributes
        }

        contentHeight = count == 0
            ? 0
            : topInset + CGFloat(count - 1) * step + cardSize.height + bottomInset
    }

    public override func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes]? {
        guard !baseAttributes.isEmpty else { return nil }
        return visibleRange().compactMap { item in
            let attributes = pinnedAttributes(forItemAt: item)
            guard !attributes.isHidden, attributes.frame.intersects(rect) else { return nil }
            return attributes
        }
    }

    public override func layoutAttributesForItem(
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard indexPath.item < baseAttributes.count else { return nil }
        return pinnedAttributes(forItemAt: indexPath.item)
    }

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }

    public override func invalidationContext(
        forBoundsChange newBounds: CGRect
    ) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        // Размер поменялся — пусть отработает полный пересчёт в prepare().
        guard newBounds.size == cachedBoundsSize else { return context }
        // Иначе трогаем только видимые элементы: invalidateEverything остаётся false.
        let paths = visibleRange(for: newBounds).map { IndexPath(item: $0, section: 0) }
        if !paths.isEmpty {
            context.invalidateItems(at: paths)
        }
        return context
    }

    // MARK: - Прижатие и глубина

    /// Убирает карты ниже якоря, пока открывается карта перехода: чем дальше
    /// карта от якоря, тем сильнее она уезжает — стопка расходится веером.
    private func applyReveal(to attributes: UICollectionViewLayoutAttributes, item: Int) {
        guard revealProgress > 0, let anchor = revealAnchorItem, item > anchor else { return }
        attributes.frame.origin.y +=
            CDKCardStackGeometry.revealShift(step: item - anchor) * revealProgress
        attributes.alpha *= 1 - revealProgress
    }

    /// Диапазон элементов, которые могут оказаться на экране при текущем смещении.
    private func visibleRange(for bounds: CGRect? = nil) -> Range<Int> {
        guard let collectionView, cachedItemCount > 0 else { return 0..<0 }
        let frame = bounds ?? collectionView.bounds
        let line = frame.minY + topInset
        // Сколько карт уже ушло выше линии прижатия.
        let passed = Int(floor((line - topInset) / step)) + 1
        // Запас в 6 карт покрывает окно прижатия и карту, частично видимую сверху.
        let lower = max(0, min(passed, cachedItemCount) - 6)
        let upper = Int(ceil((frame.maxY - topInset) / step)) + 1
        return lower..<max(lower, min(cachedItemCount, max(upper, 0)))
    }

    /// Атрибуты элемента с учётом прижатия, глубины и подъёма пальцем.
    private func pinnedAttributes(forItemAt item: Int) -> UICollectionViewLayoutAttributes {
        // swiftlint:disable:next force_cast
        let attributes = baseAttributes[item].copy() as! UICollectionViewLayoutAttributes

        let progress = (pinLine - attributes.frame.minY) / step
        let maxPinned = CGFloat(CDKTheme.Card.maxPinnedCards)

        if progress > 0 {
            // Прижатая карта встаёт на фиксированное расстояние выше линии прижатия.
            attributes.frame.origin.y = pinLine - CDKCardStackGeometry.displacement(
                progress: progress,
                step: step,
                pinnedStep: pinnedStep,
                limit: maxPinned
            )
        }

        let depth = progress.cdkClamped(0, maxPinned)
        let scale = 1 - (1 - CDKTheme.Card.deepestScale) * (depth / maxPinned)

        // Пятая прижатая карта гаснет, за ней — скрывается совсем.
        if progress > maxPinned {
            let fade = (progress - maxPinned).cdkClamped(0, 1)
            attributes.alpha = 1 - (1 - CDKTheme.Card.fadedAlpha) * fade
            attributes.isHidden = progress > maxPinned + 1
        } else {
            attributes.alpha = 1
            attributes.isHidden = false
        }

        applyReveal(to: attributes, item: item)

        let lifted = attributes.indexPath == liftedIndexPath
        var transform = CATransform3DIdentity
        transform.m34 = CDKTheme.Card.perspective
        transform = CATransform3DTranslate(transform, 0, 0, -depth * CDKTheme.Card.depthZStep)
        let finalScale = lifted ? CDKTheme.Card.liftedScale : scale
        attributes.transform3D = CATransform3DScale(transform, finalScale, finalScale, 1)
        if lifted {
            attributes.zIndex = cachedItemCount + 1
        }
        return attributes
    }
}
