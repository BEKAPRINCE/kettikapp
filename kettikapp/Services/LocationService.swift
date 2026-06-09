import Foundation
import CoreLocation
import Combine

// MARK: - Location Service
final class LocationService: NSObject, ObservableObject {
    
    static let shared = LocationService()
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let manager = CLLocationManager()
    private var isUpdating = false
    private var driverTrackingEnabled = false
    
    // Default center: Osh city center
    let defaultCenter = CLLocationCoordinate2D(latitude: 40.513998, longitude: 72.816097)
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 15
    }
    
    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdating()
        case .denied, .restricted:
            userLocation = defaultCenter
        @unknown default:
            userLocation = defaultCenter
        }
    }
    
    func requestAlwaysPermission() {
        authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
            startUpdating()
        case .authorizedAlways:
            startUpdating()
        case .denied, .restricted:
            userLocation = defaultCenter
        @unknown default:
            userLocation = defaultCenter
        }
    }

    func startDriverTracking() {
        driverTrackingEnabled = true
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 5
        manager.pausesLocationUpdatesAutomatically = false
        requestAlwaysPermission()
    }

    func startUpdating() {
        guard !isUpdating else { return }
        guard manager.authorizationStatus == .authorizedWhenInUse ||
              manager.authorizationStatus == .authorizedAlways else {
            if driverTrackingEnabled {
                requestAlwaysPermission()
            } else {
                requestPermission()
            }
            return
        }

        isUpdating = true
        manager.startUpdatingLocation()
        manager.requestLocation()
    }
    
    func stopUpdating() {
        isUpdating = false
        driverTrackingEnabled = false
        manager.stopUpdatingLocation()
    }

    private func normalizedCoordinate(from location: CLLocation) -> CLLocationCoordinate2D {
        #if targetEnvironment(simulator)
        if location.coordinate.isLikelySimulatorDefaultLocation {
            return defaultCenter
        }
        #endif

        return location.coordinate
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = normalizedCoordinate(from: location)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            startUpdating()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        userLocation = defaultCenter
    }
}

private extension CLLocationCoordinate2D {
    var isLikelySimulatorDefaultLocation: Bool {
        let sanFrancisco = CLLocation(latitude: 37.785834, longitude: -122.406417)
        let current = CLLocation(latitude: latitude, longitude: longitude)
        return current.distance(from: sanFrancisco) < 20_000
    }
}
