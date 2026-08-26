//
//  CDKCardStackGeometry.swift
//  Cardeck
//

import UIKit

/// Чистая геометрия стопки карт.
///
/// Вынесена из ``CDKCardStackLayout`` отдельно: это функции без состояния,
/// их удобно проверять юнит-тестами, не поднимая `UICollectionView`.
public nonisolated enum CDKCardStackGeometry {

    /// Размер карты для заданного размера коллекции.
    ///
    /// Обычно ширину задаёт экран. Если карта, посчитанная от ширины, не влезает
    /// по высоте (узкий экран, крупный заголовок), размер задаёт доступная высота,
    /// а карта центрируется по горизонтали.
    ///
    /// - Returns: размер карты с соотношением ``CDKTheme/Card/aspectRatio``.
    public static func cardSize(
        in bounds: CGSize,
        horizontalInset: CGFloat,
        topInset: CGFloat,
        bottomSafeArea: CGFloat
    ) -> CGSize {
        let widthLimited = max(bounds.width - horizontalInset * 2, 1)
        let availableHeight = bounds.height - topInset - bottomSafeArea - CDKTheme.Spacing.l
        let heightLimited = max(availableHeight, 1) * CDKTheme.Card.aspectRatio
        let width = min(widthLimited, heightLimited).rounded()
        return CGSize(width: width, height: CDKTheme.Card.height(forWidth: width))
    }


    /// Насколько карта уезжает вниз, освобождая место открывающейся карте.
    ///
    /// - Parameter step: расстояние в позициях от открываемой карты, начиная с 1.
    public static func revealShift(step: Int) -> CGFloat {
        120 + CGFloat(max(step - 1, 0)) * 20
    }

    /// Расстояние от линии прижатия до верха прижатой карты.
    ///
    /// Шаг между прижатыми картами непрерывно падает с `step` до `pinnedStep`
    /// на первой ступени (easeOut), дальше остаётся постоянным и перестаёт расти
    /// после `limit` карт. В точке `progress == 0` функция и её производная совпадают
    /// с обычной стопкой, поэтому на границе прижатия карты не дёргаются.
    ///
    /// - Parameters:
    ///   - progress: сколько базовых шагов карта прошла выше линии прижатия.
    ///   - step: базовый шаг стопки.
    ///   - pinnedStep: минимальный шаг между прижатыми картами.
    ///   - limit: максимум прижатых карт.
    /// - Returns: смещение вверх от линии прижатия в точках, всегда неотрицательное.
    public static func displacement(
        progress: CGFloat,
        step: CGFloat,
        pinnedStep: CGFloat,
        limit: CGFloat
    ) -> CGFloat {
        guard progress > 0 else { return 0 }
        let amplitude = step - pinnedStep
        let clamped = min(progress, limit)
        if clamped <= 1 {
            let eased = 1 - pow(1 - clamped, 3)
            return pinnedStep * clamped + amplitude / 3 * eased
        }
        let firstStep = pinnedStep + amplitude / 3
        return firstStep + pinnedStep * (clamped - 1)
    }
}
