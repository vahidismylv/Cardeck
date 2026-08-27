import Foundation

public nonisolated enum CDKUserActivity {

    public static let openCardType = "com.Cardeck.openCard"

    private static let cardIDKey = "cardID"

    public static func openCard(_ id: UUID) -> NSUserActivity {
        let activity = NSUserActivity(activityType: openCardType)
        activity.title = "Open card"
        activity.addUserInfoEntries(from: [cardIDKey: id.uuidString])
        return activity
    }

    public static func cardID(from activity: NSUserActivity?) -> UUID? {
        guard let activity, activity.activityType == openCardType,
              let raw = activity.userInfo?[cardIDKey] as? String else { return nil }
        return UUID(uuidString: raw)
    }
}
