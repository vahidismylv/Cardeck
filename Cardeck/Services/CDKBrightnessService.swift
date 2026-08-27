import UIKit

public protocol CDKBrightnessServicing: AnyObject {

    func boost(on screen: UIScreen)

    func restore()

    func restoreImmediately()
}

public final class CDKBrightnessService: CDKBrightnessServicing {

    public static let shared = CDKBrightnessService(preferences: CDKPreferences.shared)

    private static let rampDuration: CFTimeInterval = 0.25

    private let preferences: CDKPreferencesProtocol

    private weak var screen: UIScreen?
    private var originalBrightness: CGFloat?
    private var displayLink: CADisplayLink?
    private var rampStart: CFTimeInterval = 0
    private var rampFrom: CGFloat = 0
    private var rampTo: CGFloat = 0

    public init(preferences: CDKPreferencesProtocol) {
        self.preferences = preferences
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    deinit {

        displayLink?.invalidate()
        if let screen, let originalBrightness {
            screen.brightness = originalBrightness
        }
    }

    public func boost(on screen: UIScreen) {
        guard preferences.autoBrightnessEnabled else { return }
        self.screen = screen
        if originalBrightness == nil {
            originalBrightness = screen.brightness
        }
        ramp(to: 1.0)
    }

    public func restore() {
        guard let originalBrightness else { return }
        ramp(to: originalBrightness)
    }

    public func restoreImmediately() {
        stopRamp()
        guard let screen, let originalBrightness else { return }
        screen.brightness = originalBrightness
        self.originalBrightness = nil
    }

    private func ramp(to target: CGFloat) {
        guard let screen else { return }
        stopRamp()
        rampFrom = screen.brightness
        rampTo = target
        guard abs(rampTo - rampFrom) > 0.001 else { return }
        rampStart = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(step))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopRamp() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func step() {
        guard let screen else {
            stopRamp()
            return
        }
        let elapsed = CACurrentMediaTime() - rampStart
        let progress = min(elapsed / Self.rampDuration, 1)

        let eased = 1 - pow(1 - progress, 3)
        screen.brightness = rampFrom + (rampTo - rampFrom) * CGFloat(eased)
        guard progress >= 1 else { return }
        stopRamp()

        if let originalBrightness, abs(rampTo - originalBrightness) < 0.001 {
            self.originalBrightness = nil
        }
    }

    @objc private func handleResignActive() {
        restoreImmediately()
    }
}
