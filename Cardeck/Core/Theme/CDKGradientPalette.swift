//
//  CDKGradientPalette.swift
//  Cardeck
//

import UIKit

/// Палитра из восьми диагональных градиентов для карт.
///
/// Каждый пресет — два насыщенных стопа. Индекс пресета хранится в модели карты,
/// поэтому порядок элементов менять нельзя: он часть формата данных.
public enum CDKGradientPalette {

    /// Все пресеты палитры в порядке хранения.
    public static let presets: [CDKGradientPreset] = [
        CDKGradientPreset(name: "Midnight", start: 0x1B2A6B, end: 0x6B2FB3),
        CDKGradientPreset(name: "Emerald", start: 0x0B6B4F, end: 0x1FC8B4),
        CDKGradientPreset(name: "Sunset", start: 0x8C1230, end: 0xF2762A),
        CDKGradientPreset(name: "Graphite", start: 0x24262B, end: 0x646B78),
        CDKGradientPreset(name: "Indigo", start: 0x2B1F8C, end: 0xC42BA8),
        CDKGradientPreset(name: "Pine", start: 0x14432A, end: 0x9BD31F),
        CDKGradientPreset(name: "Bordeaux", start: 0x5C1030, end: 0xE8558F),
        CDKGradientPreset(name: "Gold", start: 0xD9A521, end: 0x8A4B18)
    ]

    /// Количество пресетов.
    public static var count: Int { presets.count }

    /// Пресет по индексу; индекс приводится к диапазону палитры.
    public static func preset(at index: Int) -> CDKGradientPreset {
        presets[((index % count) + count) % count]
    }
}

/// Один градиентный пресет карты: имя для доступности и два цветовых стопа.
public struct CDKGradientPreset: Equatable {

    /// Человекочитаемое имя пресета, читается VoiceOver в пикере.
    public let name: String
    /// Начальный цвет диагонали (верхний левый угол).
    public let start: UIColor
    /// Конечный цвет диагонали (нижний правый угол).
    public let end: UIColor

    /// Создаёт пресет из двух шестнадцатеричных значений RGB.
    public init(name: String, start: UInt32, end: UInt32) {
        self.name = name
        self.start = UIColor(cdkHex: start)
        self.end = UIColor(cdkHex: end)
    }

    /// Плоский цвет для режима Increase Contrast, где градиенты запрещены.
    public var flatColor: UIColor {
        start.cdkBlended(with: end, fraction: 0.5).cdkDarkened(by: 0.12)
    }

    /// Стопы в виде `CGColor` для `CAGradientLayer`.
    public var cgColors: [CGColor] { [start.cgColor, end.cgColor] }

    /// Стопы в виде линейных компонент RGBA для передачи в шейдер.
    public var shaderColors: (start: SIMD4<Float>, end: SIMD4<Float>) {
        (start.cdkFloat4, end.cdkFloat4)
    }
}
