import CoreMotion
import UIKit

public nonisolated struct CDKTilt: Equatable, Sendable {

    public var x: Double
    public var y: Double

    public static let zero = CDKTilt(x: 0, y: 0)

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public func maxDelta(from other: CDKTilt) -> Double {
        max(abs(x - other.x), abs(y - other.y))
    }
}

public protocol CDKMotionObserver: AnyObject {

    func motionService(_ service: CDKMotionServiceProtocol, didUpdate tilt: CDKTilt)
}

public protocol CDKMotionServiceProtocol: AnyObject {

    var tilt: CDKTilt { get }

    var isAvailable: Bool { get }

    func addObserver(_ observer: CDKMotionObserver)

    func removeObserver(_ observer: CDKMotionObserver)
}

public final class CDKMotionService: CDKMotionServiceProtocol {

    public static let shared = CDKMotionService()

    private static let smoothingFactor = 0.88
    private static let updateInterval = 1.0 / 60.0

    private let manager = CMMotionManager()
    private let observers = NSHashTable<AnyObject>.weakObjects()
    private var isRunning = false

    public private(set) var tilt: CDKTilt = .zero

    public var isAvailable: Bool {
        manager.isDeviceMotionAvailable && !UIAccessibility.isReduceMotionEnabled
    }

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    deinit {
        manager.stopDeviceMotionUpdates()
    }

    public func addObserver(_ observer: CDKMotionObserver) {
        observers.add(observer)
        observer.motionService(self, didUpdate: tilt)
        startIfNeeded()
    }

    public func removeObserver(_ observer: CDKMotionObserver) {
        observers.remove(observer)
        stopIfIdle()
    }

    private func startIfNeeded() {
        guard !isRunning, isAvailable, observers.count > 0 else { return }
        isRunning = true
        manager.deviceMotionUpdateInterval = Self.updateInterval
        manager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: .main
        ) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.consume(motion.attitude)
        }
    }

    private func stopIfIdle() {
        guard isRunning, observers.count == 0 else { return }
        isRunning = false
        manager.stopDeviceMotionUpdates()
    }

    private func consume(_ attitude: CMAttitude) {
        let factor = Self.smoothingFactor
        tilt = CDKTilt(
            x: tilt.x * factor + attitude.roll * (1 - factor),
            y: tilt.y * factor + attitude.pitch * (1 - factor)
        )
        for case let observer as CDKMotionObserver in observers.allObjects {
            observer.motionService(self, didUpdate: tilt)
        }
    }

    @objc private func handleBackground() {
        guard isRunning else { return }
        isRunning = false
        manager.stopDeviceMotionUpdates()
    }

    @objc private func handleForeground() {
        startIfNeeded()
    }
}
