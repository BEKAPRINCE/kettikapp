import SwiftUI
import CoreLocation

// MARK: - Transport Type
enum TransportType: String, CaseIterable, Identifiable {
    case bus      = "bus"
    case trolley  = "trolley"
    case minibus  = "minibus"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .bus:     return "Автобус"
        case .trolley: return "Троллейбус"
        case .minibus: return "Маршрутка"
        }
    }
    
    var icon: String {
        switch self {
        case .bus:     return "bus.fill"
        case .trolley: return "tram.fill"
        case .minibus: return "car.fill"
        }
    }
    
    var emoji: String {
        switch self {
        case .bus:     return "🚌"
        case .trolley: return "🚎"
        case .minibus: return "🚐"
        }
    }
    
    var color: Color {
        switch self {
        case .bus:     return .accentOrange
        case .trolley: return .accentTeal
        case .minibus: return .accentYellow
        }
    }
}

// MARK: - Route Model
struct Route: Identifiable, Hashable {
    let id: Int
    let number: String
    let type: TransportType
    let totalStops: Int
    var etaMinutes: Int
    var coordinate: CLLocationCoordinate2D
    var isFavorite: Bool = false
    
    var etaText: String {
        etaMinutes <= 1 ? "~1 мин" : "\(etaMinutes) мин"
    }
    
    var color: Color { type.color }
    var emoji: String { type.emoji }
    
    static func == (lhs: Route, rhs: Route) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Bus Stop Model
struct BusStop: Identifiable {
    let id: Int
    let name: String
    let coordinate: CLLocationCoordinate2D
    let routes: [String]
}

// MARK: - User Profile Model
struct UserProfile {
    var fullName: String
    var email: String
    var phone: String
    var avatarInitial: String { String(fullName.prefix(1)) }
}

// MARK: - Bank Card Model
struct BankCard: Identifiable {
    let id: UUID
    var last4: String
    var cardType: CardType
    var holderName: String
    var expiry: String
    var cvv: String
    
    enum CardType: String {
        case visa       = "Visa"
        case mastercard = "Mastercard"
        case elcard     = "Elcard"
        
        var icon: String {
            switch self {
            case .visa:       return "creditcard.fill"
            case .mastercard: return "creditcard.circle.fill"
            case .elcard:     return "creditcard.fill"
            }
        }
    }
}

// MARK: - Monthly Ticket Model
struct MonthlyTicket {
    var ownerName: String
    var validUntil: Date
    var ticketNumber: String
    var tripsUsed: Int
    var moneySaved: Double
    var hoursInTransit: Double
    var routesUsed: Int
    
    var isActive: Bool { validUntil > Date() }
    
    var validUntilText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: validUntil)
    }
}

// MARK: - Sample Data
extension Route {
    static let sampleData: [Route] = [
        Route(id: 1, number: "12А",         type: .bus,     totalStops: 18, etaMinutes: 3,  coordinate: CLLocationCoordinate2D(latitude: 40.515, longitude: 72.816)),
        Route(id: 2, number: "5",           type: .trolley, totalStops: 24, etaMinutes: 7,  coordinate: CLLocationCoordinate2D(latitude: 40.519, longitude: 72.821)),
        Route(id: 3, number: "238",         type: .minibus, totalStops: 12, etaMinutes: 2,  coordinate: CLLocationCoordinate2D(latitude: 40.509, longitude: 72.812)),
        Route(id: 5, number: "7Б",          type: .bus,     totalStops: 15, etaMinutes: 5,  coordinate: CLLocationCoordinate2D(latitude: 40.506, longitude: 72.807)),
        Route(id: 6, number: "8",           type: .trolley, totalStops: 22, etaMinutes: 9,  coordinate: CLLocationCoordinate2D(latitude: 40.513, longitude: 72.818)),
        Route(id: 7, number: "280",         type: .minibus, totalStops: 16, etaMinutes: 4,  coordinate: CLLocationCoordinate2D(latitude: 40.522, longitude: 72.826)),
    ]
}
