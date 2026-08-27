import UIKit

public final class CDKCodePanelView: UIView {

    private let codeContainer = UIView()
    private let codeImageView = UIImageView()
    private let numberLabel = UILabel()
    private let messageLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    private var aspectConstraint: NSLayoutConstraint?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    public var currentCodeImage: UIImage? { codeImageView.image }

    public func showLoading() {
        spinner.startAnimating()
        codeContainer.backgroundColor = .clear
        codeImageView.isHidden = true
        messageLabel.isHidden = true
    }

    public func show(image: UIImage, aspectRatio: CGFloat, number: String) {
        spinner.stopAnimating()
        codeContainer.backgroundColor = .white
        messageLabel.isHidden = true
        codeImageView.isHidden = false
        codeImageView.image = image
        numberLabel.text = number
        setAspectRatio(aspectRatio)
        accessibilityLabel = "Barcode, \(number)"
    }

    public func show(error: CDKBarcodeError, number: String) {
        spinner.stopAnimating()
        codeContainer.backgroundColor = .clear
        codeImageView.isHidden = true
        messageLabel.isHidden = false
        messageLabel.text = error.message
        numberLabel.text = number
        accessibilityLabel = "\(error.message) Card number \(number)"
    }

    private func setAspectRatio(_ ratio: CGFloat) {
        aspectConstraint?.isActive = false
        let constraint = codeContainer.widthAnchor.constraint(
            equalTo: codeContainer.heightAnchor,
            multiplier: max(ratio, 0.1)
        )
        constraint.priority = .defaultHigh
        constraint.isActive = true
        aspectConstraint = constraint
    }

    private func setUp() {
        backgroundColor = CDKTheme.Color.surface
        layer.cornerRadius = CDKTheme.Radius.surface
        layer.cornerCurve = .continuous

        codeContainer.backgroundColor = .white
        codeContainer.layer.cornerRadius = CDKTheme.Radius.button
        codeContainer.layer.cornerCurve = .continuous

        codeImageView.contentMode = .scaleAspectFit

        codeImageView.layer.magnificationFilter = .nearest
        codeImageView.layer.minificationFilter = .nearest

        numberLabel.font = CDKTheme.Font.mono(20, .semibold)
        numberLabel.textColor = CDKTheme.Color.textPrimary
        numberLabel.textAlignment = .center
        numberLabel.numberOfLines = 0

        messageLabel.font = CDKTheme.Font.caption
        messageLabel.textColor = CDKTheme.Color.textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.isHidden = true

        spinner.color = CDKTheme.Color.textSecondary

        codeContainer.cdkAddSubview(codeImageView)
        codeContainer.cdkAddSubview(spinner)
        cdkAddSubview(codeContainer)
        cdkAddSubview(numberLabel)
        cdkAddSubview(messageLabel)

        let inset = CDKTheme.Spacing.m
        NSLayoutConstraint.activate(
            codeImageView.cdkPinConstraints(to: codeContainer, inset: CDKTheme.Spacing.s)
        )
        NSLayoutConstraint.activate([
            codeContainer.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            codeContainer.leadingAnchor.constraint(
                greaterThanOrEqualTo: leadingAnchor, constant: inset
            ),
            codeContainer.trailingAnchor.constraint(
                lessThanOrEqualTo: trailingAnchor, constant: -inset
            ),
            codeContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            codeContainer.widthAnchor.constraint(
                equalTo: widthAnchor, constant: -inset * 2
            ).cdkWithPriority(.defaultLow),

            spinner.centerXAnchor.constraint(equalTo: codeContainer.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: codeContainer.centerYAnchor),

            numberLabel.topAnchor.constraint(
                equalTo: codeContainer.bottomAnchor, constant: CDKTheme.Spacing.m
            ),
            numberLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            numberLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),

            messageLabel.topAnchor.constraint(
                equalTo: numberLabel.bottomAnchor, constant: CDKTheme.Spacing.s
            ),
            messageLabel.leadingAnchor.constraint(equalTo: numberLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: numberLabel.trailingAnchor),
            messageLabel.bottomAnchor.constraint(
                lessThanOrEqualTo: bottomAnchor, constant: -inset
            ),
            numberLabel.bottomAnchor.constraint(
                lessThanOrEqualTo: bottomAnchor, constant: -inset
            ).cdkWithPriority(.defaultHigh)
        ])

        isAccessibilityElement = true
        accessibilityTraits = .image
    }
}

public extension UIView {

    func cdkPinConstraints(to view: UIView, inset: CGFloat = 0) -> [NSLayoutConstraint] {
        [
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -inset),
            topAnchor.constraint(equalTo: view.topAnchor, constant: inset),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -inset)
        ]
    }
}
