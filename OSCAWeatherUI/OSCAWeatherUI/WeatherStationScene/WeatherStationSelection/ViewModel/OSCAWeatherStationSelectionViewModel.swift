//
//  OSCAWeatherStationSelectionViewModel.swift
//  OSCAWeatherUI
//
//  Created by Ömer Kurutay on 07.12.21.
//

import OSCAEssentials
import OSCAWeather
import Foundation
import Combine
import struct MapKit.MKCoordinateRegion
import CoreLocation

public struct OSCAWeatherStationSelectionViewModelActions {
  public var didSelectStation: ((String) -> Void)?
}

public enum OSCAWeatherStationSelectionViewModelError: Error, Equatable {
  case weatherObservedFetch
}

public enum OSCAWeatherStationSelectionViewModelState: Equatable {
  case error(OSCAWeatherStationSelectionViewModelError)
}

public final class OSCAWeatherStationSelectionViewModel {
  
  private let dataModule: OSCAWeather
  private let actions: OSCAWeatherStationSelectionViewModelActions?
  private var bindings = Set<AnyCancellable>()
  
  @Published var currentWeatherObserved: [OSCAWeatherObserved] = []
  
  // MARK: Initializer
  public init(dataModule: OSCAWeather,
              actions: OSCAWeatherStationSelectionViewModelActions) {
    self.dataModule = dataModule
    self.actions = actions
  }
  
  // MARK: - OUTPUT
  
  enum Section { case weatherObserved }
  
  @Published private(set) var state: OSCAWeatherStationSelectionViewModelState = .error(.weatherObservedFetch)
  @Published var selectedWeatherObserved: OSCAWeatherObserved?
  
  /**
   Use this to get access to the __Bundle__ delivered from this module's configuration parameter __externalBundle__.
   - Returns: The __Bundle__ given to this module's configuration parameter __externalBundle__. If __externalBundle__ is __nil__, The module's own __Bundle__ is returned instead.
   */
  var bundle: Bundle = {
    if let bundle = OSCAWeatherUI.configuration.externalBundle {
      return bundle
    }
    else { return OSCAWeatherUI.bundle }
  }()
  
  var allWeatherObserved: [OSCAWeatherObserved] = []
  var userLocation: OSCAGeoPoint? = nil
  
  var selectedWeatherObservedRegion: MKCoordinateRegion? {
    guard let latitude = selectedWeatherObserved?.geopoint?.latitude,
          let longitude = selectedWeatherObserved?.geopoint?.longitude
    else { return nil }
    
    let coordinate = CLLocationCoordinate2D(latitude: latitude,
                                            longitude: longitude)
    return MKCoordinateRegion(center: coordinate,
                              latitudinalMeters: 2000,
                              longitudinalMeters: 2000)
  }
  
  var weatherObservedAnnotations: [OSCAMapAnnotation] {
    var annotations: [OSCAMapAnnotation] = []
    
    currentWeatherObserved.forEach { weatherObserved in
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
  
  var selectedWeatherObservedAnnotation: OSCAMapAnnotation? {
    guard let annotation = weatherObservedAnnotations.first(where: { $0.objectId == selectedWeatherObserved?.objectId }) else {
      return nil }
    return annotation
  }
  
  // MARK: Localized Strings
  
  var screenTitle: String { NSLocalizedString(
    "weaher_selection_screen_title",
    bundle: self.bundle,
    comment: "The screen title") }
  var searchPlaceholder: String { NSLocalizedString(
    "weaher_search_placeholder",
    bundle: self.bundle,
    comment: "Placeholder for searchbar") }
  var alertTitleError: String { NSLocalizedString(
    "weaher_alert_title_error",
    bundle: self.bundle,
    comment: "The alert title for an error") }
  var alertActionConfirm: String { NSLocalizedString(
    "weaher_alert_title_confirm",
    bundle: self.bundle,
    comment: "The alert action title to confirm") }
  
  // MARK: Private
  
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
          self.currentWeatherObserved = self.allWeatherObserved
          
          if let id = self.dataModule.userDefaults.getOSCAWeatherObserved() {
            let weatherObserved = fetchedWeatherObserved.first {
              if let objectId = $0.objectId, objectId == id {
                return true
              }
              return false
            }
            self.selectedWeatherObserved = weatherObserved
          } else {
            if let weatherObserved = self.allWeatherObserved.first {
              self.selectedWeatherObserved = weatherObserved
            }
          }
          
        case .failure:
          self.state = .error(.weatherObservedFetch)
        }
      }
      .store(in: &bindings)
  }
  
  private func getWeatherObserved(for ids: [String]) {
    let query = ["where":"{\"objectId\":{\"$in\":\(ids)}}"]
    self.dataModule.getWeatherObserved(limit: 1000, query: query)
      .sink { completion in
        switch completion {
        case .finished:
          print("finished: \(#function)")
          
        case .failure:
          self.state = .error(.weatherObservedFetch)
        }
      } receiveValue: { results in
        switch results {
        case let .success(weatherObserved):
          self.currentWeatherObserved = self.sort(weatherObserved)
          
        case .failure:
          self.state = .error(.weatherObservedFetch)
        }
      }
      .store(in: &bindings)
  }
  
  private func getWeatherObserved(for searchText: String) {
    self.dataModule.elasticSearch(for: searchText)
      .sink { completion in
        switch completion {
        case .finished:
          print("finished: \(#function)")
          
        case .failure:
          self.state = .error(.weatherObservedFetch)
        }
      } receiveValue: { allWeatherObserved in
        
        var ids: [String] = []
        for weatherObserved in allWeatherObserved {
          if let id = weatherObserved._id {
            ids.append(id)
          }
        }
        
        self.getWeatherObserved(for: ids)
      }
      .store(in: &bindings)
  }
  
  private func updateStation() {
    guard let selectedWeatherObserved = selectedWeatherObserved,
          let objectId = selectedWeatherObserved.objectId
    else { return}
    self.dataModule.userDefaults.setOSCAWeatherObserved(objectId)
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
}

// MARK: - INPUT. View event methods
extension OSCAWeatherStationSelectionViewModel {
  func viewDidLoad() {
    LocationManager.shared.askForPermissionIfNeeded()
    if let userLocation = LocationManager.shared.userLocation {
      self.userLocation = OSCAGeoPoint(userLocation)
    }
    fetchWeatherObserved()
  }
  
  func updateSearchResults(for searchText: String) {
    if !searchText.isEmpty {
      getWeatherObserved(for: searchText)
    }
    else { currentWeatherObserved = allWeatherObserved }
  }
  
  func updateLocation() {
    guard let location = LocationManager.shared.userLocation else { return }
    userLocation = OSCAGeoPoint(location)
    currentWeatherObserved = sort(currentWeatherObserved)
  }
  
  func didSelectAnnotation(_ annotation: OSCAMapAnnotation) {
    guard let weatherObserved = currentWeatherObserved.first(
      where: { $0.objectId == annotation.objectId })
    else { return }
    selectedWeatherObserved = weatherObserved
    updateStation()
  }
  
  func didSelectItem(at index: Int) {
    guard index >= 0, index < currentWeatherObserved.count else { return }
    selectedWeatherObserved = currentWeatherObserved[index]
    
    guard let objectId = selectedWeatherObserved?.objectId else { return }
    
    if let didSelectAction = self.actions?.didSelectStation {
      didSelectAction(objectId)
    } else {
      updateStation()
    }
  }
}
