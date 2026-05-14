import Foundation
import CoreLocation
import Combine

// MARK: - Transport Service
final class TransportService {
    
    static let shared = TransportService()
    
    private var timer: Timer?
    private let updateSubject = PassthroughSubject<[Route], Never>()
    private let routePath = BusStop.route43Stops.map(\.coordinate)
    
    private var segmentIndex = 0
    private var segmentProgress = 0.0
    private let progressStep = 0.08
    
    var routeUpdates: AnyPublisher<[Route], Never> {
        updateSubject.eraseToAnyPublisher()
    }
    
    private var routes: [Route] = Route.sampleData
    
    // MARK: - Start/Stop simulation
    func startSimulation() {
        guard timer == nil else { return }
        publishCurrentRoute()
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            self?.moveRoute43AlongStops()
        }
    }
    
    func stopSimulation() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Route 43 Movement
    private func moveRoute43AlongStops() {
        guard routePath.count > 1 else { return }
        
        segmentProgress += progressStep
        
        if segmentProgress >= 1 {
            segmentProgress = 0
            segmentIndex = (segmentIndex + 1) % routePath.count
        }
        
        publishCurrentRoute()
    }
    
    private func publishCurrentRoute() {
        guard routePath.count > 1 else {
            updateSubject.send(routes)
            return
        }
        
        let start = routePath[segmentIndex]
        let end = routePath[(segmentIndex + 1) % routePath.count]
        let coordinate = interpolate(from: start, to: end, progress: segmentProgress)
        let remainingStops = max(1, routePath.count - segmentIndex)
        let eta = max(1, Int(ceil(Double(remainingStops) * 1.4)))
        
        routes = [
            Route(
                id: 4,
                number: "43",
                type: .bus,
                totalStops: routePath.count,
                etaMinutes: eta,
                coordinate: coordinate,
                isFavorite: true
            )
        ]
        
        updateSubject.send(routes)
    }
    
    private func interpolate(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        progress: Double
    ) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: start.latitude + (end.latitude - start.latitude) * progress,
            longitude: start.longitude + (end.longitude - start.longitude) * progress
        )
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
