import UIKit

final class CDKMaterialFallbackView: UIView {

    private let gradientLayer = CAGradientLayer()
    private let sheenLayer = CAGradientLayer()
    private let noiseLayer = CALayer()

    private var gradient: CDKGradientPreset
    private var isFlat: Bool

    var cornerRadius: CGFloat = CDKTheme.Radius.card {
        didSet {
            guard cornerRadius != oldValue else { return }
            applyCornerRadius()
            setNeedsLayout()
        }
    }

    init(gradient: CDKGradientPreset, flat: Bool) {
        self.gradient = gradient
        self.isFlat = flat
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear

        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)

        sheenLayer.colors = [
            UIColor.white.withAlphaComponent(0).cgColor,
            UIColor.white.withAlphaComponent(0.28).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor
        ]
        sheenLayer.locations = [0.0, 0.5, 1.0]

        noiseLayer.contentsGravity = .resize

        layer.addSublayer(gradientLayer)
        layer.addSublayer(sheenLayer)
        layer.addSublayer(noiseLayer)
        applyCornerRadius()
        applyColors()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        sheenLayer.frame = bounds
        noiseLayer.frame = bounds
        noiseLayer.contents = CDKNoiseTexture.image(
            size: bounds.size,
            cornerRadius: cornerRadius,
            amplitude: CGFloat(CDKCardUniforms.Default.noiseAmplitude)
        )?.cgImage
        CATransaction.commit()
    }

    func update(gradient: CDKGradientPreset, flat: Bool) {
        self.gradient = gradient
        self.isFlat = flat
        applyColors()
    }

    func animateCornerRadius(from start: CGFloat, to target: CGFloat) {
        cornerRadius = target
        let animation = CASpringAnimation(keyPath: "cornerRadius")
        animation.mass = CDKTheme.Motion.transitionMass
        animation.stiffness = CDKTheme.Motion.transitionStiffness
        animation.damping = CDKTheme.Motion.transitionDamping
        animation.duration = CDKTheme.Motion.transitionDuration
        animation.fromValue = start
        animation.toValue = target
        for target in [gradientLayer, sheenLayer] {
            target.add(animation, forKey: "cdkCornerRadius")
        }
    }

    func update(tilt: CDKTilt) {
        guard !isFlat else { return }

        let shift = CGFloat(tilt.x).cdkClamped(-0.6, 0.6) / 0.6
        let center = 0.5 + shift * 0.45
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        sheenLayer.startPoint = CGPoint(x: center - 0.55, y: -0.15)
        sheenLayer.endPoint = CGPoint(x: center + 0.55, y: 1.15)
        CATransaction.commit()
    }

    private func applyColors() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.colors = isFlat
            ? [gradient.flatColor.cgColor, gradient.flatColor.cgColor]
            : gradient.cgColors
        sheenLayer.isHidden = isFlat
        noiseLayer.isHidden = isFlat
        CATransaction.commit()
    }

    private func applyCornerRadius() {
        for target in [gradientLayer, sheenLayer] {
            target.cornerRadius = cornerRadius
            target.cornerCurve = .continuous
        }
        noiseLayer.cornerCurve = .continuous
    }
}
