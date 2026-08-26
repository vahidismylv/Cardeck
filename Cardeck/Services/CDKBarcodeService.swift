//
//  CDKBarcodeService.swift
//  Cardeck
//

import CoreImage
import UIKit

/// Причина, по которой код не удалось построить.
public nonisolated enum CDKBarcodeError: Error, Equatable {
    /// Номер пустой.
    case empty
    /// Code 128 кодирует только ASCII 0...127.
    case unsupportedCharacters
    /// Фильтр Core Image не вернул изображение.
    case generationFailed

    /// Сообщение для экрана — показывается вместе с крупным номером.
    public var message: String {
        switch self {
        case .empty: "This card has no number."
        case .unsupportedCharacters: "Code 128 supports Latin characters only."
        case .generationFailed: "Could not render the barcode."
        }
    }
}

/// Генератор штриховых кодов.
public protocol CDKBarcodeServicing: AnyObject, Sendable {
    /// Строит изображение кода синхронно; безопасно вызывать с любого потока.
    func generate(payload: String, type: CDKCodeType, size: CGSize) throws -> UIImage
    /// Строит изображение кода вне главного потока.
    func image(payload: String, type: CDKCodeType, size: CGSize) async throws -> UIImage
}

/// Реализация на Core Image с общим `CIContext` и кешем результатов.
///
/// Апскейл делается на `CIImage` аффинным преобразованием, без интерполяции:
/// размытый код сканер не читает. Слой, показывающий результат, обязан стоять
/// на `magnificationFilter = .nearest`.
public nonisolated final class CDKBarcodeService: CDKBarcodeServicing, @unchecked Sendable {

    /// Общий экземпляр сервиса.
    public static let shared = CDKBarcodeService()

    private let context: CIContext
    private let cache = NSCache<NSString, UIImage>()

    /// Создаёт сервис с собственным `CIContext`.
    public init() {
        context = CIContext(options: [.useSoftwareRenderer: false])
        cache.countLimit = 32
    }

    public func image(
        payload: String,
        type: CDKCodeType,
        size: CGSize
    ) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) { [self] in
            try generate(payload: payload, type: type, size: size)
        }.value
    }

    public func generate(payload: String, type: CDKCodeType, size: CGSize) throws -> UIImage {
        try validate(payload: payload, type: type)
        let scale = UITraitCollection.current.displayScale
        let pixelSize = CGSize(
            width: max(size.width * scale, 1).rounded(),
            height: max(size.height * scale, 1).rounded()
        )
        let key = "\(payload)|\(type.rawValue)|\(Int(pixelSize.width))x\(Int(pixelSize.height))"
            as NSString
        if let cached = cache.object(forKey: key) { return cached }

        guard let source = makeCIImage(payload: payload, type: type) else {
            throw CDKBarcodeError.generationFailed
        }
        // Целочисленный коэффициент увеличения — модули кода остаются одинаковой ширины.
        let factor = max(
            floor(min(
                pixelSize.width / source.extent.width,
                pixelSize.height / source.extent.height
            )),
            1
        )
        let scaled = source.transformed(by: CGAffineTransform(scaleX: factor, y: factor))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else {
            throw CDKBarcodeError.generationFailed
        }
        let image = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
        cache.setObject(image, forKey: key)
        return image
    }

    // MARK: - Приватное

    /// Проверяет полезную нагрузку до обращения к Core Image.
    private func validate(payload: String, type: CDKCodeType) throws {
        guard !payload.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CDKBarcodeError.empty
        }
        if type == .code128, !payload.unicodeScalars.allSatisfy({ $0.value <= 127 }) {
            throw CDKBarcodeError.unsupportedCharacters
        }
    }

    private func makeCIImage(payload: String, type: CDKCodeType) -> CIImage? {
        let data: Data?
        let filterName: String
        var parameters: [String: Any] = [:]

        switch type {
        case .code128:
            data = payload.data(using: .ascii)
            filterName = "CICode128BarcodeGenerator"
            parameters["inputQuietSpace"] = 8
        case .qr:
            data = payload.data(using: .utf8)
            filterName = "CIQRCodeGenerator"
            parameters["inputCorrectionLevel"] = "M"
        case .pdf417:
            data = payload.data(using: .utf8)
            filterName = "CIPDF417BarcodeGenerator"
        }

        guard let data, let filter = CIFilter(name: filterName) else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        for (key, value) in parameters {
            filter.setValue(value, forKey: key)
        }
        return filter.outputImage
    }
}
