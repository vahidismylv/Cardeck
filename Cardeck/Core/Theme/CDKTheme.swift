import UIKit

public enum CDKTheme {

    public enum Color {

        public static let background = UIColor(cdkHex: 0x0E0E12)

        public static let surface = UIColor(cdkHex: 0x17171F)

        public static let surfaceElevated = UIColor(cdkHex: 0x1F1F29)

        public static let textPrimary = UIColor(cdkHex: 0xF2F2F7)

        public static let textSecondary = UIColor(cdkHex: 0x8E8E9A)

        public static let accent = UIColor(cdkHex: 0x6E5BFF)

        public static let destructive = UIColor(cdkHex: 0xFF4D5E)

        public static let separator = UIColor(cdkHex: 0xF2F2F7, alpha: 0.08)
    }

    public enum Font {

        public static var largeTitle: UIFont { rounded(34, .bold) }

        public static var title: UIFont { rounded(22, .semibold) }

        public static var body: UIFont { rounded(17, .regular) }

        public static var callout: UIFont { rounded(15, .medium) }

        public static var caption: UIFont { rounded(13, .regular) }

        public static func mono(_ size: CGFloat, _ weight: UIFont.Weight = .medium) -> UIFont {
            .monospacedSystemFont(ofSize: size, weight: weight)
        }

        public static func rounded(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            return base.fontDescriptor.withDesign(.rounded)
                .map { UIFont(descriptor: $0, size: size) } ?? base
        }
    }

    public nonisolated enum Spacing {
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 16
        public static let l: CGFloat = 24
        public static let xl: CGFloat = 32
    }

    public nonisolated enum Radius {

        public static let card: CGFloat = 22

        public static let cardExpanded: CGFloat = 28

        public static let button: CGFloat = 14

        public static let surface: CGFloat = 18
    }

    public enum Shadow {
        public static let offset = CGSize(width: 0, height: 8)
        public static let blur: CGFloat = 24
        public static let opacity: Float = 0.35
        public static let color = UIColor.black.cgColor

        public static let liftedOffset = CGSize(width: 0, height: 18)
        public static let liftedBlur: CGFloat = 36
        public static let liftedOpacity: Float = 0.5
    }

    public nonisolated enum Card {

        public static let aspectRatio: CGFloat = 1.586

        public static let stackHorizontalInset: CGFloat = 20

        public static let detailHorizontalInset: CGFloat = 16

        public static let stackStep: CGFloat = 62

        public static let pinnedStep: CGFloat = 14

        public static let maxPinnedCards: Int = 4

        public static let pinInset: CGFloat = 12

        public static let perspective: CGFloat = -1.0 / 700.0

        public static let depthZStep: CGFloat = 8

        public static let deepestScale: CGFloat = 0.92

        public static let fadedAlpha: CGFloat = 0.55

        public static let liftedScale: CGFloat = 1.04

        public static let contentInset: CGFloat = 16

        public static let contentTopInset: CGFloat = 12

        public static func height(forWidth width: CGFloat) -> CGFloat {
            (width / aspectRatio).rounded()
        }
    }

    public enum Motion {

        public nonisolated static let transitionDuration: TimeInterval = 0.55
        public nonisolated static let transitionMass: CGFloat = 1.0
        public nonisolated static let transitionStiffness: CGFloat = 220
        public nonisolated static let transitionDamping: CGFloat = 26

        public nonisolated static let contentDelay: TimeInterval = 0.12

        public static let stagger: TimeInterval = 0.03

        public static func snappy(_ duration: TimeInterval = 0.35) -> UIViewPropertyAnimator {
            UIViewPropertyAnimator(
                duration: duration,
                timingParameters: UISpringTimingParameters(
                    mass: 1.0, stiffness: 320, damping: 26, initialVelocity: .zero
                )
            )
        }

        public static func transition(
            initialVelocity: CGVector = .zero
        ) -> UIViewPropertyAnimator {
            UIViewPropertyAnimator(
                duration: transitionDuration,
                timingParameters: UISpringTimingParameters(
                    mass: transitionMass,
                    stiffness: transitionStiffness,
                    damping: transitionDamping,
                    initialVelocity: initialVelocity
                )
            )
        }
    }
}
