//
//  CDKPreferences.swift
//  Cardeck
//

import Foundation

/// Способ сортировки стопки карт.
public nonisolated enum CDKSortOrder: String, CaseIterable, Sendable {

    /// Порядок, заданный пользователем перетаскиванием.
    case manual
    /// Часто используемые — наверх.
    case frequency
    /// По алфавиту.
    case alphabetical

    /// Название для экрана настроек.
    public var title: String {
        switch self {
        case .manual: "Manual"
        case .frequency: "Most used"
        case .alphabetical: "Alphabetical"
        }
    }
}

/// Пользовательские настройки приложения.
public protocol CDKPreferencesProtocol: AnyObject {
    /// Порядок сортировки стопки.
    var sortOrder: CDKSortOrder { get set }
    /// Тактильная отдача включена.
    var hapticsEnabled: Bool { get set }
    /// Автоподъём яркости на детальном экране включён.
    var autoBrightnessEnabled: Bool { get set }
    /// Голографический материал карты включён; выключение переводит карты на fallback.
    var holographicEnabled: Bool { get set }
    /// Демонстрационный набор карт уже засеян в хранилище.
    var didSeedDemoData: Bool { get set }
}

/// Реализация настроек поверх `UserDefaults`.
///
/// Изменение любого значения рассылает ``CDKPreferences/didChangeNotification``.
public final class CDKPreferences: CDKPreferencesProtocol {

    /// Общий экземпляр настроек приложения.
    public static let shared = CDKPreferences(defaults: .standard)

    /// Уведомление об изменении любой настройки.
    public static let didChangeNotification = Notification.Name("CDKPreferencesDidChange")

    private enum Key {
        static let sortOrder = "cdk.sortOrder"
        static let haptics = "cdk.hapticsEnabled"
        static let autoBrightness = "cdk.autoBrightnessEnabled"
        static let holographic = "cdk.holographicEnabled"
        static let didSeed = "cdk.didSeedDemoData"
    }

    private let defaults: UserDefaults

    /// Создаёт хранилище настроек поверх переданного `UserDefaults`.
    public init(defaults: UserDefaults) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.sortOrder: CDKSortOrder.manual.rawValue,
            Key.haptics: true,
            Key.autoBrightness: true,
            Key.holographic: true,
            Key.didSeed: false
        ])
    }

    public var sortOrder: CDKSortOrder {
        get { CDKSortOrder(rawValue: defaults.string(forKey: Key.sortOrder) ?? "") ?? .manual }
        set { set(newValue.rawValue, Key.sortOrder) }
    }

    public var hapticsEnabled: Bool {
        get { defaults.bool(forKey: Key.haptics) }
        set { set(newValue, Key.haptics) }
    }

    public var autoBrightnessEnabled: Bool {
        get { defaults.bool(forKey: Key.autoBrightness) }
        set { set(newValue, Key.autoBrightness) }
    }

    public var holographicEnabled: Bool {
        get { defaults.bool(forKey: Key.holographic) }
        set { set(newValue, Key.holographic) }
    }

    public var didSeedDemoData: Bool {
        get { defaults.bool(forKey: Key.didSeed) }
        set { set(newValue, Key.didSeed) }
    }

    private func set(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }
}
