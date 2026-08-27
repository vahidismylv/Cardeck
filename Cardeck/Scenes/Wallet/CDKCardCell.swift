import UIKit

public protocol CDKCardCellDelegate: AnyObject {
    func cardCellDidRequestShowCode(_ cell: CDKCardCell)
    func cardCellDidRequestEdit(_ cell: CDKCardCell)
    func cardCellDidRequestDelete(_ cell: CDKCardCell)
}

public final class CDKCardCell: UICollectionViewCell {

    public static let reuseIdentifier = "CDKCardCell"

    public weak var delegate: CDKCardCellDelegate?

    public private(set) var materialView: CDKCardMaterialView?

    private let titleLabel = UILabel()
    private let codeLabel = UILabel()
    private let categoryLabel = UILabel()
    private let categoryIcon = UIImageView()

    private var snapshot: CDKCardSnapshot?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    public override func layoutSubviews() {
        super.layoutSubviews()

        layer.cdkApplyCardShadow(cornerRadius: CDKTheme.Radius.card)
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        materialView?.stopMotionUpdates()
        materialView?.removeFromSuperview()
        materialView = nil
        snapshot = nil
        contentView.transform = .identity
        layer.zPosition = 0
        setLifted(false)
    }

    public func configure(with card: CDKCardSnapshot) {
        snapshot = card
        let material = materialView ?? makeMaterialView()
        material.update(gradient: card.gradient)
        material.startMotionUpdates()

        let foreground = card.gradient.foregroundColor
        titleLabel.text = card.title
        titleLabel.textColor = foreground
        codeLabel.text = card.maskedCode
        codeLabel.textColor = foreground.withAlphaComponent(0.85)
        categoryLabel.text = card.category.title
        categoryLabel.textColor = foreground.withAlphaComponent(0.75)
        categoryIcon.image = UIImage(systemName: card.category.symbolName)
        categoryIcon.tintColor = foreground.withAlphaComponent(0.75)

        configureAccessibility(with: card)
    }

    @objc private func handleContrastChange() {
        guard let snapshot else { return }
        configure(with: snapshot)
    }

    public func reclaimMaterialView(_ view: CDKCardMaterialView) {
        materialView = view
        view.cornerRadius = CDKTheme.Radius.card
        contentView.insertSubview(view, at: 0)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.cdkPin(to: contentView)
        view.startMotionUpdates()
    }

    public func detachMaterialView() -> CDKCardMaterialView? {
        guard let materialView else { return nil }
        materialView.stopMotionUpdates()
        materialView.removeFromSuperview()
        self.materialView = nil
        return materialView
    }

    public func setLifted(_ lifted: Bool) {
        layer.cdkApplyCardShadow(cornerRadius: CDKTheme.Radius.card, lifted: lifted)
    }

    private func makeMaterialView() -> CDKCardMaterialView {
        let material = CDKCardMaterialView(gradient: CDKGradientPalette.preset(at: 0))
        materialView = material
        contentView.insertSubview(material, at: 0)
        material.translatesAutoresizingMaskIntoConstraints = false
        material.cdkPin(to: contentView)
        return material
    }

    private func setUp() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        contentView.layer.cornerRadius = CDKTheme.Radius.card
        contentView.layer.cornerCurve = .continuous

        titleLabel.font = CDKTheme.Font.title
        titleLabel.numberOfLines = 2

        codeLabel.font = CDKTheme.Font.mono(15)

        categoryLabel.font = CDKTheme.Font.caption
        categoryIcon.contentMode = .scaleAspectFit
        categoryIcon.setContentHuggingPriority(.required, for: .horizontal)

        let categoryStack = UIStackView(arrangedSubviews: [categoryIcon, categoryLabel])
        categoryStack.spacing = CDKTheme.Spacing.xs
        categoryStack.alignment = .center

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContrastChange),
            name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil
        )

        contentView.cdkAddSubview(titleLabel)
        contentView.cdkAddSubview(codeLabel)
        contentView.cdkAddSubview(categoryStack)

        let inset = CDKTheme.Card.contentInset
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(
                equalTo: contentView.topAnchor, constant: CDKTheme.Card.contentTopInset
            ),
            titleLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: inset
            ),
            titleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor, constant: -inset
            ),

            categoryStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            categoryStack.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: CDKTheme.Spacing.xs
            ),
            categoryStack.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor, constant: -inset
            ),
            categoryIcon.widthAnchor.constraint(equalToConstant: 14),

            codeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            codeLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor, constant: -inset
            ),
            codeLabel.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor, constant: -inset
            )
        ])
    }

    private func configureAccessibility(with card: CDKCardSnapshot) {
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = card.accessibilityDescription
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Show code") { [weak self] _ in
                guard let self else { return false }
                self.delegate?.cardCellDidRequestShowCode(self)
                return true
            },
            UIAccessibilityCustomAction(name: "Edit") { [weak self] _ in
                guard let self else { return false }
                self.delegate?.cardCellDidRequestEdit(self)
                return true
            },
            UIAccessibilityCustomAction(name: "Delete") { [weak self] _ in
                guard let self else { return false }
                self.delegate?.cardCellDidRequestDelete(self)
                return true
            }
        ]
    }
}
