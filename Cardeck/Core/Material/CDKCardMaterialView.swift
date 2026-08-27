import UIKit

public final class CDKCardMaterialView: UIView, CDKMotionObserver {

    private let metalSurface: CDKMetalCardSurface?
    private let fallbackSurface: CDKMaterialFallbackView?
    private let motionService: CDKMotionServiceProtocol

    private var isObservingMotion = false

    private var gradient: CDKGradientPreset
    private var cornerRadiusLink: CADisplayLink?
    private var cornerRadiusStart: CGFloat = 0
    private var cornerRadiusTarget: CGFloat = 0
    private var cornerRadiusBeganAt: CFTimeInterval = 0

    public var isHardwareAccelerated: Bool { metalSurface != nil }

    public var cornerRadius: CGFloat = CDKTheme.Radius.card {
        didSet {
            metalSurface?.cornerRadius = cornerRadius
            fallbackSurface?.cornerRadius = cornerRadius
        }
    }

    public init(
        gradient: CDKGradientPreset,
        preferences: CDKPreferencesProtocol = CDKPreferences.shared,
        motionService: CDKMotionServiceProtocol = CDKMotionService.shared
    ) {
        self.motionService = motionService
        self.gradient = gradient
        let flat = UIAccessibility.isDarkerSystemColorsEnabled
        if preferences.holographicEnabled, let renderer = CDKMetalCardRenderer.shared {
            metalSurface = CDKMetalCardSurface(renderer: renderer, gradient: gradient, flat: flat)
            fallbackSurface = nil
        } else {
            metalSurface = nil
            fallbackSurface = CDKMaterialFallbackView(gradient: gradient, flat: flat)
        }
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        let surface: UIView = metalSurface ?? fallbackSurface!
        cdkAddSubview(surface)
        surface.cdkPin(to: self)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContrastChange),
            name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil
        )
    }

    @objc private func handleContrastChange() {
        update(gradient: gradient)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    deinit {
        cornerRadiusLink?.invalidate()
        motionService.removeObserver(self)
    }

    public func update(gradient: CDKGradientPreset) {
        self.gradient = gradient
        let flat = UIAccessibility.isDarkerSystemColorsEnabled
        metalSurface?.update(gradient: gradient, flat: flat)
        fallbackSurface?.update(gradient: gradient, flat: flat)
    }

    public func startMotionUpdates() {
        guard !isObservingMotion else { return }
        isObservingMotion = true
        motionService.addObserver(self)
    }

    public func stopMotionUpdates() {
        guard isObservingMotion else { return }
        isObservingMotion = false
        motionService.removeObserver(self)
    }

    public func refresh() {
        metalSurface?.setNeedsRender(force: true)
        fallbackSurface?.setNeedsLayout()
    }

    public func animateCornerRadius(from start: CGFloat, to target: CGFloat) {
        stopCornerRadiusAnimation()
        cornerRadius = target
        if let fallbackSurface {
            fallbackSurface.animateCornerRadius(from: start, to: target)
            return
        }
        guard metalSurface != nil else { return }
        cornerRadiusStart = start
        cornerRadiusTarget = target
        cornerRadiusBeganAt = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(stepCornerRadius))
        link.add(to: .main, forMode: .common)
        cornerRadiusLink = link
    }

    public func stopCornerRadiusAnimation() {
        cornerRadiusLink?.invalidate()
        cornerRadiusLink = nil
        metalSurface?.cornerRadius = cornerRadius
    }

    @objc private func stepCornerRadius() {
        let elapsed = CACurrentMediaTime() - cornerRadiusBeganAt
        let radius = CDKSpring.cardTransition.value(
            from: cornerRadiusStart,
            to: cornerRadiusTarget,
            at: elapsed
        )
        let presented = layer.presentation()?.bounds.width ?? bounds.width
        let compensation = bounds.width / max(presented, 1)
        metalSurface?.cornerRadius = radius * compensation
        guard elapsed >= CDKTheme.Motion.transitionDuration else { return }
        stopCornerRadiusAnimation()
    }

    public func motionService(_ service: CDKMotionServiceProtocol, didUpdate tilt: CDKTilt) {
        metalSurface?.update(tilt: tilt)
        fallbackSurface?.update(tilt: tilt)
    }
}
