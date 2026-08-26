//
//  CDKWalletViewModel.swift
//  Cardeck
//

import Foundation

/// Вью-модель стопки карт.
///
/// Ничего не знает про UIKit: наружу отдаёт массив снимков и сообщает об изменениях
/// через ``onChange``. Контроллер сам решает, как это показать.
public final class CDKWalletViewModel {

    /// Вызывается на главном потоке после каждого изменения набора карт.
    public var onChange: (() -> Void)?
    /// Вызывается, когда карта удалена и доступна отмена в течение окна ожидания.
    public var onUndoAvailable: ((CDKCardSnapshot) -> Void)?
    /// Вызывается, когда запись в хранилище не удалась.
    ///
    /// Чаще всего это переполненный диск. Молча проглатывать такое нельзя:
    /// пользователь считает, что порядок карт сохранён, а он не сохранён.
    public var onWriteFailure: (() -> Void)?

    private let store: CDKCardStore
    private let preferences: CDKPreferencesProtocol

    /// Текущий набор карт в порядке отображения.
    public private(set) var cards: [CDKCardSnapshot] = []

    /// Карта, ожидающая окончательного удаления, если отмена не сработает.
    private var pendingDeletion: CDKCardSnapshot?

    /// Создаёт вью-модель.
    public init(store: CDKCardStore, preferences: CDKPreferencesProtocol) {
        self.store = store
        self.preferences = preferences
    }

    /// Стопка пуста — контроллер показывает пустое состояние.
    public var isEmpty: Bool { cards.isEmpty }

    /// Текущий порядок сортировки.
    public var sortOrder: CDKSortOrder {
        get { preferences.sortOrder }
        set {
            preferences.sortOrder = newValue
            reload()
        }
    }

    /// Разрешено ли перетаскивание: ручной порядок и больше одной карты.
    public var isReorderingEnabled: Bool { sortOrder == .manual && cards.count > 1 }

    /// Перечитывает карты из хранилища.
    ///
    /// Карта, ожидающая окончательного удаления, из выдачи исключается: она ещё
    /// лежит в хранилище ради отмены, но в стопке её быть не должно — иначе
    /// любой `reload` воскрешал бы только что удалённую карту.
    public func reload() {
        let fetched = (try? store.fetchAll(sortedBy: preferences.sortOrder)) ?? []
        cards = fetched.filter { $0.id != pendingDeletion?.id }
        onChange?()
    }

    /// Карта по позиции в стопке.
    public func card(at index: Int) -> CDKCardSnapshot? {
        cards.indices.contains(index) ? cards[index] : nil
    }

    /// Переставляет карту в стопке.
    ///
    /// Работает только в ручном порядке: в остальных режимах позиция задаётся
    /// правилом сортировки, и перестановка была бы потеряна при следующем чтении.
    public func move(from source: Int, to destination: Int) {
        guard isReorderingEnabled else { return }
        perform { try store.reorder(from: source, to: destination) }
        reload()
    }

    /// Выполняет запись и сообщает наверх, если она не удалась.
    private func perform(_ work: () throws -> Void) {
        do {
            try work()
        } catch {
            onWriteFailure?()
        }
    }

    /// Отмечает карту открытой — влияет на сортировку по частоте.
    public func markUsed(id: UUID) {
        // Отметку об использовании терять не жалко: она влияет только на сортировку.
        try? store.touch(cardID: id)
    }

    // MARK: - Удаление с отменой

    /// Мягко удаляет карту: она исчезает из стопки, но ещё может быть возвращена.
    public func delete(id: UUID) {
        guard let card = cards.first(where: { $0.id == id }) else { return }
        commitPendingDeletion()
        pendingDeletion = card
        cards.removeAll { $0.id == id }
        onChange?()
        onUndoAvailable?(card)
    }

    /// Возвращает карту, удалённую последней.
    public func undoDelete() {
        guard pendingDeletion != nil else { return }
        // Карта не покидала хранилище: мягкое удаление только скрыло её из стопки.
        pendingDeletion = nil
        reload()
    }

    /// Есть ли карта, ожидающая окончательного удаления.
    public var hasPendingDeletion: Bool { pendingDeletion != nil }

    /// Окончательно удаляет карту, если окно отмены истекло.
    public func commitPendingDeletion() {
        guard let card = pendingDeletion else { return }
        pendingDeletion = nil
        perform { try store.delete(id: card.id) }
        reload()
    }
}
