import Foundation
import CoreLocation
import Combine

// MARK: - Transport Service
final class TransportService {
    
    static let shared = TransportService()
    
    private var timer: Timer?
    private let updateSubject = PassthroughSubject<[Route], Never>()
    
    var routeUpdates: AnyPublisher<[Route], Never> {
        updateSubject.eraseToAnyPublisher()
    }
    
    private var routes: [Route] = Route.sampleData
    
    // MARK: - Start/Stop simulation
    func startSimulation() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.simulateMovement()
        }
    }
    
    func stopSimulation() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Simulate vehicle movement
    private func simulateMovement() {
        routes = routes.map { route in
            var updated = route
            // Slightly move coordinate
            let latDelta = Double.random(in: -0.0008...0.0008)
            let lngDelta = Double.random(in: -0.0008...0.0008)
            updated.coordinate = CLLocationCoordinate2D(
                latitude:  route.coordinate.latitude  + latDelta,
                longitude: route.coordinate.longitude + lngDelta
            )
            // Update ETA
            let etaDelta = Int.random(in: -1...1)
            updated.etaMinutes = max(1, route.etaMinutes + etaDelta)
            return updated
        }
        updateSubject.send(routes)
    }
    
    // MARK: - Get all routes
    func getAllRoutes() -> [Route] {
        return routes
    }
    
    // MARK: - Search routes
    func search(query: String) -> [Route] {
        guard !query.isEmpty else { return routes }
        let lowered = query.lowercased()
        return routes.filter {
            $0.number.lowercased().contains(lowered) ||
            $0.type.displayName.lowercased().contains(lowered)
        }
    }
}
