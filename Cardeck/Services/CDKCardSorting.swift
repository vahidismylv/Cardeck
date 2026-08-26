//
//  CDKCardSorting.swift
//  Cardeck
//

import Foundation

/// Чистые функции сортировки и переупорядочивания стопки.
///
/// Вынесены отдельно от хранилища, чтобы покрыть тестами без контекста SwiftData.
public nonisolated enum CDKCardSorting {

    /// Применяет порядок сортировки к набору карт.
    ///
    /// - Ручной порядок — по `sortIndex`.
    /// - По частоте — сначала недавно использованные, затем ни разу не открытые.
    /// - По алфавиту — регистронезависимо, с локальным сравнением.
    public static func apply(
        _ order: CDKSortOrder,
        to cards: [CDKCardSnapshot]
    ) -> [CDKCardSnapshot] {
        switch order {
        case .manual:
            return cards.sorted { $0.sortIndex < $1.sortIndex }
        case .frequency:
            return cards.sorted { lhs, rhs in
                switch (lhs.lastUsedAt, rhs.lastUsedAt) {
                case let (left?, right?):
                    return left == right ? lhs.sortIndex < rhs.sortIndex : left > right
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return lhs.sortIndex < rhs.sortIndex
                }
            }
        case .alphabetical:
            return cards.sorted { lhs, rhs in
                let result = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
                return result == .orderedSame
                    ? lhs.sortIndex < rhs.sortIndex
                    : result == .orderedAscending
            }
        }
    }

    /// Переставляет карту и пересчитывает `sortIndex` подряд, начиная с нуля.
    ///
    /// Индексы вне диапазона игнорируются: массив возвращается без изменений.
    public static func reorder(
        _ cards: [CDKCardSnapshot],
        from source: Int,
        to destination: Int
    ) -> [CDKCardSnapshot] {
        guard cards.indices.contains(source),
              destination >= 0, destination < cards.count,
              source != destination else {
            return reindexed(cards)
        }
        var result = cards
        let moved = result.remove(at: source)
        result.insert(moved, at: destination)
        return reindexed(result)
    }

    /// Проставляет `sortIndex` по текущему порядку массива.
    public static func reindexed(_ cards: [CDKCardSnapshot]) -> [CDKCardSnapshot] {
        cards.enumerated().map { $0.element.replacing(sortIndex: $0.offset) }
    }
}

public extension CDKCardSnapshot {

    /// Возвращает копию снимка с изменёнными полями.
    func replacing(
        title: String? = nil,
        code: String? = nil,
        codeType: CDKCodeType? = nil,
        gradientIndex: Int? = nil,
        category: CDKCategory? = nil,
        note: String?? = nil,
        lastUsedAt: Date? = nil,
        sortIndex: Int? = nil
    ) -> CDKCardSnapshot {
        CDKCardSnapshot(
            id: id,
            title: title ?? self.title,
            code: code ?? self.code,
            codeType: codeType ?? self.codeType,
            gradientIndex: gradientIndex ?? self.gradientIndex,
            category: category ?? self.category,
            note: note ?? self.note,
            createdAt: createdAt,
            lastUsedAt: lastUsedAt ?? self.lastUsedAt,
            sortIndex: sortIndex ?? self.sortIndex
        )
    }
}
