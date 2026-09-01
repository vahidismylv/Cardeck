import UIKit

public final class CDKWalletHeaderView: UIView {

    public var onAddTapped: (() -> Void)?

    public var onSettingsTapped: (() -> Void)?

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public func setSubtitle(_ text: String?) {
        subtitleLabel.text = text
        subtitleLabel.isHidden = text == nil
    }

    private func setUp() {
        backgroundColor = CDKTheme.Color.background

        titleLabel.text = "Cards"
        titleLabel.font = CDKTheme.Font.largeTitle
        titleLabel.textColor = CDKTheme.Color.textPrimary
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.accessibilityTraits = .header

        subtitleLabel.font = CDKTheme.Font.callout
        subtitleLabel.textColor = CDKTheme.Color.textSecondary

        configure(settingsButton, symbol: "gearshape", label: "Settings") { [weak self] in
            self?.onSettingsTapped?()
        }
        configure(addButton, symbol: "plus", label: "Add card") { [weak self] in
            self?.onAddTapped?()
        }

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .horizontal
        titleStack.alignment = .firstBaseline
        titleStack.spacing = CDKTheme.Spacing.s

        let buttonStack = UIStackView(arrangedSubviews: [settingsButton, addButton])
        buttonStack.spacing = CDKTheme.Spacing.s
        buttonStack.setContentHuggingPriority(.required, for: .horizontal)
        buttonStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [titleStack, buttonStack])
        row.alignment = .center
        row.spacing = CDKTheme.Spacing.m

        cdkAddSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: CDKTheme.Spacing.xs),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CDKTheme.Spacing.l),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -CDKTheme.Spacing.l),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -CDKTheme.Spacing.xs)
        ])
    }

    private func configure(
        _ button: UIButton,
        symbol: String,
        label: String,
        action: @escaping () -> Void
    ) {
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: symbol)
        configuration.baseBackgroundColor = CDKTheme.Color.surfaceElevated
        configuration.baseForegroundColor = CDKTheme.Color.textPrimary
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: CDKTheme.Spacing.s,
            leading: CDKTheme.Spacing.s,
            bottom: CDKTheme.Spacing.s,
            trailing: CDKTheme.Spacing.s
        )
        button.configuration = configuration
        button.accessibilityLabel = label
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    }
}
