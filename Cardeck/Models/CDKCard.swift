//
//  CDKCard.swift
//  Cardeck
//

import Foundation
import SwiftData

/// Карта лояльности — персистентная модель SwiftData.
///
/// Модель принадлежит слою хранения. Экраны и вью-модели работают со снимком
/// ``CDKCardSnapshot``: значение проще диффить и безопасно передавать между потоками.
@Model
public final class CDKCard {

    /// Стабильный идентификатор карты, не меняется при редактировании.
    public var id: UUID
    /// Название карты, до 30 символов.
    public var title: String
    /// Номер карты — полезная нагрузка штрихкода.
    public var code: String
    /// Тип кода, хранится строкой ради стабильности схемы.
    public var codeTypeRaw: String
    /// Индекс градиентного пресета в ``CDKGradientPalette``.
    public var gradientIndex: Int
    /// Категория, хранится строкой ради стабильности схемы.
    public var categoryRaw: String
    /// Необязательная заметка, до 140 символов.
    public var note: String?
    /// Дата создания.
    public var createdAt: Date
    /// Дата последнего открытия карты; `nil`, если карту ещё не открывали.
    public var lastUsedAt: Date?
    /// Позиция в стопке при ручной сортировке.
    public var sortIndex: Int

    /// Создаёт карту. Все параметры кроме обязательных имеют разумные значения.
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

    /// Тип кода карты; при неизвестном сыром значении откатывается к Code 128.
    public var codeType: CDKCodeType {
        get { CDKCodeType(rawValue: codeTypeRaw) ?? .code128 }
        set { codeTypeRaw = newValue.rawValue }
    }

    /// Категория карты; при неизвестном сыром значении откатывается к «Другое».
    public var category: CDKCategory {
        get { CDKCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// Неизменяемый снимок для слоёв представления.
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
