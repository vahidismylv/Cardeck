import Foundation

public final class CDKWalletViewModel {

    public var onChange: (() -> Void)?

    public var onUndoAvailable: ((CDKCardSnapshot) -> Void)?

    public var onWriteFailure: (() -> Void)?

    private let store: CDKCardStore
    private let preferences: CDKPreferencesProtocol

    public private(set) var cards: [CDKCardSnapshot] = []

    private var pendingDeletion: CDKCardSnapshot?

    public init(store: CDKCardStore, preferences: CDKPreferencesProtocol) {
        self.store = store
        self.preferences = preferences
    }

    public var isEmpty: Bool { cards.isEmpty }

    public var sortOrder: CDKSortOrder {
        get { preferences.sortOrder }
        set {
            preferences.sortOrder = newValue
            reload()
        }
    }

    public var isReorderingEnabled: Bool { sortOrder == .manual && cards.count > 1 }

    public func reload() {
        let fetched = (try? store.fetchAll(sortedBy: preferences.sortOrder)) ?? []
        cards = fetched.filter { $0.id != pendingDeletion?.id }
        onChange?()
    }

    public func card(at index: Int) -> CDKCardSnapshot? {
        cards.indices.contains(index) ? cards[index] : nil
    }

    public func move(from source: Int, to destination: Int) {
        guard isReorderingEnabled else { return }
        perform { try store.reorder(from: source, to: destination) }
        reload()
    }

    private func perform(_ work: () throws -> Void) {
        do {
            try work()
        } catch {
            onWriteFailure?()
        }
    }

    public func markUsed(id: UUID) {

        try? store.touch(cardID: id)
    }

    public func delete(id: UUID) {
        guard let card = cards.first(where: { $0.id == id }) else { return }
        commitPendingDeletion()
        pendingDeletion = card
        cards.removeAll { $0.id == id }
        onChange?()
        onUndoAvailable?(card)
    }

    public func undoDelete() {
        guard pendingDeletion != nil else { return }

        pendingDeletion = nil
        reload()
    }

    public var hasPendingDeletion: Bool { pendingDeletion != nil }

    public func commitPendingDeletion() {
        guard let card = pendingDeletion else { return }
        pendingDeletion = nil
        perform { try store.delete(id: card.id) }
        reload()
    }
}
