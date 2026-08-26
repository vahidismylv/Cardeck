//
//  CDKCardUniforms.swift
//  Cardeck
//

import CoreGraphics
import simd

/// Параметры материала карты, передаваемые во фрагментный шейдер.
///
/// Порядок полей обязан совпадать с `CDKCardUniforms` в `CDKCardShader.metal`:
/// векторы `float4` идут первыми, поэтому смещения полей одинаковы
/// в Swift и в Metal без ручного выравнивания.
public struct CDKCardUniforms {

    /// Начальный цвет диагонального градиента.
    public var colorA: SIMD4<Float>
    /// Конечный цвет диагонального градиента.
    public var colorB: SIMD4<Float>
    /// Наклон устройства в радианах.
    public var tilt: SIMD2<Float>
    /// Размер холста в пикселях.
    public var resolution: SIMD2<Float>
    /// Время с момента создания вью — для медленного дрейфа голограммы.
    public var time: Float
    /// Радиус скругления в пикселях.
    public var cornerRadius: Float
    /// Сила голографического слоя.
    public var hologramStrength: Float
    /// Сила зеркального блика.
    public var specularStrength: Float
    /// Амплитуда зерна.
    public var noiseAmplitude: Float
    /// 1.0 — плоский цвет без эффектов (режим Increase Contrast).
    public var flatMode: Float

    /// Значения по умолчанию, заданные дизайн-системой.
    public enum Default {
        public static let hologramStrength: Float = 0.35
        public static let specularStrength: Float = 0.6
        public static let noiseAmplitude: Float = 0.04
    }

    /// Собирает параметры материала для одной карты.
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
