//
//  CDKCardDetailViewModel.swift
//  Cardeck
//

import CoreGraphics
import Foundation

/// Состояние панели кода.
public nonisolated enum CDKCodeState {
    /// Код ещё строится.
    case loading
    /// Код готов; изображение отдаётся отдельно, чтобы вью-модель не знала про UIKit.
    case ready
    /// Код построить не удалось — экран показывает крупный номер как fallback.
    case failed(CDKBarcodeError)
}

/// Вью-модель детального экрана карты.
///
/// Не знает про UIKit: наружу отдаёт данные карты и состояние кода,
/// само изображение запрашивает контроллер через ``CDKBarcodeServicing``.
public final class CDKCardDetailViewModel {

    /// Вызывается при смене состояния кода.
    public var onStateChange: ((CDKCodeState) -> Void)?

    private let store: CDKCardStore

    /// Показываемая карта.
    public private(set) var card: CDKCardSnapshot
    /// Текущее состояние кода.
    public private(set) var state: CDKCodeState = .loading

    /// Создаёт вью-модель для карты.
    public init(card: CDKCardSnapshot, store: CDKCardStore) {
        self.card = card
        self.store = store
    }

    /// Заголовок экрана.
    public var title: String { card.title }
    /// Подпись под заголовком — категория.
    public var subtitle: String { card.category.title }
    /// Номер карты, разбитый на группы по четыре — так его проще читать глазами.
    public var groupedCode: String {
        stride(from: 0, to: card.code.count, by: 4)
            .map { offset -> String in
                let start = card.code.index(card.code.startIndex, offsetBy: offset)
                let end = card.code.index(start, offsetBy: 4, limitedBy: card.code.endIndex)
                    ?? card.code.endIndex
                return String(card.code[start..<end])
            }
            .joined(separator: " ")
    }

    /// Пропорции кода — панель подстраивает высоту под тип.
    public var codeAspectRatio: CGFloat { card.codeType.preferredAspectRatio }

    /// Отмечает карту использованной.
    public func markUsed() {
        try? store.touch(cardID: card.id)
    }

    /// Фиксирует результат построения кода.
    public func setState(_ state: CDKCodeState) {
        self.state = state
        onStateChange?(state)
    }
}
