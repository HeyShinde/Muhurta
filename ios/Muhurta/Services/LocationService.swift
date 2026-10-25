//
//  LocationService.swift
//  Muhurta
//
//  GPS Location and Geocoding Manager with automatic updates and astronomical fallback.
//

import Foundation
import CoreLocation
import MapKit
import Observation

@Observable
public final class LocationService: NSObject, CLLocationManagerDelegate {
    public static let shared = LocationService()
    
    // Ujjain, India - Ancient Prime Meridian of Hindu Astronomy (Avanti)
    public static let defaultCoordinate = CLLocationCoordinate2D(latitude: 23.1765, longitude: 75.7885)
    public static let defaultCityName = "Ujjain (Cosmic Meridian)"
    
    public var currentCoordinate: CLLocationCoordinate2D = LocationService.defaultCoordinate
    public var cityName: String = LocationService.defaultCityName
    public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    public var isLocating: Bool = false
    public var lastUpdated: Date?
    
    private let locationManager = CLLocationManager()
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    public func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func requestLocation() {
        isLocating = true
        locationManager.requestLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            requestLocation()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.currentCoordinate = location.coordinate
        self.lastUpdated = Date()
        self.isLocating = false
        
        // Modern reverse geocoding via MapKit
        Task { [weak self] in
            guard let self = self else { return }
            do {
                if let request = MKReverseGeocodingRequest(location: location) {
                    let mapItems = try await request.mapItems
                    if let firstItem = mapItems.first {
                        let name = firstItem.name ?? "Current Location"
                        await MainActor.run {
                            self.cityName = name
                        }
                    }
                }
            } catch {
                print("Reverse geocoding error: \(error.localizedDescription)")
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLocating = false
        print("LocationManager failed with error: \(error.localizedDescription)")
    }
}
