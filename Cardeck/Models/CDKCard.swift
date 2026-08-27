import Foundation
import SwiftData

@Model
public final class CDKCard {

    public var id: UUID

    public var title: String

    public var code: String

    public var codeTypeRaw: String

    public var gradientIndex: Int

    public var categoryRaw: String

    public var note: String?

    public var createdAt: Date

    public var lastUsedAt: Date?

    public var sortIndex: Int

    public init(
        id: UUID = UUID(),
        title: String,
        code: String,
        codeType: CDKCodeType = .code128,
        gradientIndex: Int = 0,
        category: CDKCategory = .other,
        note: String? = nil,
        createdAt: Date = .now,
        lastUsedAt: Date? = nil,
        sortIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.code = code
        self.codeTypeRaw = codeType.rawValue
        self.gradientIndex = gradientIndex
        self.categoryRaw = category.rawValue
        self.note = note
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.sortIndex = sortIndex
    }

    public var codeType: CDKCodeType {
        get { CDKCodeType(rawValue: codeTypeRaw) ?? .code128 }
        set { codeTypeRaw = newValue.rawValue }
    }

    public var category: CDKCategory {
        get { CDKCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    public var snapshot: CDKCardSnapshot {
        CDKCardSnapshot(
            id: id,
            title: title,
            code: code,
            codeType: codeType,
            gradientIndex: gradientIndex,
            category: category,
            note: note,
            createdAt: createdAt,
            lastUsedAt: lastUsedAt,
            sortIndex: sortIndex
        )
    }
}
