//
//  CDKSpring.swift
//  Cardeck
//

import CoreGraphics
import Foundation

/// Аналитическое решение пружины «масса — жёсткость — затухание».
///
/// Нужно там, где кривую нельзя отдать Core Animation: радиус скругления карты
/// считает фрагментный шейдер, а не слой, поэтому значение приходится
/// интерполировать вручную теми же параметрами, что и у остальной анимации перехода.
public nonisolated struct CDKSpring {

    private let omega: Double
    private let zeta: Double

    /// Создаёт пружину с параметрами `UISpringTimingParameters`.
    public init(mass: CGFloat, stiffness: CGFloat, damping: CGFloat) {
        let m = max(Double(mass), .leastNonzeroMagnitude)
        let k = max(Double(stiffness), .leastNonzeroMagnitude)
        omega = (k / m).squareRoot()
        zeta = Double(damping) / (2 * (k * m).squareRoot())
    }

    /// Пружина перехода карты, заданная в ``CDKTheme/Motion``.
    public static var cardTransition: CDKSpring {
        CDKSpring(
            mass: CDKTheme.Motion.transitionMass,
            stiffness: CDKTheme.Motion.transitionStiffness,
            damping: CDKTheme.Motion.transitionDamping
        )
    }

    /// Прогресс 0...1 в момент времени `time` (в секундах от начала анимации).
    ///
    /// Для затухания меньше критического возвращает классическое решение
    /// с колебанием, для критического и выше — апериодическое.
    public func progress(at time: TimeInterval) -> CGFloat {
        guard time > 0 else { return 0 }
        let t = time
        if zeta < 1 {
            let omegaD = omega * (1 - zeta * zeta).squareRoot()
            let decay = exp(-zeta * omega * t)
            let value = 1 - decay * (cos(omegaD * t) + (zeta * omega / omegaD) * sin(omegaD * t))
            return CGFloat(value)
        }
        let decay = exp(-omega * t)
        return CGFloat(1 - decay * (1 + omega * t))
    }

    /// Интерполяция между двумя значениями по кривой пружины.
    public func value(from: CGFloat, to: CGFloat, at time: TimeInterval) -> CGFloat {
        from + (to - from) * progress(at: time)
    }
}
