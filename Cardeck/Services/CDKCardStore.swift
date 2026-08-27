import Foundation

public protocol CDKCardStore: AnyObject {

    func fetchAll(sortedBy order: CDKSortOrder) throws -> [CDKCardSnapshot]

    func add(_ card: CDKCardSnapshot) throws

    func update(_ card: CDKCardSnapshot) throws

    func delete(id: UUID) throws

    func restore(_ card: CDKCardSnapshot) throws

    func reorder(from source: Int, to destination: Int) throws

    func touch(cardID: UUID) throws

    func deleteAll() throws
}

public final class CDKInMemoryCardStore: CDKCardStore {

    private var cards: [CDKCardSnapshot]

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
