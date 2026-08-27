import Foundation

public final class CDKAddEditViewModel {

    public enum Mode {

        case create

        case edit(CDKCardSnapshot)
    }

    public enum Limit {
        public static let title = 30
        public static let note = 140
        public static let code = 64
    }

    public var onChange: (() -> Void)?

    private let mode: Mode
    private let store: CDKCardStore
    private let original: CDKCardSnapshot

    private var titleStorage = ""
    private var codeStorage = ""
    private var noteStorage = ""
    private var codeTypeStorage: CDKCodeType = .code128
    private var categoryStorage: CDKCategory = .other
    private var gradientIndexStorage = 0

    public var title: String {
        get { titleStorage }
        set {
            let value = String(newValue.prefix(Limit.title))
            guard value != titleStorage else { return }
            titleStorage = value
            onChange?()
        }
    }

    public var code: String {
        get { codeStorage }
        set {
            let value = String(newValue.prefix(Limit.code))
            guard value != codeStorage else { return }
            codeStorage = value
            onChange?()
        }
    }

    public var note: String {
        get { noteStorage }
        set {
            let value = String(newValue.prefix(Limit.note))
            guard value != noteStorage else { return }
            noteStorage = value
            onChange?()
        }
    }

    public var codeType: CDKCodeType {
        get { codeTypeStorage }
        set {
            guard newValue != codeTypeStorage else { return }
            codeTypeStorage = newValue
            onChange?()
        }
    }

    public var category: CDKCategory {
        get { categoryStorage }
        set {
            guard newValue != categoryStorage else { return }
            categoryStorage = newValue
            onChange?()
        }
    }

    public var gradientIndex: Int {
        get { gradientIndexStorage }
        set {
            guard newValue != gradientIndexStorage else { return }
            gradientIndexStorage = newValue
            onChange?()
        }
    }

    public init(mode: Mode, store: CDKCardStore) {
        self.mode = mode
        self.store = store
        switch mode {
        case .create:
            original = CDKCardSnapshot(
                id: UUID(), title: "", code: "", codeType: .code128,
                gradientIndex: Int.random(in: 0..<CDKGradientPalette.count),
                category: .other, note: nil, createdAt: .now, lastUsedAt: nil, sortIndex: 0
            )
        case .edit(let card):
            original = card
        }
        titleStorage = original.title
        codeStorage = original.code
        noteStorage = original.note ?? ""
        codeTypeStorage = original.codeType
        categoryStorage = original.category
        gradientIndexStorage = original.gradientIndex
    }

    public var screenTitle: String {
        if case .edit = mode { return "Edit card" }
        return "New card"
    }

    public var saveTitle: String {
        if case .edit = mode { return "Save" }
        return "Add card"
    }

    public var draft: CDKCardSnapshot {
        original.replacing(
            title: title.isEmpty ? "Card name" : title,
            code: code,
            codeType: codeType,
            gradientIndex: gradientIndex,
            category: category,
            note: note.isEmpty ? .some(nil) : .some(note)
        )
    }

    public var titleError: String? {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Name is required"
            : nil
    }

    public var codeError: String? {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Number is required" }
        if codeType == .code128, !trimmed.unicodeScalars.allSatisfy({ $0.value <= 127 }) {
            return "Code 128 supports Latin characters only"
        }
        return nil
    }

    public var isValid: Bool { titleError == nil && codeError == nil }

    public func save() throws -> CDKCardSnapshot {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let card = original.replacing(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            code: code.trimmingCharacters(in: .whitespacesAndNewlines),
            codeType: codeType,
            gradientIndex: gradientIndex,
            category: category,
            note: trimmedNote.isEmpty ? .some(nil) : .some(trimmedNote)
        )
        if case .edit = mode {
            try store.update(card)
        } else {
            try store.add(card)
        }
        return card
    }
}
