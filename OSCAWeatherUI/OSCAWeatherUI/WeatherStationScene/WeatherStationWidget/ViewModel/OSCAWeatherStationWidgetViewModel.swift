//
//  OSCAWeatherStationWidgetViewModel.swift
//  OSCAWeatherUI
//
//  Created by Ömer Kurutay on 10.05.23.
//

import OSCAEssentials
import OSCAWeather
import Foundation
import Combine
import CoreLocation

public final class OSCAWeatherStationWidgetViewModel {
  
  let dataModule  : OSCAWeather
  let moduleConfig: OSCAWeatherUIConfig
  let fontConfig  : OSCAFontConfig
  let colorConfig : OSCAColorConfig
  
  private let actions: Actions
  private var bindings = Set<AnyCancellable>()
  
  // MARK: Initializer
  public init(dependencies: Dependencies) {
    self.actions      = dependencies.actions
    self.dataModule   = dependencies.dataModule
    self.moduleConfig = dependencies.moduleConfig
    self.fontConfig   = dependencies.moduleConfig.fontConfig
    self.colorConfig  = dependencies.moduleConfig.colorConfig
  }
  
  // MARK: - OUTPUT
  
  @Published private(set) var state: State = .loading
  @Published private(set) var weatherStations: [OSCAWeatherObserved] = []
  
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
  
  var cellMode: CellMode {
    if self.moduleConfig.stationWidget.allowExtendedLayout {
      return self.weatherStations.count > 1 ? .classic : .extended
      
    } else {
      return .classic
    }
  }
  
  // MARK: - Private
  
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
        self.weatherStations = weatherStations
      }
      
    }
    else { self.weatherStations = stations }
  }
  
  @objc private func updateUserWeatherStation() {
    self.updateWeatherStationCells(self.weatherStations)
  }
}

// MARK: - Configurarions
extension OSCAWeatherStationWidgetViewModel {
  enum CellMode {
    case classic
    case extended
  }
}

// MARK: - Dependencies
extension OSCAWeatherStationWidgetViewModel {
  public struct Dependencies {
    var actions     : Actions
    var dataModule  : OSCAWeather
    var moduleConfig: OSCAWeatherUIConfig
  }
}

// MARK: - Actions
extension OSCAWeatherStationWidgetViewModel {
  public struct Actions {}
}

// MARK: - Error
extension OSCAWeatherStationWidgetViewModel {
  public enum Error: Swift.Error, Equatable {
    case weatherStationFetch
  }
}

// MARK: - Sections
extension OSCAWeatherStationWidgetViewModel {
  public enum Section { case weatherStations }
}

// MARK: - States
extension OSCAWeatherStationWidgetViewModel {
  public enum State: Equatable {
    case loading
    case finishedLoading
    case error(Error)
  }
}

// MARK: - Data Access
extension OSCAWeatherStationWidgetViewModel {
  private func fetchWeatherStations() {
    self.state = .loading
    
    var lat = Environment.defaultGeoPoint.latitude
    var lon = Environment.defaultGeoPoint.longitude
    
    if let location = CLLocationManager().location {
      lat = location.coordinate.latitude
      lon = location.coordinate.longitude
    }
    
    let limit = self.moduleConfig.stationWidget.maxItems
    let query = ["where": "{\"geopoint\": {\"$nearSphere\": {\"__type\": \"GeoPoint\",\"latitude\": \(lat),\"longitude\": \(lon)}}, \"maintenance\": false }"]
    
    self.dataModule.getWeatherObserved(limit: limit, query: query)
      .sink { completion in
        switch completion {
        case .finished:
          self.state = .finishedLoading
          
        case let .failure(error):
#if DEBUG
          print("\(String(describing: self)): \(#function) with Error: \(error)")
#endif
          self.state = .error(.weatherStationFetch)
        }
        
      } receiveValue: { result in
        switch result {
        case let .success(fetchedStations):
          self.updateWeatherStationCells(fetchedStations)
          
        case .failure:
          self.state = .error(.weatherStationFetch)
        }
      }
      .store(in: &self.bindings)
  }
}

// MARK: - INPUT
extension OSCAWeatherStationWidgetViewModel {
  func viewDidLoad() {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.updateUserWeatherStation),
      name: .userWeatherStationDidChange,
      object: nil)
    
    self.fetchWeatherStations()
  }
  
  func refreshContent() {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    self.fetchWeatherStations()
  }
}

// MARK: - Localized Strings
extension OSCAWeatherStationWidgetViewModel {
  var widgetTitle: String { NSLocalizedString(
    "weaher_station_widget_title",
    bundle: self.bundle,
    comment: "The widget title") }
  var alertTitleError: String { NSLocalizedString(
    "weaher_alert_title_error",
    bundle: self.bundle,
    comment: "The alert title for an error") }
  var alertActionConfirm: String { NSLocalizedString(
    "weaher_alert_title_confirm",
    bundle: self.bundle,
    comment: "The alert action title to confirm") }
}
