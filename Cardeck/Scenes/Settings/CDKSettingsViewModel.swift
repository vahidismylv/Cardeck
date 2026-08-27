import Foundation

public final class CDKSettingsViewModel {

    public var onChange: (() -> Void)?

    public var onReset: (() -> Void)?

    private let preferences: CDKPreferencesProtocol
    private let store: CDKCardStore

    public init(preferences: CDKPreferencesProtocol, store: CDKCardStore) {
        self.preferences = preferences
        self.store = store
    }

    public var sortOrder: CDKSortOrder {
        get { preferences.sortOrder }
        set {
            preferences.sortOrder = newValue
            onChange?()
        }
    }

    public var hapticsEnabled: Bool {
        get { preferences.hapticsEnabled }
        set {
            preferences.hapticsEnabled = newValue
            onChange?()
        }
    }

    public var autoBrightnessEnabled: Bool {
        get { preferences.autoBrightnessEnabled }
        set {
            preferences.autoBrightnessEnabled = newValue
            onChange?()
        }
    }

    public var holographicEnabled: Bool {
        get { preferences.holographicEnabled }
        set {
            preferences.holographicEnabled = newValue
            onChange?()
        }
    }

    public var versionText: String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion")
        return "Version \(version as? String ?? "—") (\(build as? String ?? "—"))"
    }

    public func resetData() {
        try? store.deleteAll()
        onReset?()
    }
}
