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

// MARK: - Route Direction
enum RouteDirection: String {
    case outbound
    case inbound
}

// MARK: - Bus Stop Model
struct BusStop: Identifiable {
    let id: Int
    let name: String
    let coordinate: CLLocationCoordinate2D
    let routes: [String]
    var direction: RouteDirection = .outbound
}

// MARK: - User Profile Model
struct UserProfile {
    var fullName: String
    var email: String
    var phone: String
    var avatarInitial: String { String(fullName.prefix(1)) }
}

// MARK: - Bank Card Model
struct BankCard: Identifiable, Codable {
    let id: UUID
    var last4: String
    var cardType: CardType
    var holderName: String
    var expiry: String
    var cvv: String
    
    enum CardType: String, Codable {
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
        Route(id: 4, number: "43",          type: .bus,     totalStops: BusStop.route43Stops.count, etaMinutes: 6,  coordinate: BusStop.route43Stops[0].coordinate),
    ]
}

extension BusStop {
    static let route43OutboundStops: [BusStop] = [
        BusStop(id: 43001, name: "Ак Тилек конечная", coordinate: CLLocationCoordinate2D(latitude: 40.49864, longitude: 72.77452), routes: ["43"], direction: .outbound),
        BusStop(id: 43002, name: "Западный", coordinate: CLLocationCoordinate2D(latitude: 40.51696, longitude: 72.76488), routes: ["43"], direction: .outbound),
        BusStop(id: 43003, name: "Ош Плаза", coordinate: CLLocationCoordinate2D(latitude: 40.51978, longitude: 72.76318), routes: ["43"], direction: .outbound),
        BusStop(id: 43004, name: "Западный круговая", coordinate: CLLocationCoordinate2D(latitude: 40.52229, longitude: 72.76159), routes: ["43"], direction: .outbound),
        BusStop(id: 43005, name: "Гапара Айтиева", coordinate: CLLocationCoordinate2D(latitude: 40.52492, longitude: 72.76655), routes: ["43"], direction: .outbound),
        BusStop(id: 43006, name: "ОшГУ хаб", coordinate: CLLocationCoordinate2D(latitude: 40.52584, longitude: 72.77201), routes: ["43"], direction: .outbound),
        BusStop(id: 43007, name: "Гора Сулайман-Тоо", coordinate: CLLocationCoordinate2D(latitude: 40.52686, longitude: 72.78265), routes: ["43"], direction: .outbound),
        BusStop(id: 43008, name: "Араванская", coordinate: CLLocationCoordinate2D(latitude: 40.52873, longitude: 72.79408), routes: ["43"], direction: .outbound),
        BusStop(id: 43009, name: "Главный корпус ОшГУ", coordinate: CLLocationCoordinate2D(latitude: 40.53084, longitude: 72.79666), routes: ["43"], direction: .outbound),
        BusStop(id: 43010, name: "Театр Бабура", coordinate: CLLocationCoordinate2D(latitude: 40.53459, longitude: 72.79568), routes: ["43"], direction: .outbound),
        BusStop(id: 43011, name: "Рынок Келечек", coordinate: CLLocationCoordinate2D(latitude: 40.53744, longitude: 72.80138), routes: ["43"], direction: .outbound),
        BusStop(id: 43012, name: "ТЦ Ак Кеме", coordinate: CLLocationCoordinate2D(latitude: 40.53941, longitude: 72.80351), routes: ["43"], direction: .outbound),
        BusStop(id: 43013, name: "Зайнабидинова", coordinate: CLLocationCoordinate2D(latitude: 40.54386, longitude: 72.80222), routes: ["43"], direction: .outbound),
        BusStop(id: 43014, name: "Ошский район", coordinate: CLLocationCoordinate2D(latitude: 40.54979, longitude: 72.80152), routes: ["43"], direction: .outbound),
        BusStop(id: 43015, name: "ХБК", coordinate: CLLocationCoordinate2D(latitude: 40.56206, longitude: 72.80402), routes: ["43"], direction: .outbound),
        BusStop(id: 43016, name: "Кинотеатр Семетей", coordinate: CLLocationCoordinate2D(latitude: 40.56551, longitude: 72.80607), routes: ["43"], direction: .outbound),
        BusStop(id: 43017, name: "Конечная 2 Прораба", coordinate: CLLocationCoordinate2D(latitude: 40.56839, longitude: 72.79668), routes: ["43"], direction: .outbound),
    ]

    static let route43InboundStops: [BusStop] = [
        BusStop(id: 43101, name: "Детская областная", coordinate: CLLocationCoordinate2D(latitude: 40.55610, longitude: 72.80274), routes: ["43"], direction: .inbound),
        BusStop(id: 43102, name: "Ошский район", coordinate: CLLocationCoordinate2D(latitude: 40.55028, longitude: 72.80137), routes: ["43"], direction: .inbound),
        BusStop(id: 43103, name: "Зайнабидинова", coordinate: CLLocationCoordinate2D(latitude: 40.54597, longitude: 72.80130), routes: ["43"], direction: .inbound),
        BusStop(id: 43104, name: "Кафе Гульназ", coordinate: CLLocationCoordinate2D(latitude: 40.54200, longitude: 72.80243), routes: ["43"], direction: .inbound),
        BusStop(id: 43105, name: "ТЦ Рамазан", coordinate: CLLocationCoordinate2D(latitude: 40.53891, longitude: 72.80330), routes: ["43"], direction: .inbound),
        BusStop(id: 43106, name: "Дом быта", coordinate: CLLocationCoordinate2D(latitude: 40.52895, longitude: 72.80601), routes: ["43"], direction: .inbound),
        BusStop(id: 43107, name: "Финпол", coordinate: CLLocationCoordinate2D(latitude: 40.52783, longitude: 72.79742), routes: ["43"], direction: .inbound),
        BusStop(id: 43108, name: "Школа ВЛКСМ", coordinate: CLLocationCoordinate2D(latitude: 40.52870, longitude: 72.79277), routes: ["43"], direction: .inbound),
        BusStop(id: 43109, name: "Театр Кыргызстан", coordinate: CLLocationCoordinate2D(latitude: 40.52497, longitude: 72.78076), routes: ["43"], direction: .inbound),
        BusStop(id: 43110, name: "Кадамжай", coordinate: CLLocationCoordinate2D(latitude: 40.52225, longitude: 72.77199), routes: ["43"], direction: .inbound),
        BusStop(id: 43111, name: "Кафе Уч Тал", coordinate: CLLocationCoordinate2D(latitude: 40.52598, longitude: 72.77141), routes: ["43"], direction: .inbound),
        BusStop(id: 43112, name: "Запад", coordinate: CLLocationCoordinate2D(latitude: 40.52256, longitude: 72.76103), routes: ["43"], direction: .inbound),
        BusStop(id: 43113, name: "мкр Анар", coordinate: CLLocationCoordinate2D(latitude: 40.51633, longitude: 72.76496), routes: ["43"], direction: .inbound),
    ]

    static let route43Stops = route43OutboundStops + route43InboundStops
}
