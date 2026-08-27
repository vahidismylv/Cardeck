import UIKit

public final class CDKSettingsSectionView: UIView {

    private let titleLabel = UILabel()
    private let rowsStack = UIStackView()
    private let card = UIView()

    public init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title.uppercased()
        titleLabel.font = CDKTheme.Font.caption
        titleLabel.textColor = CDKTheme.Color.textSecondary
        titleLabel.accessibilityTraits = .header

        card.backgroundColor = CDKTheme.Color.surface
        card.layer.cornerRadius = CDKTheme.Radius.surface
        card.layer.cornerCurve = .continuous

        rowsStack.axis = .vertical
        rowsStack.spacing = 0

        card.cdkAddSubview(rowsStack)
        cdkAddSubview(titleLabel)
        cdkAddSubview(card)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: CDKTheme.Spacing.m
            ),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            card.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: CDKTheme.Spacing.s
            ),
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        NSLayoutConstraint.activate(rowsStack.cdkPinConstraints(to: card))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    public func addRow(_ row: UIView) {
        if !rowsStack.arrangedSubviews.isEmpty {
            rowsStack.addArrangedSubview(makeSeparator())
        }
        rowsStack.addArrangedSubview(row)
    }

    private func makeSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = CDKTheme.Color.separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }
}

public final class CDKSettingsToggleRow: UIView {

    public var onToggle: ((Bool) -> Void)?

    private let toggle = UISwitch()

    public init(title: String, subtitle: String? = nil) {
        super.init(frame: .zero)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = CDKTheme.Font.body
        titleLabel.textColor = CDKTheme.Color.textPrimary
        titleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel])
        stack.axis = .vertical
        stack.spacing = 2
        if let subtitle {
            let subtitleLabel = UILabel()
            subtitleLabel.text = subtitle
            subtitleLabel.font = CDKTheme.Font.caption
            subtitleLabel.textColor = CDKTheme.Color.textSecondary
            subtitleLabel.numberOfLines = 0
            stack.addArrangedSubview(subtitleLabel)
        }

        toggle.onTintColor = CDKTheme.Color.accent
        toggle.accessibilityLabel = title
        toggle.addAction(
            UIAction { [weak self] _ in self?.onToggle?(self?.toggle.isOn ?? false) },
            for: .valueChanged
        )
        toggle.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [stack, toggle])
        row.alignment = .center
        row.spacing = CDKTheme.Spacing.m
        cdkAddSubview(row)
        NSLayoutConstraint.activate(row.cdkPinConstraints(to: self, inset: CDKTheme.Spacing.m))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    public func setOn(_ isOn: Bool) {
        toggle.setOn(isOn, animated: false)
    }
}
