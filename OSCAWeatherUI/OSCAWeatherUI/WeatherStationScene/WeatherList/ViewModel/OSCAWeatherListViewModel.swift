//
//  OSCAWeatherListViewModel.swift
//  OSCAWeatherUI
//

import OSCAEssentials
import OSCAWeather
import Foundation
import Combine
import struct MapKit.MKCoordinateRegion
import CoreLocation

public struct OSCAWeatherListViewModelActions {
    public var didSelectStation: ((String) -> Void)?
}

public enum OSCAWeatherListViewModelError: Error, Equatable {
    case weatherObservedFetch
}

public enum OSCAWeatherListViewModelState: Equatable {
    case loading
    case finishedLoading
    case error(OSCAWeatherListViewModelError)
}

public final class OSCAWeatherListViewModel {
    
    public let dataModule: OSCAWeather
    public let moduleConfig: OSCAWeatherUIConfig
    private let actions: OSCAWeatherListViewModelActions?
    private var bindings = Set<AnyCancellable>()
    
    @Published var allWeatherObserved: [OSCAWeatherObserved] = []
    
    public init(dataModule: OSCAWeather,
                actions: OSCAWeatherListViewModelActions, moduleConfig: OSCAWeatherUIConfig) {
        self.dataModule = dataModule
        self.actions = actions
        self.moduleConfig = moduleConfig
    }
    
    
    @Published private(set) var state: OSCAWeatherListViewModelState = .loading
    
    
    var bundle: Bundle = {
        if let bundle = OSCAWeatherUI.configuration.externalBundle {
            return bundle
        }
        else { return OSCAWeatherUI.bundle }
    }()
    
    
    var userLocation: OSCAGeoPoint? = nil
    
    var weatherObservedAnnotations: [OSCAMapAnnotation] {
        var annotations: [OSCAMapAnnotation] = []
        
        allWeatherObserved.forEach { weatherObserved in
            if let objectId = weatherObserved.objectId,
               let latitude = weatherObserved.geopoint?.latitude,
               let longitude = weatherObserved.geopoint?.longitude
            {
                let annotation = OSCAMapAnnotation()
                annotation.objectId = objectId
                annotation.title = weatherObserved.name
                annotation.coordinate = CLLocationCoordinate2D(
                    latitude: latitude,
                    longitude: longitude)
                annotations.append(annotation)
            }
        }
        
        return annotations
    }
    
    
    var screenTitle: String { NSLocalizedString(
        "weaher_selection_screen_title",
        bundle: self.bundle,
        comment: "The screen title") }
    var alertTitleError: String { NSLocalizedString(
        "weaher_alert_title_error",
        bundle: self.bundle,
        comment: "The alert title for an error") }
    var alertActionConfirm: String { NSLocalizedString(
        "weaher_alert_title_confirm",
        bundle: self.bundle,
        comment: "The alert action title to confirm") }
    
    
    private func fetchWeatherObserved() {
        self.dataModule
            .getWeatherObserved(limit: 1000, query: ["where":"{ \"maintenance\": false }"])
            .sink { completion in
                switch completion {
                case .finished:
                    print("finished: \(#function)")
                    
                case .failure:
                    self.state = .error(.weatherObservedFetch)
                }
                
            } receiveValue: { result in
                switch result {
                case let .success(fetchedWeatherObserved):
                    self.allWeatherObserved = self.sort(fetchedWeatherObserved)
                    
                case .failure:
                    self.state = .error(.weatherObservedFetch)
                }
            }
            .store(in: &bindings)
    }
    
    private func sort(_ weatherObserved: [OSCAWeatherObserved]) -> [OSCAWeatherObserved] {
        return weatherObserved.sorted(by: {
            let geopoint = OSCAGeoPoint($0.geopoint)
            let nextGeopoint = OSCAGeoPoint($1.geopoint)
            
            guard let distance = geopoint?.distanceInMeters(to: userLocation),
                  let nextDistance = nextGeopoint?.distanceInMeters(to: userLocation)
            else { return false }
            return distance < nextDistance
        })
    }
    
    func updateLocation() {
        guard let location = LocationManager.shared.userLocation else { return }
        userLocation = OSCAGeoPoint(location)
        self.allWeatherObserved = sort(self.allWeatherObserved)
    }
    
    func didSelectItem(at index: Int) {
        guard let didSelectStation = self.actions?.didSelectStation else { return }
        didSelectStation(self.allWeatherObserved[index].objectId!)
    }
    
    func didSelectItem(_ objectId: String) {
        guard let didSelectStation = self.actions?.didSelectStation else { return }
        didSelectStation(objectId)
    }
    
    private func updateWeatherStationCells(_ stations: [OSCAWeatherObserved]) {
        var weatherStations = stations
        if let id = self.dataModule.userDefaults.getOSCAWeatherObserved() {
            let index = stations.firstIndex {
                guard let objectId = $0.objectId else { return false }
                return objectId == id
            }
            
            if let index = index {
                let station = weatherStations.remove(at: index)
                weatherStations.insert(station, at: 0)
                self.allWeatherObserved = weatherStations
            }
            
        }
        else { self.allWeatherObserved = stations }
    }
    
    @objc private func updateUserWeatherStation() {
        self.updateWeatherStationCells(self.allWeatherObserved)
    }
    
    
    public struct Dependencies {
        var actions     : Actions
        var dataModule  : OSCAWeather
        var moduleConfig: OSCAWeatherUIConfig
    }
    
    public struct Actions {}
    
    public enum Error: Swift.Error, Equatable {
        case weatherStationFetch
    }
    
    
    public enum Section { case allWeatherObserved }
    
    public enum State: Equatable {
        case loading
        case finishedLoading
        case error(Error)
    }
    
    
    func viewDidLoad() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.updateUserWeatherStation),
            name: .userWeatherStationDidChange,
            object: nil)
        
        LocationManager.shared.askForPermissionIfNeeded()
        if let userLocation = LocationManager.shared.userLocation {
            self.userLocation = OSCAGeoPoint(userLocation)
        }
        fetchWeatherObserved()
    }
    
    func refreshContent() {
        self.fetchWeatherObserved()
    }
    
}
