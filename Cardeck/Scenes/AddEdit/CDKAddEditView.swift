import UIKit

public final class CDKAddEditView: UIView {

    public var onTitleChange: ((String) -> Void)?

    public var onCodeChange: ((String) -> Void)?

    public var onNoteChange: ((String) -> Void)?

    public var onCodeTypeChange: ((CDKCodeType) -> Void)?

    public var onCategoryChange: ((CDKCategory) -> Void)?

    public var onGradientChange: ((Int) -> Void)?

    public var onSave: (() -> Void)?

    public var onCancel: (() -> Void)?

    public let previewCard = CDKDetailCardView()

    public let gradientPicker: CDKGradientPickerView

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let previewContainer = UIView()
    private let titleField = CDKFormFieldView(caption: "Name", placeholder: "Card name")
    private let codeField = CDKFormFieldView(
        caption: "Number", placeholder: "Card number", keyboard: .numberPad
    )
    private let noteField = CDKFormFieldView(caption: "Note", placeholder: "Optional")
    private let codeTypeControl = UISegmentedControl(
        items: CDKCodeType.allCases.map(\.title)
    )
    private let categoryControl = UIButton(type: .system)
    private let headerLabel = UILabel()
    private let cancelButton = UIButton(type: .system)
    private lazy var saveButton = CDKActionButton.make(title: "Save", style: .accent) {
        [weak self] in self?.onSave?()
    }

    private var previewHeight: NSLayoutConstraint?
    private var previewWidth: NSLayoutConstraint?

    public init(haptics: CDKHapticsServiceProtocol) {
        gradientPicker = CDKGradientPickerView(haptics: haptics)
        super.init(frame: .zero)
        backgroundColor = CDKTheme.Color.background
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let width = (bounds.width - CDKTheme.Card.detailHorizontalInset * 2).rounded()
        guard width > 0, previewWidth?.constant != width else { return }
        previewWidth?.constant = width
        previewHeight?.constant = CDKTheme.Card.height(forWidth: width)
    }

    public func apply(_ viewModel: CDKAddEditViewModel) {
        headerLabel.text = viewModel.screenTitle
        saveButton.configuration?.title = viewModel.saveTitle
        previewCard.configure(with: viewModel.draft)
        previewCard.materialView?.update(gradient: viewModel.draft.gradient)
        titleField.setError(viewModel.title.isEmpty ? nil : viewModel.titleError)
        codeField.setError(viewModel.code.isEmpty ? nil : viewModel.codeError)
        saveButton.isEnabled = viewModel.isValid
        saveButton.alpha = viewModel.isValid ? 1 : 0.5
        categoryControl.configuration?.title = viewModel.category.title
        categoryControl.configuration?.image = UIImage(
            systemName: viewModel.category.symbolName
        )
        if codeTypeControl.selectedSegmentIndex
            != CDKCodeType.allCases.firstIndex(of: viewModel.codeType) {
            codeTypeControl.selectedSegmentIndex =
                CDKCodeType.allCases.firstIndex(of: viewModel.codeType) ?? 0
        }
    }

    public func fill(from viewModel: CDKAddEditViewModel) {
        titleField.text = viewModel.title
        codeField.text = viewModel.code
        noteField.text = viewModel.note
        gradientPicker.select(index: viewModel.gradientIndex, animated: false)
    }

    public func setCategoryMenu(_ menu: UIMenu) {
        categoryControl.menu = menu
        categoryControl.showsMenuAsPrimaryAction = true
    }

    public func setPreviewCompact(_ compact: Bool) {
        previewCard.transform = compact
            ? CGAffineTransform(scaleX: 0.8, y: 0.8)
            : .identity
    }

    public func focusFirstField() {
        titleField.becomeFirstResponder()
    }

    private func setUp() {
        headerLabel.font = CDKTheme.Font.title
        headerLabel.textColor = CDKTheme.Color.textPrimary

        var cancelConfiguration = UIButton.Configuration.plain()
        cancelConfiguration.image = UIImage(systemName: "xmark")
        cancelConfiguration.baseForegroundColor = CDKTheme.Color.textSecondary
        cancelButton.configuration = cancelConfiguration
        cancelButton.accessibilityLabel = "Cancel"
        cancelButton.addAction(UIAction { [weak self] _ in self?.onCancel?() }, for: .touchUpInside)

        var categoryConfiguration = UIButton.Configuration.filled()
        categoryConfiguration.baseBackgroundColor = CDKTheme.Color.surface
        categoryConfiguration.baseForegroundColor = CDKTheme.Color.textPrimary
        categoryConfiguration.cornerStyle = .fixed
        categoryConfiguration.background.cornerRadius = CDKTheme.Radius.button
        categoryConfiguration.imagePadding = CDKTheme.Spacing.s
        categoryConfiguration.contentInsets = NSDirectionalEdgeInsets(
            top: CDKTheme.Spacing.m, leading: CDKTheme.Spacing.m,
            bottom: CDKTheme.Spacing.m, trailing: CDKTheme.Spacing.m
        )
        categoryControl.configuration = categoryConfiguration
        categoryControl.contentHorizontalAlignment = .leading
        categoryControl.accessibilityLabel = "Category"

        codeTypeControl.selectedSegmentIndex = 0
        codeTypeControl.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                let index = self.codeTypeControl.selectedSegmentIndex
                guard CDKCodeType.allCases.indices.contains(index) else { return }
                self.onCodeTypeChange?(CDKCodeType.allCases[index])
            },
            for: .valueChanged
        )

        titleField.onChange = { [weak self] in self?.onTitleChange?($0) }
        codeField.onChange = { [weak self] in self?.onCodeChange?($0) }
        noteField.onChange = { [weak self] in self?.onNoteChange?($0) }
        gradientPicker.onSelect = { [weak self] in self?.onGradientChange?($0) }

        previewContainer.cdkAddSubview(previewCard)
        contentStack.axis = .vertical
        contentStack.spacing = CDKTheme.Spacing.l
        for view in [previewContainer, gradientPicker, titleField, codeField,
                     codeTypeControl, categoryControl, noteField, saveButton] {
            contentStack.addArrangedSubview(view)
        }

        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        cdkAddSubview(headerLabel)
        cdkAddSubview(cancelButton)
        cdkAddSubview(scrollView)
        scrollView.cdkAddSubview(contentStack)
        activateConstraints()
    }

    private func activateConstraints() {
        let inset = CDKTheme.Card.detailHorizontalInset
        let width = previewCard.widthAnchor.constraint(equalToConstant: 1)
        let height = previewCard.heightAnchor.constraint(equalToConstant: 1)
        previewWidth = width
        previewHeight = height

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(
                equalTo: safeAreaLayoutGuide.topAnchor, constant: CDKTheme.Spacing.s
            ),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            cancelButton.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor),
            cancelButton.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -CDKTheme.Spacing.s
            ),
            cancelButton.leadingAnchor.constraint(
                greaterThanOrEqualTo: headerLabel.trailingAnchor, constant: CDKTheme.Spacing.s
            ),

            scrollView.topAnchor.constraint(
                equalTo: headerLabel.bottomAnchor, constant: CDKTheme.Spacing.m
            ),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),

            scrollView.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
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

            width, height,
            previewCard.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            previewCard.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),
            previewCard.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor)
        ])
    }
}
