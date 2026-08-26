//
//  CDKFullScreenCodeView.swift
//  Cardeck
//

import UIKit

/// Код во весь экран на белом фоне — состояние «поднести к сканеру».
///
/// Белая подложка здесь не украшение: тёмная тема приложения снижает контраст
/// кода, а сканеры рассчитывают на светлый фон. Закрывается тапом.
public final class CDKFullScreenCodeView: UIView {

    private let imageView = UIImageView()
    private let numberLabel = UILabel()
    private let hintLabel = UILabel()
    private let aspectRatio: CGFloat

    /// Создаёт оверлей для номера и пропорций кода.
    public init(number: String, aspectRatio: CGFloat) {
        self.aspectRatio = aspectRatio
        super.init(frame: .zero)
        backgroundColor = .white
        alpha = 0

        imageView.contentMode = .scaleAspectFit
        imageView.layer.magnificationFilter = .nearest
        imageView.layer.minificationFilter = .nearest

        numberLabel.text = number
        numberLabel.font = CDKTheme.Font.mono(22, .semibold)
        numberLabel.textColor = .black
        numberLabel.textAlignment = .center
        numberLabel.numberOfLines = 0
        numberLabel.adjustsFontForContentSizeCategory = true

        hintLabel.text = "Tap to close"
        hintLabel.font = CDKTheme.Font.caption
        hintLabel.textColor = .darkGray
        hintLabel.textAlignment = .center
        hintLabel.adjustsFontForContentSizeCategory = true

        cdkAddSubview(imageView)
        cdkAddSubview(numberLabel)
        cdkAddSubview(hintLabel)

        let inset = CDKTheme.Spacing.l
        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -inset),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            imageView.heightAnchor.constraint(
                equalTo: imageView.widthAnchor, multiplier: 1 / max(aspectRatio, 0.1)
            ),

            numberLabel.topAnchor.constraint(
                equalTo: imageView.bottomAnchor, constant: CDKTheme.Spacing.l
            ),
            numberLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            numberLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),

            hintLabel.topAnchor.constraint(
                equalTo: numberLabel.bottomAnchor, constant: CDKTheme.Spacing.s
            ),
            hintLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
        isAccessibilityElement = true
        accessibilityLabel = "Barcode, \(number). Tap to close."
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    /// Показывает оверлей поверх экрана.
    public func present(over host: UIView, image: UIImage?) {
        imageView.image = image
        imageView.isHidden = image == nil
        host.cdkAddSubview(self)
        cdkPin(to: host)
        host.layoutIfNeeded()
        let animator = CDKTheme.Motion.snappy(0.3)
        animator.addAnimations { self.alpha = 1 }
        animator.startAnimation()
        UIAccessibility.post(notification: .screenChanged, argument: self)
    }

    @objc private func close() {
        let animator = CDKTheme.Motion.snappy(0.25)
        animator.addAnimations { self.alpha = 0 }
        animator.addCompletion { _ in self.removeFromSuperview() }
        animator.startAnimation()
    }
}
