import Foundation

public nonisolated struct CDKCardSnapshot: Identifiable, Hashable, Sendable {

    public let id: UUID
    public let title: String
    public let code: String
    public let codeType: CDKCodeType
    public let gradientIndex: Int
    public let category: CDKCategory
    public let note: String?
    public let createdAt: Date
    public let lastUsedAt: Date?
    public let sortIndex: Int

    public init(
        id: UUID,
        title: String,
        code: String,
        codeType: CDKCodeType,
        gradientIndex: Int,
        category: CDKCategory,
        note: String?,
        createdAt: Date,
        lastUsedAt: Date?,
        sortIndex: Int
    ) {
        self.id = id
        self.title = title
        self.code = code
        self.codeType = codeType
        self.gradientIndex = gradientIndex
        self.category = category
        self.note = note
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.sortIndex = sortIndex
    }

    public var lastFourDigits: String {
        let significant = code.filter { !$0.isWhitespace }
        return String(significant.suffix(4))
    }

    public var maskedCode: String {
        lastFourDigits.isEmpty ? "—" : "•••• \(lastFourDigits)"
    }

    public var gradient: CDKGradientPreset {
        CDKGradientPalette.preset(at: gradientIndex)
    }

    public var accessibilityDescription: String {
        let tail = lastFourDigits.isEmpty
            ? "no number"
            : "number ends in \(lastFourDigits.map(String.init).joined(separator: " "))"
        return "\(title), \(category.title), \(tail)"
    }
}
