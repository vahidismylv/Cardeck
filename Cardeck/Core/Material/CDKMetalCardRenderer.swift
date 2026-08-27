import Metal
import QuartzCore

public final class CDKMetalCardRenderer {

    public static let shared: CDKMetalCardRenderer? = CDKMetalCardRenderer()

    public let device: MTLDevice

    private let pipelineState: MTLRenderPipelineState
    private let commandQueue: MTLCommandQueue

    private init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let library = try? device.makeDefaultLibrary(bundle: .main),
              let vertexFunction = library.makeFunction(name: "cdk_card_vertex"),
              let fragmentFunction = library.makeFunction(name: "cdk_card_fragment") else {
            return nil
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "CDKCardMaterial"
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        guard let state = try? device.makeRenderPipelineState(descriptor: descriptor) else {
            return nil
        }

        self.device = device
        self.commandQueue = queue
        self.pipelineState = state
    }

    public func configure(_ layer: CAMetalLayer) {
        layer.device = device
        layer.pixelFormat = .bgra8Unorm
        layer.framebufferOnly = true
        layer.isOpaque = false
        layer.maximumDrawableCount = 2
        layer.presentsWithTransaction = false
        layer.allowsNextDrawableTimeout = true
    }

    @discardableResult
    public func render(uniforms: CDKCardUniforms, into layer: CAMetalLayer) -> Bool {
        guard layer.drawableSize.width >= 1, layer.drawableSize.height >= 1 else { return false }
        guard let drawable = layer.nextDrawable(),
              let commandBuffer = commandQueue.makeCommandBuffer() else { return false }

        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = drawable.texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else {
            return false
        }
        var payload = uniforms
        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(
            &payload,
            length: MemoryLayout<CDKCardUniforms>.stride,
            index: 0
        )
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
        return true
    }
}
