import UIKit

public final class CDKCardDetailView: UIView {

    public var onShowCode: (() -> Void)?

    public var onEdit: (() -> Void)?

    public var onDelete: (() -> Void)?

    public var onClose: (() -> Void)?

    public let cardView = CDKDetailCardView()

    public let codePanel = CDKCodePanelView()

    public let scrollView = UIScrollView()

    private let cardContainer = UIView()
    private let contentStack = UIStackView()
    private let actionsStack = UIStackView()
    private let closeButton = UIButton(type: .system)

    private var cardHeightConstraint: NSLayoutConstraint?
    private var cardWidthConstraint: NSLayoutConstraint?

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

        scrollView.contentInset.top = safeAreaInsets.top
            + closeButton.bounds.height + CDKTheme.Spacing.s
    }

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
