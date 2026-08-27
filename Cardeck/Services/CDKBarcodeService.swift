import CoreImage
import UIKit

public nonisolated enum CDKBarcodeError: Error, Equatable {

    case empty

    case unsupportedCharacters

    case generationFailed

    public var message: String {
        switch self {
        case .empty: "This card has no number."
        case .unsupportedCharacters: "Code 128 supports Latin characters only."
        case .generationFailed: "Could not render the barcode."
        }
    }
}

public protocol CDKBarcodeServicing: AnyObject, Sendable {

    func generate(payload: String, type: CDKCodeType, size: CGSize) throws -> UIImage

    func image(payload: String, type: CDKCodeType, size: CGSize) async throws -> UIImage
}

public nonisolated final class CDKBarcodeService: CDKBarcodeServicing, @unchecked Sendable {

    public static let shared = CDKBarcodeService()

    private let context: CIContext
    private let cache = NSCache<NSString, UIImage>()

    public init() {
        context = CIContext(options: [.useSoftwareRenderer: false])
        cache.countLimit = 32
    }

    public nonisolated func image(
        payload: String,
        type: CDKCodeType,
        size: CGSize
    ) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) { [self] in
            try generate(payload: payload, type: type, size: size)
        }.value
    }

    public nonisolated func generate(
        payload: String,
        type: CDKCodeType,
        size: CGSize
    ) throws -> UIImage {
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

    private nonisolated func validate(payload: String, type: CDKCodeType) throws {
        guard !payload.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CDKBarcodeError.empty
        }
        if type == .code128, !payload.unicodeScalars.allSatisfy({ $0.value <= 127 }) {
            throw CDKBarcodeError.unsupportedCharacters
        }
    }

    private nonisolated func makeCIImage(payload: String, type: CDKCodeType) -> CIImage? {
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
