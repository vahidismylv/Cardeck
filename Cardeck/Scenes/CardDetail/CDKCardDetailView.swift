//
//  CDKCardDetailView.swift
//  Cardeck
//

import UIKit

/// Вёрстка детального экрана: карта, панель кода и кнопки действий.
///
/// Вынесена из контроллера: тот отвечает за жизненный цикл, яркость и построение
/// кода, а вся геометрия живёт здесь.
public final class CDKCardDetailView: UIView {

    /// Нажатие «Show code».
    public var onShowCode: (() -> Void)?
    /// Нажатие «Edit».
    public var onEdit: (() -> Void)?
    /// Нажатие «Delete».
    public var onDelete: (() -> Void)?
    /// Нажатие крестика.
    public var onClose: (() -> Void)?

    /// Карта со слотом под материал.
    public let cardView = CDKDetailCardView()
    /// Панель со штриховым кодом.
    public let codePanel = CDKCodePanelView()
    /// Скролл, внутри которого лежит весь контент.
    public let scrollView = UIScrollView()

    private let cardContainer = UIView()
    private let contentStack = UIStackView()
    private let actionsStack = UIStackView()
    private let closeButton = UIButton(type: .system)

    private var cardHeightConstraint: NSLayoutConstraint?
    private var cardWidthConstraint: NSLayoutConstraint?

    /// Контент, который появляется вторым аниматором после прилёта карты.
    public var animatableContent: [UIView] { [codePanel, actionsStack, closeButton] }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = CDKTheme.Color.background
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateCardSize()
        scrollView.contentInset.top = safeAreaInsets.top + CDKTheme.Spacing.l
    }

    /// Возвращает экран в рабочее состояние после отменённого закрытия.
    ///
    /// Жест отменял скролл панели и мог оставить её в оттянутом положении,
    /// поэтому её надо вернуть к началу.
    public func restoreAfterCancelledDismissal() {
        for view in animatableContent {
            view.alpha = 1
            view.transform = .identity
        }
        scrollView.setContentOffset(
            CGPoint(x: 0, y: -scrollView.adjustedContentInset.top),
            animated: false
        )
    }

    /// Размер карты по ширине экрана в пропорциях ID-1.
    ///
    /// Приложение работает только в портрете, поэтому ширину всегда задаёт экран.
    private func updateCardSize() {
        let width = (bounds.width - CDKTheme.Card.detailHorizontalInset * 2).rounded()
        guard width > 0 else { return }
        let height = CDKTheme.Card.height(forWidth: width)
        guard cardHeightConstraint?.constant != height
            || cardWidthConstraint?.constant != width else { return }
        cardHeightConstraint?.constant = height
        cardWidthConstraint?.constant = width
        cardView.materialView?.refresh()
    }

    private func setUp() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        // Верхний отступ задаём сами в layoutSubviews; автоматический прибавил бы
        // safe area поверх него, и карта уехала бы вниз на её высоту второй раз.
        scrollView.contentInsetAdjustmentBehavior = .never

        contentStack.axis = .vertical
        contentStack.spacing = CDKTheme.Spacing.l

        actionsStack.axis = .vertical
        actionsStack.spacing = CDKTheme.Spacing.s
        actionsStack.addArrangedSubview(
            CDKActionButton.make(title: "Show code", style: .accent) { [weak self] in
                self?.onShowCode?()
            }
        )
        actionsStack.addArrangedSubview(
            CDKActionButton.make(title: "Edit", style: .surface) { [weak self] in
                self?.onEdit?()
            }
        )
        actionsStack.addArrangedSubview(
            CDKActionButton.make(title: "Delete", style: .destructive) { [weak self] in
                self?.onDelete?()
            }
        )

        var closeConfiguration = UIButton.Configuration.plain()
        closeConfiguration.image = UIImage(systemName: "xmark")
        closeConfiguration.baseForegroundColor = CDKTheme.Color.textSecondary
        closeButton.configuration = closeConfiguration
        closeButton.accessibilityLabel = "Close"
        closeButton.addAction(UIAction { [weak self] _ in self?.onClose?() }, for: .touchUpInside)

        // Карта живёт в контейнере во всю ширину и центрируется в нём:
        // её размер задан явными константами, а не растяжением по стеку.
        cardContainer.cdkAddSubview(cardView)
        contentStack.addArrangedSubview(cardContainer)
        contentStack.addArrangedSubview(codePanel)
        contentStack.addArrangedSubview(actionsStack)

        cdkAddSubview(scrollView)
        scrollView.cdkAddSubview(contentStack)
        cdkAddSubview(closeButton)

        activateConstraints()
    }

    private func activateConstraints() {
        let inset = CDKTheme.Card.detailHorizontalInset
        let height = cardView.heightAnchor.constraint(equalToConstant: 1)
        let width = cardView.widthAnchor.constraint(equalToConstant: 1)
        cardHeightConstraint = height
        cardWidthConstraint = width

        NSLayoutConstraint.activate([
            height, width,
            cardView.topAnchor.constraint(equalTo: cardContainer.topAnchor),
            cardView.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor),
            cardView.centerXAnchor.constraint(equalTo: cardContainer.centerXAnchor),

            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStack.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor,
                constant: CDKTheme.Spacing.l
            ),
            contentStack.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -CDKTheme.Spacing.xl
            ),
            contentStack.leadingAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: inset
            ),
            contentStack.trailingAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -inset
            ),

            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            closeButton.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -CDKTheme.Spacing.s
            )
        ])
    }
}
