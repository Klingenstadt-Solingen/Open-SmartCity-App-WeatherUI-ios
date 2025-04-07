//
//  OSCAWeatherStationViewModel.swift
//  OSCAWeatherUI
//
//  Created by Ömer Kurutay on 06.12.21.
//  Reviewed by Stephan Breidenbach on 21.06.22
//

import OSCAWeather
import Foundation
import Combine

public struct OSCAWeatherStationViewModelActions {
  let showWeatherStationSelection: () -> Void
}

public enum OSCAWeatherStationViewModelError: Error, Equatable {
  case weatherObservedFetch
}

public enum OSCAWeatherStationViewModelState: Equatable {
  case loading
  case finishedLoading
  case error(OSCAWeatherStationViewModelError)
}

public final class OSCAWeatherStationViewModel {
  
  let dataModule: OSCAWeather
  private let actions: OSCAWeatherStationViewModelActions?
  private var bindings = Set<AnyCancellable>()
  private var selectedItemId: String?
  
  // MARK: Initializer
  public init(dataModule: OSCAWeather,
              actions: OSCAWeatherStationViewModelActions) {
    self.dataModule = dataModule
    self.actions = actions
  }// end public init
  
  // MARK: - OUTPUT
  
  @Published var state: OSCAWeatherStationViewModelState = .error(.weatherObservedFetch)
  @Published var weatherObservedCells: [WeatherCell]?
  
  var numberOfItemsInSection: Int { weatherObservedCells?.count ?? 0 }
  var numberOfSections: Int { 1 }
  
  var currentWeatherObserved: OSCAWeatherObserved? = nil
  
  // MARK: Localized Strings
}

// MARK: - Private
extension OSCAWeatherStationViewModel {
  
  @objc private func updateUserWeatherStation() {
    guard let id = dataModule.userDefaults.getOSCAWeatherObserved() else { return }
    getWeatherObserved(for: id)
  }
  
  private func getWeatherObserved(for id: String) {
    self.state = .loading
    let query = ["where":"{\"objectId\":\"\(id)\"}"]
    self.dataModule
      .getWeatherObserved(query: query)
      .sink { completion in
        switch completion {
        case .finished:
          self.state = .finishedLoading
          
        case .failure:
          self.state = .error(.weatherObservedFetch)
        }
      } receiveValue: { results in
        switch results {
        case let .success(weatherObserved):
          guard let weatherObserved = weatherObserved.first else {
            self.state = .error(.weatherObservedFetch)
            return
          }
          self.currentWeatherObserved = weatherObserved
          
          self.weatherObservedCells = OSCAWeatherStationCollectionCellViewModel(weatherObserved: weatherObserved).cells
        case .failure:
          self.state = .error(.weatherObservedFetch)
        }
      }
      .store(in: &bindings)
  }
}// end extension final class OSCAWeatherStationViewModel

// MARK: - Input, view event methods
extension OSCAWeatherStationViewModel {
  func viewDidLoad() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(updateUserWeatherStation),
      name: .userWeatherStationDidChange,
      object: nil)
    
    if let selectedItemId = self.selectedItemId,
       !selectedItemId.isEmpty{
      self.getWeatherObserved(for: OSCAWeatherUI.configuration.selectedWeatherObservedId)
    } else {
      self.getWeatherObserved(for: OSCAWeatherUI.configuration.selectedWeatherObservedId)
    }// end if
  }// end viewDidLoad
  
  func stationSelectionButtonTouch() {
    actions?.showWeatherStationSelection()
  }
  
  func refreshData() {
    guard let id = self.currentWeatherObserved?.objectId else { return }
    self.getWeatherObserved(for: id)
  }
}

// MARK: - Deeplinking
extension OSCAWeatherStationViewModel {
  func didReceiveDeeplinkDetail(with objectId: String) -> Void {
    guard !objectId.isEmpty else { return }
    self.selectedItemId = objectId
    getWeatherObserved(for: objectId)
    self.selectedItemId = nil
  }// end func didReceiveDeeplinkDetail
}// end extension final class OSCAWeatherStationViewModel
