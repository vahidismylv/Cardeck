import Foundation

public enum CDKMockData {

    public static var cards: [CDKCardSnapshot] {
        let raw: [(String, String, CDKCodeType, Int, CDKCategory)] = [
            ("Carrefour", "4820471193058", .code128, 0, .grocery),
            ("Lidl Plus", "2000009374821", .code128, 5, .grocery),
            ("Costco", "96473829", .pdf417, 1, .grocery),
            ("Walgreens", "7712004583920", .code128, 6, .pharmacy),
            ("Shell Go+", "5003718264519", .code128, 3, .fuel),
            ("BP Rewards", "88114290374651234567", .qr, 7, .fuel),
            ("Sephora", "3002914756830", .qr, 4, .beauty),
            ("Starbucks", "1170036492815", .qr, 2, .coffee),
            ("Costa Coffee", "6600471928374", .code128, 6, .coffee),
            ("Decathlon", "4419028375610", .pdf417, 1, .sport),
            ("Trainline", "9273610048592", .qr, 3, .transport),
            ("Nike Member", "5528301947263", .code128, 5, .sport)
        ]
        let now = Date.now
        return raw.enumerated().map { index, item in
            CDKCardSnapshot(
                id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index))
                    ?? UUID(),
                title: item.0,
                code: item.1,
                codeType: item.2,
                gradientIndex: item.3,
                category: item.4,
                note: nil,
                createdAt: now.addingTimeInterval(TimeInterval(-index) * 86_400),
                lastUsedAt: index % 3 == 0
                    ? now.addingTimeInterval(TimeInterval(-index) * 3_600)
                    : nil,
                sortIndex: index
            )
        }
    }

    public static func stress(count: Int) -> [CDKCardSnapshot] {
        let base = cards
        return (0..<count).map { index in
            let source = base[index % base.count]
            return CDKCardSnapshot(
                id: UUID(),
                title: "\(source.title) \(index / base.count + 1)",
                code: source.code,
                codeType: source.codeType,
                gradientIndex: (source.gradientIndex + index) % CDKGradientPalette.count,
                category: source.category,
                note: nil,
                createdAt: source.createdAt,
                lastUsedAt: source.lastUsedAt,
                sortIndex: index
            )
        }
    }
}
