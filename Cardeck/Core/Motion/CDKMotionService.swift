//
//  CDKMotionService.swift
//  Cardeck
//

import CoreMotion
import UIKit

/// Наклон устройства в радианах: `x` — крен, `y` — тангаж.
public nonisolated struct CDKTilt: Equatable, Sendable {

    public var x: Double
    public var y: Double

    /// Нулевой наклон — состояние покоя и режим Reduce Motion.
    public static let zero = CDKTilt(x: 0, y: 0)

    /// Создаёт наклон.
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    /// Максимальная покомпонентная разница с другим наклоном.
    public func maxDelta(from other: CDKTilt) -> Double {
        max(abs(x - other.x), abs(y - other.y))
    }
}

/// Подписчик на обновления наклона устройства.
public protocol CDKMotionObserver: AnyObject {
    /// Вызывается на главном потоке при каждом сглаженном обновлении наклона.
    func motionService(_ service: CDKMotionServiceProtocol, didUpdate tilt: CDKTilt)
}

/// Источник данных о наклоне устройства.
public protocol CDKMotionServiceProtocol: AnyObject {
    /// Текущий сглаженный наклон.
    var tilt: CDKTilt { get }
    /// Доступен ли датчик и разрешено ли его использовать.
    var isAvailable: Bool { get }
    /// Добавляет подписчика; ссылка слабая, отписка не обязательна.
    func addObserver(_ observer: CDKMotionObserver)
    /// Убирает подписчика.
    func removeObserver(_ observer: CDKMotionObserver)
}

/// Единый на приложение сервис наклона поверх `CMMotionManager`.
///
/// Датчик работает только когда есть хотя бы один подписчик и приложение активно.
/// При включённом Reduce Motion не запускается вовсе: наклон остаётся нулевым,
/// блик на картах — статичным.
public final class CDKMotionService: CDKMotionServiceProtocol {

    /// Общий экземпляр сервиса.
    public static let shared = CDKMotionService()

    /// Коэффициент сглаживания: `smoothed = smoothed * factor + new * (1 - factor)`.
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

    // MARK: - Жизненный цикл датчика

    /// Запускает датчик, если есть подписчики и наклон вообще имеет смысл.
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

    /// Останавливает датчик, когда подписчиков не осталось.
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
