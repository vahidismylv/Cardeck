import UIKit
import simd

public nonisolated extension UIColor {

    convenience init(cdkHex hex: UInt32, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: alpha
        )
    }

    var cdkComponents: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    var cdkFloat4: SIMD4<Float> {
        let c = cdkComponents
        return SIMD4<Float>(Float(c.r), Float(c.g), Float(c.b), Float(c.a))
    }

    func cdkBlended(with other: UIColor, fraction: CGFloat) -> UIColor {
        let a = cdkComponents, b = other.cdkComponents
        let t = min(max(fraction, 0), 1)
        return UIColor(
            red: a.r + (b.r - a.r) * t,
            green: a.g + (b.g - a.g) * t,
            blue: a.b + (b.b - a.b) * t,
            alpha: a.a + (b.a - a.a) * t
        )
    }

    func cdkDarkened(by amount: CGFloat) -> UIColor {
        cdkBlended(with: .black, fraction: amount)
    }

    @MainActor var cdkReadableForeground: UIColor {
        let c = cdkComponents
        let luminance = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
        return luminance > 0.62 ? UIColor(cdkHex: 0x14141A) : CDKTheme.Color.textPrimary
    }
}
