//
//  CDKUserActivity.swift
//  Cardeck
//

import Foundation

/// Восстановление состояния сцены между запусками.
///
/// Хранится только идентификатор открытой карты: сами данные лежат в SwiftData,
/// и дублировать их в активность незачем.
public enum CDKUserActivity {

    /// Тип активности; продублирован в `NSUserActivityTypes` в Info.plist.
    public static let openCardType = "com.Cardeck.openCard"

    private static let cardIDKey = "cardID"

    /// Собирает активность для открытой карты.
    public static func openCard(_ id: UUID) -> NSUserActivity {
        let activity = NSUserActivity(activityType: openCardType)
        activity.title = "Open card"
        activity.addUserInfoEntries(from: [cardIDKey: id.uuidString])
        return activity
    }

    /// Достаёт идентификатор карты из активности.
    public static func cardID(from activity: NSUserActivity?) -> UUID? {
        guard let activity, activity.activityType == openCardType,
              let raw = activity.userInfo?[cardIDKey] as? String else { return nil }
        return UUID(uuidString: raw)
    }
}
