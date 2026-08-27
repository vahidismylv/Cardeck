import UIKit

public final class CDKGradientPickerView: UIView {

    public var onSelect: ((Int) -> Void)?

    private let haptics: CDKHapticsServiceProtocol
    private let stack = UIStackView()
    private let scrollView = UIScrollView()
    private var swatches: [CDKGradientSwatch] = []

    public private(set) var selectedIndex: Int = 0

    public init(haptics: CDKHapticsServiceProtocol) {
        self.haptics = haptics
        super.init(frame: .zero)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    public func select(index: Int, animated: Bool) {
        selectedIndex = index
        for (position, swatch) in swatches.enumerated() {
            swatch.setSelected(position == index, animated: animated)
        }
    }

    private func setUp() {
        scrollView.showsHorizontalScrollIndicator = false

        scrollView.decelerationRate = .fast
        stack.axis = .horizontal
        stack.spacing = CDKTheme.Spacing.m

        for index in 0..<CDKGradientPalette.count {
            let swatch = CDKGradientSwatch(preset: CDKGradientPalette.preset(at: index))
            swatch.accessibilityLabel = CDKGradientPalette.preset(at: index).name
            swatch.addAction(
                UIAction { [weak self] _ in self?.handleTap(index: index) },
                for: .touchUpInside
            )
            swatches.append(swatch)
            stack.addArrangedSubview(swatch)
        }

        cdkAddSubview(scrollView)
        scrollView.cdkAddSubview(stack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor
            ),
            stack.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor
            ),
            stack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            heightAnchor.constraint(equalToConstant: CDKGradientSwatch.side)
        ])
        select(index: 0, animated: false)
    }

    private func handleTap(index: Int) {
        guard index != selectedIndex else { return }
        select(index: index, animated: true)
        haptics.playSelection()
        onSelect?(index)
    }
}

final class CDKGradientSwatch: UIControl {

    static let side: CGFloat = 44

    private let gradientLayer = CAGradientLayer()
    private let ring = CALayer()

    init(preset: CDKGradientPreset) {
        super.init(frame: .zero)
        isAccessibilityElement = true
        accessibilityTraits = .button

        gradientLayer.colors = preset.cgColors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        ring.borderColor = CDKTheme.Color.textPrimary.cgColor
        ring.borderWidth = 0
        layer.addSublayer(gradientLayer)
        layer.addSublayer(ring)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.side),
            heightAnchor.constraint(equalToConstant: Self.side)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let inset: CGFloat = 5
        gradientLayer.frame = bounds.insetBy(dx: inset, dy: inset)
        gradientLayer.cornerRadius = gradientLayer.bounds.width / 2
        ring.frame = bounds
        ring.cornerRadius = bounds.width / 2
        CATransaction.commit()
    }

    func setSelected(_ selected: Bool, animated: Bool) {
        accessibilityTraits = selected ? [.button, .selected] : .button
        let apply = { self.ring.borderWidth = selected ? 2 : 0 }
        guard animated else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            apply()
            CATransaction.commit()
            return
        }
        apply()
    }
}
