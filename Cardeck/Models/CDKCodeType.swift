import Foundation

public nonisolated enum CDKCodeType: String, CaseIterable, Codable, Sendable {

    case code128

    case qr

    case pdf417

    public var title: String {
        switch self {
        case .code128: "Code 128"
        case .qr: "QR"
        case .pdf417: "PDF417"
        }
    }

    public var accessibilityTitle: String {
        switch self {
        case .code128: "Code 128 barcode"
        case .qr: "QR code"
        case .pdf417: "PDF417 code"
        }
    }

    public var preferredAspectRatio: CGFloat {
        switch self {
        case .code128: 2.8
        case .qr: 1.0
        case .pdf417: 2.2
        }
    }

    public var acceptsUnicode: Bool {
        switch self {
        case .code128: false
        case .qr, .pdf417: true
        }
    }
}
