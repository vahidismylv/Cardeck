//
//  CDKSettingsViewModel.swift
//  Cardeck
//

import Foundation

/// Вью-модель настроек.
///
/// Держит доступ к настройкам и хранилищу; про UIKit не знает.
public final class CDKSettingsViewModel {

    /// Вызывается после изменения любой настройки.
    public var onChange: (() -> Void)?
    /// Вызывается после сброса данных.
    public var onReset: (() -> Void)?

    private let preferences: CDKPreferencesProtocol
    private let store: CDKCardStore

    /// Создаёт вью-модель настроек.
    public init(preferences: CDKPreferencesProtocol, store: CDKCardStore) {
        self.preferences = preferences
        self.store = store
    }

    /// Порядок сортировки стопки.
    public var sortOrder: CDKSortOrder {
        get { preferences.sortOrder }
        set {
            preferences.sortOrder = newValue
            onChange?()
        }
    }

    /// Тактильная отдача включена.
    public var hapticsEnabled: Bool {
        get { preferences.hapticsEnabled }
        set {
            preferences.hapticsEnabled = newValue
            onChange?()
        }
    }

    /// Авто-яркость на детальном экране включена.
    public var autoBrightnessEnabled: Bool {
        get { preferences.autoBrightnessEnabled }
        set {
            preferences.autoBrightnessEnabled = newValue
            onChange?()
        }
    }

    /// Голографический материал включён.
    ///
    /// Выключение уводит карты на fallback-материал: он дешевле по GPU
    /// и заметно помогает на слабых устройствах.
    public var holographicEnabled: Bool {
        get { preferences.holographicEnabled }
        set {
            preferences.holographicEnabled = newValue
            onChange?()
        }
    }

    /// Версия и билд из `Bundle`.
    public var versionText: String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion")
        return "Version \(version as? String ?? "—") (\(build as? String ?? "—"))"
    }

    /// Удаляет все карты.
    public func resetData() {
        try? store.deleteAll()
        onReset?()
    }
}
