import UIKit

public enum CDKNoiseTexture {

    private static let cache = NSCache<NSString, UIImage>()
    private static let tileSide = 128

    public static func image(
        size: CGSize,
        cornerRadius: CGFloat,
        amplitude: CGFloat
    ) -> UIImage? {
        guard size.width >= 1, size.height >= 1 else { return nil }
        let key = "\(Int(size.width))x\(Int(size.height))r\(Int(cornerRadius))" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let tile = grainTile() else { return nil }

        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
            context.cgContext.setAlpha(amplitude)
            context.cgContext.draw(tile, in: rect, byTiling: true)
        }
        cache.setObject(image, forKey: key)
        return image
    }

    private static func grainTile() -> CGImage? {
        let side = tileSide

        guard let context = CGContext(
            data: nil,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: side,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ), let data = context.data else { return nil }

        let pixels = data.bindMemory(to: UInt8.self, capacity: side * side)
        var generator = SystemRandomNumberGenerator()
        for index in 0..<(side * side) {
            pixels[index] = UInt8.random(in: 96...200, using: &generator)
        }
        return context.makeImage()
    }
}
