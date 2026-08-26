//
//  CDKCardStore.swift
//  Cardeck
//

import Foundation

/// Хранилище карт.
///
/// Возвращает и принимает значения ``CDKCardSnapshot``: вью-модели не должны знать
/// ни про SwiftData, ни про UIKit. Реализация на SwiftData появляется в блоке 3,
/// до этого работает ``CDKInMemoryCardStore``.
public protocol CDKCardStore: AnyObject {

    /// Все карты в заданном порядке.
    func fetchAll(sortedBy order: CDKSortOrder) throws -> [CDKCardSnapshot]
    /// Добавляет карту в конец стопки.
    func add(_ card: CDKCardSnapshot) throws
    /// Обновляет существующую карту.
    func update(_ card: CDKCardSnapshot) throws
    /// Удаляет карту по идентификатору.
    func delete(id: UUID) throws
    /// Восстанавливает ранее удалённую карту с её исходным `sortIndex`.
    func restore(_ card: CDKCardSnapshot) throws
    /// Переставляет карту и пересчитывает `sortIndex` одной транзакцией.
    func reorder(from source: Int, to destination: Int) throws
    /// Отмечает карту использованной.
    func touch(cardID: UUID) throws
    /// Удаляет все карты — сброс данных из настроек.
    func deleteAll() throws
}

/// Реализация хранилища в памяти.
///
/// Используется до подключения SwiftData, в юнит-тестах и в стресс-прогонах стопки.
public final class CDKInMemoryCardStore: CDKCardStore {

    private var cards: [CDKCardSnapshot]

    /// Создаёт хранилище с заданным набором карт.
    public init(cards: [CDKCardSnapshot] = CDKMockData.cards) {
        self.cards = cards.sorted { $0.sortIndex < $1.sortIndex }
    }

    public func fetchAll(sortedBy order: CDKSortOrder) throws -> [CDKCardSnapshot] {
        CDKCardSorting.apply(order, to: cards)
    }

    public func add(_ card: CDKCardSnapshot) throws {
        let next = (cards.map(\.sortIndex).max() ?? -1) + 1
        cards.append(card.replacing(sortIndex: next))
    }

    public func update(_ card: CDKCardSnapshot) throws {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        cards[index] = card
    }

    public func delete(id: UUID) throws {
        cards.removeAll { $0.id == id }
    }

    public func restore(_ card: CDKCardSnapshot) throws {
        guard !cards.contains(where: { $0.id == card.id }) else { return }
        let insertion = cards.firstIndex { $0.sortIndex > card.sortIndex } ?? cards.count
        cards.insert(card, at: insertion)
    }

    public func reorder(from source: Int, to destination: Int) throws {
        cards = CDKCardSorting.reorder(cards, from: source, to: destination)
    }

    public func touch(cardID: UUID) throws {
        guard let index = cards.firstIndex(where: { $0.id == cardID }) else { return }
        cards[index] = cards[index].replacing(lastUsedAt: .now)
    }

    public func deleteAll() throws {
        cards.removeAll()
    }
}
