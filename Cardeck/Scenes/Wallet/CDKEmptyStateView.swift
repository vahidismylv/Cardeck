import UIKit

public final class CDKEmptyStateView: UIView {

    public var onAddTapped: (() -> Void)?

    private let illustration = UIView()
    private let gradientLayer = CAGradientLayer()
    private let sheenLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let addButton = UIButton(type: .system)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = illustration.bounds
        sheenLayer.frame = illustration.bounds
        illustration.layer.cdkApplyCardShadow(cornerRadius: CDKTheme.Radius.card)
        CATransaction.commit()
    }

    private func setUp() {
        let preset = CDKGradientPalette.preset(at: 0)
        gradientLayer.colors = preset.cgColors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = CDKTheme.Radius.card
        gradientLayer.cornerCurve = .continuous

        sheenLayer.colors = [
            UIColor.white.withAlphaComponent(0).cgColor,
            UIColor.white.withAlphaComponent(0.3).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor
        ]
        sheenLayer.locations = [0.15, 0.5, 0.85]
        sheenLayer.startPoint = CGPoint(x: -0.1, y: 0.1)
        sheenLayer.endPoint = CGPoint(x: 1.1, y: 0.9)
        sheenLayer.cornerRadius = CDKTheme.Radius.card
        sheenLayer.cornerCurve = .continuous

        illustration.layer.addSublayer(gradientLayer)
        illustration.layer.addSublayer(sheenLayer)
        illustration.isAccessibilityElement = false

        titleLabel.text = "No cards yet"
        titleLabel.font = CDKTheme.Font.title
        titleLabel.textColor = CDKTheme.Color.textPrimary
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Add a loyalty card and it will always be within reach."
        subtitleLabel.font = CDKTheme.Font.body
        subtitleLabel.textColor = CDKTheme.Color.textSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        var configuration = UIButton.Configuration.filled()
        configuration.title = "Add your first card"
        configuration.baseBackgroundColor = CDKTheme.Color.accent
        configuration.baseForegroundColor = CDKTheme.Color.textPrimary
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = CDKTheme.Radius.button
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: CDKTheme.Spacing.m,
            leading: CDKTheme.Spacing.l,
            bottom: CDKTheme.Spacing.m,
            trailing: CDKTheme.Spacing.l
        )
        addButton.configuration = configuration
        addButton.addAction(
            UIAction { [weak self] _ in self?.onAddTapped?() },
            for: .touchUpInside
        )

        cdkAddSubview(illustration)
        cdkAddSubview(titleLabel)
        cdkAddSubview(subtitleLabel)
        cdkAddSubview(addButton)

        NSLayoutConstraint.activate([
            illustration.centerXAnchor.constraint(equalTo: centerXAnchor),
            illustration.widthAnchor.constraint(
                lessThanOrEqualTo: widthAnchor, multiplier: 0.62
            ),
            illustration.widthAnchor.constraint(equalToConstant: 240)
                .cdkWithPriority(.defaultHigh),
            illustration.heightAnchor.constraint(
                equalTo: illustration.widthAnchor,
                multiplier: 1 / CDKTheme.Card.aspectRatio
            ),
            illustration.bottomAnchor.constraint(
                equalTo: titleLabel.topAnchor, constant: -CDKTheme.Spacing.xl
            ),
            illustration.topAnchor.constraint(
                greaterThanOrEqualTo: topAnchor, constant: CDKTheme.Spacing.l
            ),

            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: CDKTheme.Spacing.l
            ),
            titleLabel.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -CDKTheme.Spacing.l
            ),

            subtitleLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: CDKTheme.Spacing.s
            ),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            addButton.topAnchor.constraint(
                equalTo: subtitleLabel.bottomAnchor, constant: CDKTheme.Spacing.l
            ),
            addButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            addButton.bottomAnchor.constraint(
                lessThanOrEqualTo: bottomAnchor, constant: -CDKTheme.Spacing.l
            )
        ])
    }
}

public extension NSLayoutConstraint {

    func cdkWithPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
