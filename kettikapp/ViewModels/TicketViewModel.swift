import Foundation
import Combine

// MARK: - Ticket ViewModel
final class TicketViewModel: ObservableObject {
    
    @Published var ticket: MonthlyTicket
    @Published var showFullscreen = false
    
    init() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: Date())
        components.month = (components.month ?? 1) + 1
        components.day = 1
        let endOfMonth = calendar.date(from: components) ?? Date()
        
        ticket = MonthlyTicket(
            ownerName:      "Бекжан Атабаев",
            validUntil:     endOfMonth,
            ticketNumber:   "BT-2025-03-004892",
            tripsUsed:      47,
            moneySaved:     890,
            hoursInTransit: 14.5,
            routesUsed:     8
        )
    }
    
    var qrCodeString: String {
        "BISHKEK-TRANSIT:\(ticket.ticketNumber):\(ticket.ownerName)"
    }
    
    var statsItems: [(label: String, value: String, icon: String, color: String)] {
        [
            ("Поездок",       "\(ticket.tripsUsed)",                  "ticket.fill",       "#4ECDC4"),
            ("Сэкономлено",   "\(Int(ticket.moneySaved)) с",          "banknote.fill",     "#FFE66D"),
            ("Маршрутов",     "\(ticket.routesUsed)",                 "map.fill",          "#FF6B35"),
            ("Часов в пути",  String(format: "%.1f", ticket.hoursInTransit), "clock.fill", "#A8E6CF"),
        ]
    }
}
