import UIKit

public final class CDKDetailCardView: UIView {

    private let titleLabel = UILabel()
    private let categoryLabel = UILabel()
    private let codeLabel = UILabel()

    public private(set) var materialView: CDKCardMaterialView?

    private var snapshot: CDKCardSnapshot?

    public var cornerRadius: CGFloat = CDKTheme.Radius.cardExpanded {
        didSet {
            guard cornerRadius != oldValue else { return }
            materialView?.cornerRadius = cornerRadius
            setNeedsLayout()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cdkApplyCardShadow(cornerRadius: cornerRadius)
    }

    @objc private func handleContrastChange() {
        guard let snapshot else { return }
        configure(with: snapshot)
    }

    public func configure(with card: CDKCardSnapshot) {
        snapshot = card
        let foreground = card.gradient.foregroundColor
        titleLabel.text = card.title
        titleLabel.textColor = foreground
        categoryLabel.text = card.category.title
        categoryLabel.textColor = foreground.withAlphaComponent(0.75)
        codeLabel.text = card.maskedCode
        codeLabel.textColor = foreground.withAlphaComponent(0.85)
        isAccessibilityElement = false
    }

    public func attach(_ material: CDKCardMaterialView) {
        materialView = material
        material.cornerRadius = cornerRadius
        insertSubview(material, at: 0)
        material.translatesAutoresizingMaskIntoConstraints = false
        material.cdkPin(to: self)
        material.startMotionUpdates()
    }

    public func detachMaterial() -> CDKCardMaterialView? {
        guard let materialView else { return nil }
        materialView.removeFromSuperview()
        self.materialView = nil
        return materialView
    }

    public func setLabelsVisible(_ visible: Bool) {
        let alpha: CGFloat = visible ? 1 : 0
        titleLabel.alpha = alpha
        categoryLabel.alpha = alpha
        codeLabel.alpha = alpha
    }

    private func setUp() {
        backgroundColor = .clear

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContrastChange),
            name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil
        )

        titleLabel.font = CDKTheme.Font.title
        titleLabel.numberOfLines = 2

        categoryLabel.font = CDKTheme.Font.caption

        codeLabel.font = CDKTheme.Font.mono(15)

        cdkAddSubview(titleLabel)
        cdkAddSubview(categoryLabel)
        cdkAddSubview(codeLabel)

        let inset = CDKTheme.Card.contentInset
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(
                equalTo: topAnchor, constant: CDKTheme.Card.contentTopInset
            ),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            titleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: trailingAnchor, constant: -inset
            ),

            categoryLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: CDKTheme.Spacing.xs
            ),
            categoryLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            categoryLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: trailingAnchor, constant: -inset
            ),

            codeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            codeLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: trailingAnchor, constant: -inset
            ),
            codeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset)
        ])
    }
}
