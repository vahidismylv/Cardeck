import CoreGraphics
import Foundation

public nonisolated enum CDKCodeState {

    case loading

    case ready

    case failed(CDKBarcodeError)
}

public final class CDKCardDetailViewModel {

    public var onStateChange: ((CDKCodeState) -> Void)?

    private let store: CDKCardStore

    public private(set) var card: CDKCardSnapshot

    public private(set) var state: CDKCodeState = .loading

    public init(card: CDKCardSnapshot, store: CDKCardStore) {
        self.card = card
        self.store = store
    }

    public var title: String { card.title }

    public var subtitle: String { card.category.title }

    public var groupedCode: String {
        stride(from: 0, to: card.code.count, by: 4)
            .map { offset -> String in
                let start = card.code.index(card.code.startIndex, offsetBy: offset)
                let end = card.code.index(start, offsetBy: 4, limitedBy: card.code.endIndex)
                    ?? card.code.endIndex
                return String(card.code[start..<end])
            }
            .joined(separator: " ")
    }

    public var codeAspectRatio: CGFloat { card.codeType.preferredAspectRatio }

    public func markUsed() {
        try? store.touch(cardID: card.id)
    }

    public func setState(_ state: CDKCodeState) {
        self.state = state
        onStateChange?(state)
    }
}
