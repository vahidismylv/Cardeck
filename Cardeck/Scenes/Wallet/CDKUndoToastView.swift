//
//  CDKUndoToastView.swift
//  Cardeck
//

import UIKit

/// Тост «карта удалена» с возможностью отменить действие.
///
/// Карта исчезает из стопки сразу, но из хранилища уходит только по истечении
/// окна отмены: удаление должно ощущаться мгновенным и при этом оставаться
/// обратимым.
public final class CDKUndoToastView: UIView {

    /// Сколько времени висит тост.
    public static let lifetime: TimeInterval = 5

    /// Нажата отмена.
    public var onUndo: (() -> Void)?
    /// Окно отмены истекло или тост закрыт.
    public var onExpire: (() -> Void)?

    private let titleLabel = UILabel()
    private let undoButton = UIButton(type: .system)
    private var timer: Timer?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    deinit {
        timer?.invalidate()
    }

    /// Показывает тост поверх экрана.
    public func present(in host: UIView, above guide: UILayoutGuide) {
        host.cdkAddSubview(self)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(
                equalTo: host.leadingAnchor, constant: CDKTheme.Spacing.m
            ),
            trailingAnchor.constraint(
                equalTo: host.trailingAnchor, constant: -CDKTheme.Spacing.m
            ),
            bottomAnchor.constraint(
                equalTo: guide.bottomAnchor, constant: -CDKTheme.Spacing.m
            )
        ])
        host.layoutIfNeeded()

        transform = CGAffineTransform(translationX: 0, y: bounds.height + CDKTheme.Spacing.l)
        alpha = 0
        let animator = CDKTheme.Motion.snappy()
        animator.addAnimations {
            self.transform = .identity
            self.alpha = 1
        }
        animator.startAnimation()

        timer = Timer.scheduledTimer(withTimeInterval: Self.lifetime, repeats: false) {
            [weak self] _ in
            self?.dismiss(undo: false)
        }
        UIAccessibility.post(notification: .announcement, argument: titleLabel.text)
    }

    /// Убирает тост.
    public func dismiss(undo: Bool) {
        timer?.invalidate()
        timer = nil
        let animator = CDKTheme.Motion.snappy(0.25)
        animator.addAnimations {
            self.transform = CGAffineTransform(
                translationX: 0, y: self.bounds.height + CDKTheme.Spacing.l
            )
            self.alpha = 0
        }
        animator.addCompletion { _ in
            self.removeFromSuperview()
            if undo {
                self.onUndo?()
            } else {
                self.onExpire?()
            }
        }
        animator.startAnimation()
    }

    private func setUp() {
        backgroundColor = CDKTheme.Color.surfaceElevated
        layer.cornerRadius = CDKTheme.Radius.surface
        layer.cornerCurve = .continuous

        titleLabel.text = "Card deleted"
        titleLabel.font = CDKTheme.Font.callout
        titleLabel.textColor = CDKTheme.Color.textPrimary
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0

        var configuration = UIButton.Configuration.plain()
        configuration.title = "Undo"
        configuration.baseForegroundColor = CDKTheme.Color.accent
        configuration.contentInsets = .zero
        undoButton.configuration = configuration
        undoButton.titleLabel?.adjustsFontForContentSizeCategory = true
        undoButton.setContentHuggingPriority(.required, for: .horizontal)
        undoButton.addAction(
            UIAction { [weak self] _ in self?.dismiss(undo: true) },
            for: .touchUpInside
        )

        let row = UIStackView(arrangedSubviews: [titleLabel, undoButton])
        row.alignment = .center
        row.spacing = CDKTheme.Spacing.m
        cdkAddSubview(row)
        NSLayoutConstraint.activate(row.cdkPinConstraints(to: self, inset: CDKTheme.Spacing.m))
    }
}
