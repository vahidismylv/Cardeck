import Foundation

public nonisolated enum CDKSortOrder: String, CaseIterable, Sendable {

    case manual

    case frequency

    case alphabetical

    public var title: String {
        switch self {
        case .manual: "Manual"
        case .frequency: "Most used"
        case .alphabetical: "Alphabetical"
        }
    }
}

public protocol CDKPreferencesProtocol: AnyObject {

    var sortOrder: CDKSortOrder { get set }

    var hapticsEnabled: Bool { get set }

    var autoBrightnessEnabled: Bool { get set }

    var holographicEnabled: Bool { get set }

    var didSeedDemoData: Bool { get set }
}

public final class CDKPreferences: CDKPreferencesProtocol {

    public static let shared = CDKPreferences(defaults: .standard)

    public static let didChangeNotification = Notification.Name("CDKPreferencesDidChange")

    private enum Key {
        static let sortOrder = "cdk.sortOrder"
        static let haptics = "cdk.hapticsEnabled"
        static let autoBrightness = "cdk.autoBrightnessEnabled"
        static let holographic = "cdk.holographicEnabled"
        static let didSeed = "cdk.didSeedDemoData"
    }

    private let defaults: UserDefaults

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
