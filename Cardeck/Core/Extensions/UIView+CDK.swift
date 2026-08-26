//
//  UIView+CDK.swift
//  Cardeck
//

import UIKit

public extension UIView {

    /// Добавляет subview, отключая авторезайзинг-маску: вся вёрстка идёт кодом.
    func cdkAddSubview(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
    }

    /// Прижимает вью к краям указанной области с одинаковым отступом.
    func cdkPin(to guide: UILayoutGuide, inset: CGFloat = 0) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: inset),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -inset),
            topAnchor.constraint(equalTo: guide.topAnchor, constant: inset),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -inset)
        ])
    }

    /// Прижимает вью к краям родителя с одинаковым отступом.
    func cdkPin(to view: UIView, inset: CGFloat = 0) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -inset),
            topAnchor.constraint(equalTo: view.topAnchor, constant: inset),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -inset)
        ])
    }
}

public extension CALayer {

    /// Выставляет параметры тени карты вместе с `shadowPath`.
    ///
    /// `shadowPath` обязателен: без него каждый кадр уходит в offscreen-проход.
    func cdkApplyCardShadow(cornerRadius: CGFloat, lifted: Bool = false) {
        shadowColor = CDKTheme.Shadow.color
        shadowOffset = lifted ? CDKTheme.Shadow.liftedOffset : CDKTheme.Shadow.offset
        shadowRadius = (lifted ? CDKTheme.Shadow.liftedBlur : CDKTheme.Shadow.blur) / 2
        shadowOpacity = lifted ? CDKTheme.Shadow.liftedOpacity : CDKTheme.Shadow.opacity
        shouldRasterize = false
        shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    }
}

public extension CGFloat {

    /// Ограничение значения диапазоном.
    func cdkClamped(_ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        Swift.min(Swift.max(self, lower), upper)
    }
}
