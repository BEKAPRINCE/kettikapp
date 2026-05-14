import Foundation
import MapKit
import Combine
import SwiftUI

// MARK: - Map ViewModel
final class MapViewModel: ObservableObject {
    
    @Published var routes: [Route] = Route.sampleData
    @Published var busStops: [BusStop] = BusStop.route43Stops
    @Published var selectedRoute: Route?
    @Published var selectedStop: BusStop?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.513998, longitude: 72.816097),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var favoriteIDs: Set<Int> = [4]
    @Published var showUserLocation = true
    
    private let transportService = TransportService.shared
    private let locationService  = LocationService.shared
    private var cancellables      = Set<AnyCancellable>()
    private var isSimulationRunning = false
    
    init() {
        setupSubscriptions()
        setAutoRefresh(enabled: true)
        locationService.requestPermission()
        locationService.startUpdating()
    }
    
    deinit {
        transportService.stopSimulation()
    }
    
    // MARK: - Setup
    private func setupSubscriptions() {
        transportService.routeUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedRoutes in
                guard let self else { return }
                self.routes = updatedRoutes.map { route in
                    var r = route
                    r.isFavorite = self.favoriteIDs.contains(route.id)
                    return r
                }
            }
            .store(in: &cancellables)
        
        locationService.$userLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coord in
                guard let self, self.showUserLocation else { return }
                self.region.center = coord
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    func selectRoute(_ route: Route?) {
        withAnimation { selectedRoute = route }
    }

    func selectStop(_ stop: BusStop?) {
        withAnimation { selectedStop = stop }
    }
    
    func toggleFavorite(routeID: Int) {
        if favoriteIDs.contains(routeID) {
            favoriteIDs.remove(routeID)
        } else {
            favoriteIDs.insert(routeID)
        }
        // Update routes list
        routes = routes.map { r in
            var updated = r
            updated.isFavorite = favoriteIDs.contains(r.id)
            return updated
        }
    }
    
    func centerOnUser() {
        if let coord = locationService.userLocation {
            region.center = coord
        } else {
            locationService.requestPermission()
            locationService.startUpdating()
        }
    }
    
    func setLocationEnabled(_ enabled: Bool) {
        showUserLocation = enabled
        if enabled {
            locationService.requestPermission()
            locationService.startUpdating()
        } else {
            locationService.stopUpdating()
        }
    }
    
    func setAutoRefresh(enabled: Bool) {
        guard enabled != isSimulationRunning else { return }
        isSimulationRunning = enabled
        if enabled {
            transportService.startSimulation()
        } else {
            transportService.stopSimulation()
        }
    }
    
    var favoriteRoutes: [Route] {
        routes.filter { favoriteIDs.contains($0.id) }
    }
}
