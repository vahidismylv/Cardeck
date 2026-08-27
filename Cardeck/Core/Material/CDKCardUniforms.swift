import CoreGraphics
import simd

public struct CDKCardUniforms {

    public var colorA: SIMD4<Float>

    public var colorB: SIMD4<Float>

    public var tilt: SIMD2<Float>

    public var resolution: SIMD2<Float>

    public var time: Float

    public var cornerRadius: Float

    public var hologramStrength: Float

    public var specularStrength: Float

    public var noiseAmplitude: Float

    public var flatMode: Float

    public enum Default {
        public static let hologramStrength: Float = 0.35
        public static let specularStrength: Float = 0.6
        public static let noiseAmplitude: Float = 0.04
    }

    public init(
        gradient: CDKGradientPreset,
        tilt: CDKTilt,
        time: Float,
        pixelSize: CGSize,
        cornerRadius: CGFloat,
        scale: CGFloat,
        flat: Bool
    ) {
        let colors = gradient.shaderColors
        if flat {
            let flatColor = gradient.flatColor.cdkFloat4
            self.colorA = flatColor
            self.colorB = flatColor
        } else {
            self.colorA = colors.start
            self.colorB = colors.end
        }
        self.tilt = SIMD2<Float>(Float(tilt.x), Float(tilt.y))
        self.resolution = SIMD2<Float>(Float(pixelSize.width), Float(pixelSize.height))
        self.time = time
        self.cornerRadius = Float(cornerRadius * scale)
        self.hologramStrength = Default.hologramStrength
        self.specularStrength = Default.specularStrength
        self.noiseAmplitude = Default.noiseAmplitude
        self.flatMode = flat ? 1.0 : 0.0
    }
}
