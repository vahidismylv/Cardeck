import UIKit

public final class CDKFormFieldView: UIView {

    public var onChange: ((String) -> Void)?

    private let captionLabel = UILabel()
    private let errorLabel = UILabel()
    private let container = UIView()
    private let textField = UITextField()

    public var text: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }

    public init(caption: String, placeholder: String, keyboard: UIKeyboardType = .default) {
        super.init(frame: .zero)
        setUp(caption: caption, placeholder: placeholder, keyboard: keyboard)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    public func setError(_ message: String?) {
        errorLabel.text = message
        errorLabel.isHidden = message == nil
        container.layer.borderColor = message == nil
            ? CDKTheme.Color.separator.cgColor
            : CDKTheme.Color.destructive.cgColor
        accessibilityHint = message
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    private func setUp(caption: String, placeholder: String, keyboard: UIKeyboardType) {
        captionLabel.text = caption
        captionLabel.font = CDKTheme.Font.caption
        captionLabel.textColor = CDKTheme.Color.textSecondary

        errorLabel.font = CDKTheme.Font.caption
        errorLabel.textColor = CDKTheme.Color.destructive
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        container.backgroundColor = CDKTheme.Color.surface
        container.layer.cornerRadius = CDKTheme.Radius.button
        container.layer.cornerCurve = .continuous
        container.layer.borderWidth = 1
        container.layer.borderColor = CDKTheme.Color.separator.cgColor

        textField.font = CDKTheme.Font.body
        textField.textColor = CDKTheme.Color.textPrimary
        textField.keyboardType = keyboard
        textField.autocorrectionType = .no
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: CDKTheme.Color.textSecondary]
        )
        textField.accessibilityLabel = caption
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        if keyboard == .numberPad {
            textField.inputAccessoryView = makeDoneToolbar()
        }

        container.cdkAddSubview(textField)
        cdkAddSubview(captionLabel)
        cdkAddSubview(container)
        cdkAddSubview(errorLabel)

        NSLayoutConstraint.activate([
            captionLabel.topAnchor.constraint(equalTo: topAnchor),
            captionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            captionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            container.topAnchor.constraint(
                equalTo: captionLabel.bottomAnchor, constant: CDKTheme.Spacing.s
            ),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),

            textField.topAnchor.constraint(
                equalTo: container.topAnchor, constant: CDKTheme.Spacing.m
            ),
            textField.bottomAnchor.constraint(
                equalTo: container.bottomAnchor, constant: -CDKTheme.Spacing.m
            ),
            textField.leadingAnchor.constraint(
                equalTo: container.leadingAnchor, constant: CDKTheme.Spacing.m
            ),
            textField.trailingAnchor.constraint(
                equalTo: container.trailingAnchor, constant: -CDKTheme.Spacing.m
            ),

            errorLabel.topAnchor.constraint(
                equalTo: container.bottomAnchor, constant: CDKTheme.Spacing.xs
            ),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            errorLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func makeDoneToolbar() -> UIToolbar {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        toolbar.barStyle = .black
        toolbar.tintColor = CDKTheme.Color.accent
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(
                title: "Done",
                primaryAction: UIAction { [weak self] _ in
                    self?.textField.resignFirstResponder()
                }
            )
        ]
        toolbar.sizeToFit()
        return toolbar
    }

    @objc private func editingChanged() {
        onChange?(text)
    }
}
