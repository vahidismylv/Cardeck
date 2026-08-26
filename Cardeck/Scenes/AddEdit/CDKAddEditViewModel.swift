//
//  CDKAddEditViewModel.swift
//  Cardeck
//

import Foundation

/// Вью-модель формы добавления и редактирования карты.
///
/// Держит черновик карты и правила валидации. Про UIKit не знает: наружу отдаёт
/// готовый ``CDKCardSnapshot`` для превью и тексты ошибок.
public final class CDKAddEditViewModel {

    /// Режим работы формы.
    public enum Mode {
        /// Новая карта.
        case create
        /// Редактирование существующей.
        case edit(CDKCardSnapshot)
    }

    /// Предельные длины полей.
    public enum Limit {
        public static let title = 30
        public static let note = 140
        public static let code = 64
    }

    /// Вызывается после каждого изменения черновика.
    public var onChange: (() -> Void)?

    private let mode: Mode
    private let store: CDKCardStore
    private let original: CDKCardSnapshot

    // Свойства вычисляемые поверх приватного хранилища, и запись в них никогда
    // не идёт через `inout`. Иначе эксклюзивный доступ остаётся открытым на всё
    // время вызова, а `onChange` внутри читает то же самое хранилище — Swift
    // ловит это как одновременный доступ и роняет приложение на первом же символе.

    private var titleStorage = ""
    private var codeStorage = ""
    private var noteStorage = ""
    private var codeTypeStorage: CDKCodeType = .code128
    private var categoryStorage: CDKCategory = .other
    private var gradientIndexStorage = 0

    /// Название карты; длина ограничена ``Limit/title``.
    public var title: String {
        get { titleStorage }
        set {
            let value = String(newValue.prefix(Limit.title))
            guard value != titleStorage else { return }
            titleStorage = value
            onChange?()
        }
    }

    /// Номер карты; длина ограничена ``Limit/code``.
    public var code: String {
        get { codeStorage }
        set {
            let value = String(newValue.prefix(Limit.code))
            guard value != codeStorage else { return }
            codeStorage = value
            onChange?()
        }
    }

    /// Заметка; длина ограничена ``Limit/note``.
    public var note: String {
        get { noteStorage }
        set {
            let value = String(newValue.prefix(Limit.note))
            guard value != noteStorage else { return }
            noteStorage = value
            onChange?()
        }
    }

    /// Тип кода.
    public var codeType: CDKCodeType {
        get { codeTypeStorage }
        set {
            guard newValue != codeTypeStorage else { return }
            codeTypeStorage = newValue
            onChange?()
        }
    }

    /// Категория.
    public var category: CDKCategory {
        get { categoryStorage }
        set {
            guard newValue != categoryStorage else { return }
            categoryStorage = newValue
            onChange?()
        }
    }

    /// Индекс градиента в палитре.
    public var gradientIndex: Int {
        get { gradientIndexStorage }
        set {
            guard newValue != gradientIndexStorage else { return }
            gradientIndexStorage = newValue
            onChange?()
        }
    }

    /// Создаёт вью-модель формы.
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

    // MARK: - Представление

    /// Заголовок экрана.
    public var screenTitle: String {
        if case .edit = mode { return "Edit card" }
        return "New card"
    }

    /// Подпись кнопки сохранения.
    public var saveTitle: String {
        if case .edit = mode { return "Save" }
        return "Add card"
    }

    /// Черновик карты для живого превью.
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

    // MARK: - Валидация

    /// Ошибка поля названия, если она есть.
    public var titleError: String? {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Name is required"
            : nil
    }

    /// Ошибка поля номера, если она есть.
    ///
    /// Несовместимые с Code 128 символы показываются сразу при вводе,
    /// а не всплывают при сохранении.
    public var codeError: String? {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Number is required" }
        if codeType == .code128, !trimmed.unicodeScalars.allSatisfy({ $0.value <= 127 }) {
            return "Code 128 supports Latin characters only"
        }
        return nil
    }

    /// Можно ли сохранять.
    public var isValid: Bool { titleError == nil && codeError == nil }

    /// Сохраняет карту и возвращает её снимок.
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
