//
//  CDKBrightnessService.swift
//  Cardeck
//

import UIKit

/// Управление яркостью экрана на время показа кода.
public protocol CDKBrightnessServicing: AnyObject {
    /// Плавно поднимает яркость до максимума, запомнив исходное значение.
    func boost(on screen: UIScreen)
    /// Плавно возвращает исходную яркость.
    func restore()
    /// Мгновенно возвращает исходную яркость — для `deinit` и ухода в фон.
    func restoreImmediately()
}

/// Реализация подъёма яркости через `CADisplayLink`.
///
/// Исходное значение запоминается один раз при первом подъёме и возвращается
/// в любом сценарии выхода: закрытие экрана, уход в фон, `deinit` владельца.
/// Тумблер «авто-яркость» в настройках полностью отключает сервис.
public final class CDKBrightnessService: CDKBrightnessServicing {

    /// Общий экземпляр сервиса.
    public static let shared = CDKBrightnessService(preferences: CDKPreferences.shared)

    /// Длительность плавного перехода.
    private static let rampDuration: CFTimeInterval = 0.25

    private let preferences: CDKPreferencesProtocol

    private weak var screen: UIScreen?
    private var originalBrightness: CGFloat?
    private var displayLink: CADisplayLink?
    private var rampStart: CFTimeInterval = 0
    private var rampFrom: CGFloat = 0
    private var rampTo: CGFloat = 0

    /// Создаёт сервис поверх настроек приложения.
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
        // Страховка: если владелец исчез, не оставляем экран на максимуме.
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

    // MARK: - Приватное

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
        // easeOut: подъём начинается быстро и мягко упирается в целевое значение.
        let eased = 1 - pow(1 - progress, 3)
        screen.brightness = rampFrom + (rampTo - rampFrom) * CGFloat(eased)
        guard progress >= 1 else { return }
        stopRamp()
        // Возврат завершён — забываем исходное значение, чтобы не вернуть его повторно.
        if let originalBrightness, abs(rampTo - originalBrightness) < 0.001 {
            self.originalBrightness = nil
        }
    }

    @objc private func handleResignActive() {
        restoreImmediately()
    }
}
