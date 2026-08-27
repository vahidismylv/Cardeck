import Foundation

public nonisolated enum CDKCategory: String, CaseIterable, Codable, Sendable {

    case grocery
    case pharmacy
    case fuel
    case beauty
    case coffee
    case sport
    case transport
    case other

    public var title: String {
        switch self {
        case .grocery: "Grocery"
        case .pharmacy: "Pharmacy"
        case .fuel: "Fuel"
        case .beauty: "Beauty"
        case .coffee: "Coffee"
        case .sport: "Sport"
        case .transport: "Transit"
        case .other: "Other"
        }
    }

    public var symbolName: String {
        switch self {
        case .grocery: "cart.fill"
        case .pharmacy: "cross.case.fill"
        case .fuel: "fuelpump.fill"
        case .beauty: "sparkles"
        case .coffee: "cup.and.saucer.fill"
        case .sport: "figure.run"
        case .transport: "tram.fill"
        case .other: "creditcard.fill"
        }
    }
}
