//
//  CDKCardCell.swift
//  Cardeck
//

import UIKit

/// Действия, доступные над картой прямо из стопки — через custom actions VoiceOver.
public protocol CDKCardCellDelegate: AnyObject {
    func cardCellDidRequestShowCode(_ cell: CDKCardCell)
    func cardCellDidRequestEdit(_ cell: CDKCardCell)
    func cardCellDidRequestDelete(_ cell: CDKCardCell)
}

/// Ячейка карты в стопке.
///
/// Слои снизу вверх: материал (Metal или fallback), затем контент — название,
/// последние четыре цифры и категория. Тень живёт на слое ячейки и всегда имеет
/// `shadowPath`, поэтому offscreen-проходов не возникает.
public final class CDKCardCell: UICollectionViewCell {

    /// Идентификатор для регистрации в коллекции.
    public static let reuseIdentifier = "CDKCardCell"

    /// Приёмник действий доступности.
    public weak var delegate: CDKCardCellDelegate?

    /// Материал карты. Публичный, потому что переход в детальный экран
    /// переносит эту вью в `containerView` вместо снимка.
    public private(set) var materialView: CDKCardMaterialView?

    private let titleLabel = UILabel()
    private let codeLabel = UILabel()
    private let categoryLabel = UILabel()
    private let categoryIcon = UIImageView()

    private var snapshot: CDKCardSnapshot?
    private var categoryStack: UIStackView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // shadowPath обязателен: без него тень пересчитывается растеризацией каждый кадр.
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

    // MARK: - Наполнение

    /// Наполняет ячейку данными карты и поднимает под неё материал.
    public func configure(with card: CDKCardSnapshot) {
        snapshot = card
        let material = materialView ?? makeMaterialView()
        material.update(gradient: card.gradient)
        material.startMotionUpdates()

        let foreground = card.gradient.end.cdkReadableForeground
        titleLabel.text = card.title
        titleLabel.textColor = foreground
        codeLabel.text = card.maskedCode
        codeLabel.textColor = foreground.withAlphaComponent(0.85)
        categoryLabel.text = card.category.title
        categoryLabel.textColor = foreground.withAlphaComponent(0.75)
        categoryIcon.image = UIImage(systemName: card.category.symbolName)
        categoryIcon.tintColor = foreground.withAlphaComponent(0.75)

        updateCategoryVisibility()
        configureAccessibility(with: card)
    }

    /// Прячет категорию, когда шрифт крупный: иначе подпись обрезает соседняя карта.
    private func updateCategoryVisibility() {
        categoryStack?.isHidden = traitCollection.preferredContentSizeCategory
            .isAccessibilityCategory
    }

    /// Возвращает материал ячейке после завершения перехода.
    ///
    /// Переход забирает материал в `containerView`; по окончании вью надо вернуть
    /// на место, иначе ячейка останется пустой при переиспользовании.
    public func reclaimMaterialView(_ view: CDKCardMaterialView) {
        materialView = view
        view.cornerRadius = CDKTheme.Radius.card
        contentView.insertSubview(view, at: 0)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.cdkPin(to: contentView)
        view.startMotionUpdates()
    }

    /// Отдаёт материал наружу, оставляя ячейку без него.
    public func detachMaterialView() -> CDKCardMaterialView? {
        guard let materialView else { return nil }
        materialView.stopMotionUpdates()
        materialView.removeFromSuperview()
        self.materialView = nil
        return materialView
    }

    /// Подъём карты пальцем при переупорядочивании: усиленная тень.
    public func setLifted(_ lifted: Bool) {
        layer.cdkApplyCardShadow(cornerRadius: CDKTheme.Radius.card, lifted: lifted)
    }

    // MARK: - Приватное

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
        titleLabel.adjustsFontForContentSizeCategory = true

        codeLabel.font = CDKTheme.Font.mono(15)
        codeLabel.adjustsFontForContentSizeCategory = true

        categoryLabel.font = CDKTheme.Font.caption
        categoryLabel.adjustsFontForContentSizeCategory = true
        categoryIcon.contentMode = .scaleAspectFit
        categoryIcon.setContentHuggingPriority(.required, for: .horizontal)

        let categoryStack = UIStackView(arrangedSubviews: [categoryIcon, categoryLabel])
        categoryStack.spacing = CDKTheme.Spacing.xs
        categoryStack.alignment = .center
        self.categoryStack = categoryStack

        // На accessibility-размерах в видимую полосу карты влезает только название.
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) {
            (cell: CDKCardCell, _) in cell.updateCategoryVisibility()
        }

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
