//
//  CDKSwiftDataCardStore.swift
//  Cardeck
//

import Foundation
import SwiftData

/// Постоянное хранилище карт на SwiftData.
///
/// Чтение идёт через главный контекст контейнера, запись — через отдельный:
/// так изменения не смешиваются с тем, что сейчас показано на экране,
/// а `reorder` целиком укладывается в одну транзакцию.
public final class CDKSwiftDataCardStore: CDKCardStore {

    private let container: ModelContainer
    private let writeContext: ModelContext

    /// Данные не переживут перезапуск: диск оказался недоступен.
    public let isEphemeral: Bool

    /// Создаёт хранилище поверх контейнера.
    public init(result: CDKModelContainerFactory.Result) {
        self.container = result.container
        self.isEphemeral = result.isEphemeral
        self.writeContext = ModelContext(result.container)
        self.writeContext.autosaveEnabled = false
    }

    private var readContext: ModelContext { container.mainContext }

    // MARK: - Чтение

    public func fetchAll(sortedBy order: CDKSortOrder) throws -> [CDKCardSnapshot] {
        let descriptor = FetchDescriptor<CDKCard>(
            sortBy: [SortDescriptor(\.sortIndex, order: .forward)]
        )
        let cards = try readContext.fetch(descriptor).map(\.snapshot)
        return CDKCardSorting.apply(order, to: cards)
    }

    /// Количество карт в хранилище — нужно, чтобы решить, засеивать ли демо-набор.
    public func count() throws -> Int {
        try readContext.fetchCount(FetchDescriptor<CDKCard>())
    }

    // MARK: - Запись

    public func add(_ card: CDKCardSnapshot) throws {
        let next = try nextSortIndex()
        writeContext.insert(makeModel(from: card.replacing(sortIndex: next)))
        try commit()
    }

    public func update(_ card: CDKCardSnapshot) throws {
        guard let model = try model(for: card.id, in: writeContext) else { return }
        model.title = card.title
        model.code = card.code
        model.codeType = card.codeType
        model.gradientIndex = card.gradientIndex
        model.category = card.category
        model.note = card.note
        try commit()
    }

    public func delete(id: UUID) throws {
        guard let model = try model(for: id, in: writeContext) else { return }
        writeContext.delete(model)
        try commit()
    }

    public func restore(_ card: CDKCardSnapshot) throws {
        guard try model(for: card.id, in: writeContext) == nil else { return }
        // Возвращаем карту с её исходным `sortIndex`, чтобы она встала на своё место.
        writeContext.insert(makeModel(from: card))
        try commit()
    }

    public func reorder(from source: Int, to destination: Int) throws {
        let descriptor = FetchDescriptor<CDKCard>(
            sortBy: [SortDescriptor(\.sortIndex, order: .forward)]
        )
        var models = try writeContext.fetch(descriptor)
        guard models.indices.contains(source),
              destination >= 0, destination < models.count else { return }
        let moved = models.remove(at: source)
        models.insert(moved, at: destination)
        // Индексы пересчитываются пачкой и сохраняются одним коммитом.
        for (index, model) in models.enumerated() where model.sortIndex != index {
            model.sortIndex = index
        }
        try commit()
    }

    public func touch(cardID: UUID) throws {
        guard let model = try model(for: cardID, in: writeContext) else { return }
        model.lastUsedAt = .now
        try commit()
    }

    /// Удаляет все карты — сброс данных из настроек.
    public func deleteAll() throws {
        try writeContext.delete(model: CDKCard.self)
        try commit()
    }

    /// Вставляет набор карт одной транзакцией — засев демо-данных.
    public func insert(_ cards: [CDKCardSnapshot]) throws {
        for card in cards {
            writeContext.insert(makeModel(from: card))
        }
        try commit()
    }

    // MARK: - Приватное

    private func commit() throws {
        guard writeContext.hasChanges else { return }
        do {
            try writeContext.save()
        } catch {
            // Чаще всего это переполненный диск. Откатываем несохранённое,
            // чтобы контекст не остался в противоречивом состоянии.
            writeContext.rollback()
            throw error
        }
    }

    private func nextSortIndex() throws -> Int {
        var descriptor = FetchDescriptor<CDKCard>(
            sortBy: [SortDescriptor(\.sortIndex, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try writeContext.fetch(descriptor).first?.sortIndex ?? -1) + 1
    }

    private func model(for id: UUID, in context: ModelContext) throws -> CDKCard? {
        var descriptor = FetchDescriptor<CDKCard>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func makeModel(from card: CDKCardSnapshot) -> CDKCard {
        CDKCard(
            id: card.id,
            title: card.title,
            code: card.code,
            codeType: card.codeType,
            gradientIndex: card.gradientIndex,
            category: card.category,
            note: card.note,
            createdAt: card.createdAt,
            lastUsedAt: card.lastUsedAt,
            sortIndex: card.sortIndex
        )
    }
}
