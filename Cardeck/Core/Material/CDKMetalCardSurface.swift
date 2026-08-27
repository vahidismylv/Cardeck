import Metal
import UIKit

final class CDKMetalCardSurface: UIView {

    override class var layerClass: AnyClass { CAMetalLayer.self }

    private var metalLayer: CAMetalLayer { layer as! CAMetalLayer }
    private let renderer: CDKMetalCardRenderer

    private var gradient: CDKGradientPreset
    private var tilt: CDKTilt = .zero
    private var lastRenderedTilt: CDKTilt = CDKTilt(x: .infinity, y: .infinity)
    private var lastRenderTime: CFTimeInterval = 0
    private var createdAt = CACurrentMediaTime()
    private var isFlat: Bool

    var cornerRadius: CGFloat = CDKTheme.Radius.card {
        didSet {
            guard cornerRadius != oldValue else { return }
            setNeedsRender(force: true)
        }
    }

    private static let tiltEpsilon = 0.002

    private static let minimumFrameInterval: CFTimeInterval = 1.0 / 60.0

    init(renderer: CDKMetalCardRenderer, gradient: CDKGradientPreset, flat: Bool) {
        self.renderer = renderer
        self.gradient = gradient
        self.isFlat = flat
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        renderer.configure(metalLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let scale = traitCollection.displayScale > 0 ? traitCollection.displayScale : 3
        metalLayer.contentsScale = scale
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        guard size.width >= 1, size.height >= 1 else { return }
        if metalLayer.drawableSize != size {
            metalLayer.drawableSize = size
            setNeedsRender(force: true)
        }
    }

    func update(gradient: CDKGradientPreset, flat: Bool) {
        self.gradient = gradient
        self.isFlat = flat
        setNeedsRender(force: true)
    }

    func update(tilt: CDKTilt) {
        self.tilt = tilt
        setNeedsRender(force: false)
    }

    func setNeedsRender(force: Bool) {
        guard window != nil || force else { return }
        let now = CACurrentMediaTime()
        if !force {
            guard tilt.maxDelta(from: lastRenderedTilt) > Self.tiltEpsilon else { return }
            guard now - lastRenderTime >= Self.minimumFrameInterval else { return }
        }
        let uniforms = CDKCardUniforms(
            gradient: gradient,
            tilt: tilt,
            time: Float(now - createdAt),
            pixelSize: metalLayer.drawableSize,
            cornerRadius: cornerRadius,
            scale: metalLayer.contentsScale,
            flat: isFlat
        )
        guard renderer.render(uniforms: uniforms, into: metalLayer) else { return }
        lastRenderedTilt = tilt
        lastRenderTime = now
    }
}
