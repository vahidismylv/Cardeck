import UIKit

public final class CDKUndoToastView: UIView {

    public static let lifetime: TimeInterval = 5

    public var onUndo: (() -> Void)?

    public var onExpire: (() -> Void)?

    private let titleLabel = UILabel()
    private let undoButton = UIButton(type: .system)
    private var timer: Timer?

    private let message: String
    private let actionTitle: String?

    public init(message: String = "Card deleted", actionTitle: String? = "Undo") {
        self.message = message
        self.actionTitle = actionTitle
        super.init(frame: .zero)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    deinit {
        timer?.invalidate()
    }

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

        titleLabel.text = message
        titleLabel.font = CDKTheme.Font.callout
        titleLabel.textColor = CDKTheme.Color.textPrimary
        titleLabel.numberOfLines = 0

        var configuration = UIButton.Configuration.plain()
        configuration.title = actionTitle ?? ""
        configuration.baseForegroundColor = CDKTheme.Color.accent
        configuration.contentInsets = .zero
        undoButton.configuration = configuration
        undoButton.setContentHuggingPriority(.required, for: .horizontal)
        undoButton.isHidden = actionTitle == nil
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
