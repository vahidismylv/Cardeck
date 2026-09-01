import UIKit

public final class CDKSettingsChoiceRow: UIControl {

    public var onSelect: (() -> Void)?

    private let titleLabel = UILabel()
    private let checkmark = UIImageView(image: UIImage(systemName: "checkmark"))

    public init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = CDKTheme.Font.body
        titleLabel.textColor = CDKTheme.Color.textPrimary
        titleLabel.numberOfLines = 0

        checkmark.tintColor = CDKTheme.Color.accent
        checkmark.setContentHuggingPriority(.required, for: .horizontal)
        checkmark.isHidden = true

        let row = UIStackView(arrangedSubviews: [titleLabel, checkmark])
        row.alignment = .center
        row.spacing = CDKTheme.Spacing.m
        row.isUserInteractionEnabled = false
        cdkAddSubview(row)
        NSLayoutConstraint.activate(row.cdkPinConstraints(to: self, inset: CDKTheme.Spacing.m))

        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = .button
        addAction(UIAction { [weak self] _ in self?.onSelect?() }, for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public func setSelected(_ selected: Bool) {
        checkmark.isHidden = !selected
        accessibilityTraits = selected ? [.button, .selected] : .button
    }

    public override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
                ? CDKTheme.Color.surfaceElevated
                : .clear
        }
    }
}

public final class CDKSettingsActionRow: UIControl {

    public var onTap: (() -> Void)?

    public init(title: String, destructive: Bool = false, showsChevron: Bool = true) {
        super.init(frame: .zero)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = CDKTheme.Font.body
        titleLabel.textColor = destructive
            ? CDKTheme.Color.destructive
            : CDKTheme.Color.textPrimary
        titleLabel.numberOfLines = 0

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = CDKTheme.Color.textSecondary
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.isHidden = !showsChevron

        let row = UIStackView(arrangedSubviews: [titleLabel, chevron])
        row.alignment = .center
        row.spacing = CDKTheme.Spacing.m
        row.isUserInteractionEnabled = false
        cdkAddSubview(row)
        NSLayoutConstraint.activate(row.cdkPinConstraints(to: self, inset: CDKTheme.Spacing.m))

        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = .button
        addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
                ? CDKTheme.Color.surfaceElevated
                : .clear
        }
    }
}
