//
//  CDKCodeType.swift
//  Cardeck
//

import Foundation

/// Тип штрихового кода, которым закодирован номер карты.
public nonisolated enum CDKCodeType: String, CaseIterable, Codable, Sendable {

    /// Линейный Code 128 — самый частый формат карт лояльности.
    case code128
    /// QR-код.
    case qr
    /// Двумерный PDF417 — используется на транспортных и клубных картах.
    case pdf417

    /// Короткое имя для сегментированного контрола.
    public var title: String {
        switch self {
        case .code128: "Code 128"
        case .qr: "QR"
        case .pdf417: "PDF417"
        }
    }

    /// Описание для VoiceOver.
    public var accessibilityTitle: String {
        switch self {
        case .code128: "Code 128 barcode"
        case .qr: "QR code"
        case .pdf417: "PDF417 code"
        }
    }

    /// Соотношение сторон, в котором код читается лучше всего.
    ///
    /// Линейный код широкий и низкий, QR — квадратный.
    public var preferredAspectRatio: CGFloat {
        switch self {
        case .code128: 2.8
        case .qr: 1.0
        case .pdf417: 2.2
        }
    }

    /// Допускает ли формат произвольные символы Unicode.
    public var acceptsUnicode: Bool {
        switch self {
        case .code128: false
        case .qr, .pdf417: true
        }
    }
}
