import CoreHaptics
import UIKit

public protocol CDKHapticsServiceProtocol: AnyObject {

    func playSnap()

    func playSelection()

    func beginDrag()

    func updateDrag(progress: Double)

    func endDrag()
}

public final class CDKHapticsService: CDKHapticsServiceProtocol {

    public static let shared = CDKHapticsService(preferences: CDKPreferences.shared)

    private let preferences: CDKPreferencesProtocol
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private var engine: CHHapticEngine?
    private var dragPlayer: CHHapticAdvancedPatternPlayer?
    private var impactGenerator: UIImpactFeedbackGenerator?
    private var selectionGenerator: UISelectionFeedbackGenerator?

    public init(preferences: CDKPreferencesProtocol) {
        self.preferences = preferences
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    deinit {
        engine?.stop()
    }

    private var isEnabled: Bool { preferences.hapticsEnabled }

    public func playSnap() {
        guard isEnabled else { return }
        guard supportsHaptics, let engine = preparedEngine() else {
            fallbackImpact(intensity: 0.7)
            return
        }
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
            ],
            relativeTime: 0
        )
        play(events: [event], on: engine)
    }

    public func playSelection() {
        guard isEnabled else { return }
        guard supportsHaptics, let engine = preparedEngine() else {
            let generator = selectionGenerator ?? UISelectionFeedbackGenerator()
            selectionGenerator = generator
            generator.selectionChanged()
            return
        }
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.45),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
            ],
            relativeTime: 0
        )
        play(events: [event], on: engine)
    }

    public func beginDrag() {
        guard isEnabled, supportsHaptics, let engine = preparedEngine() else { return }
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35)
            ],
            relativeTime: 0,
            duration: 30
        )
        dragPlayer = try? engine.makeAdvancedPlayer(with: CHHapticPattern(events: [event], parameters: []))
        try? dragPlayer?.start(atTime: CHHapticTimeImmediate)
    }

    public func updateDrag(progress: Double) {
        guard let dragPlayer else { return }
        let intensity = Float(min(max(progress, 0), 1)) * 0.8
        let parameter = CHHapticDynamicParameter(
            parameterID: .hapticIntensityControl,
            value: intensity,
            relativeTime: 0
        )
        try? dragPlayer.sendParameters([parameter], atTime: CHHapticTimeImmediate)
    }

    public func endDrag() {
        try? dragPlayer?.stop(atTime: CHHapticTimeImmediate)
        dragPlayer = nil
    }

    private func preparedEngine() -> CHHapticEngine? {
        if let engine { return engine }
        guard let created = try? CHHapticEngine() else { return nil }
        created.playsHapticsOnly = true
        created.isAutoShutdownEnabled = true
        created.resetHandler = { [weak self] in
            self?.dragPlayer = nil
            try? self?.engine?.start()
        }
        created.stoppedHandler = { [weak self] _ in
            self?.dragPlayer = nil
            self?.engine = nil
        }
        try? created.start()
        engine = created
        return created
    }

    private func play(events: [CHHapticEvent], on engine: CHHapticEngine) {
        guard let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine.makePlayer(with: pattern) else {
            fallbackImpact(intensity: 0.7)
            return
        }
        try? player.start(atTime: CHHapticTimeImmediate)
    }

    private func fallbackImpact(intensity: CGFloat) {
        let generator = impactGenerator ?? UIImpactFeedbackGenerator(style: .medium)
        impactGenerator = generator
        generator.impactOccurred(intensity: intensity)
    }

    @objc private func handleBackground() {
        endDrag()
        engine?.stop()
        engine = nil
    }
}
