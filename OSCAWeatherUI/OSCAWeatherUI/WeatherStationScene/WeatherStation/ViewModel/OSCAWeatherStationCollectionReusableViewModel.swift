//
//  OSCAWeatherStationCollectionReusableViewModel.swift
//  OSCAWeatherUI
//
//  Created by Ömer Kurutay on 16.02.22.
//

import OSCAEssentials
import OSCAWeather
import Foundation
import Combine

@_implementationOnly
import SwiftDate

public final class OSCAWeatherStationCollectionReusableViewModel {
  
  private let dataModule: OSCAWeather
  private let weatherObserved: OSCAWeatherObserved!
  private var bindings = Set<AnyCancellable>()
  
  // MARK: Initializer
  public init(dataModule: OSCAWeather, weatherObserved: OSCAWeatherObserved) {
    self.dataModule = dataModule
    self.weatherObserved = weatherObserved
    
    setupBindings()
  }
  
  // MARK: - OUTPUT
  
  @Published var weatherObservedCount: Int = 0
  
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
  
  var title: String = ""
  var detailedTitle: String? = nil
  var date: String = ""
  var temperature: String = ""
  
  // MARK: Localized Strings
  
  var details: String { NSLocalizedString(
    "weaher_title_details",
    bundle: self.bundle,
    comment: "The for detailed weather information") }
  var clock: String { NSLocalizedString(
    "weather_clock",
    bundle: self.bundle,
    comment: "The clock label text.") }
  var today: String { NSLocalizedString(
    "weather_today",
    bundle: self.bundle,
    comment: "The day of the date for today.") }
  var yesterday: String { NSLocalizedString(
    "weather_yesterday",
    bundle: self.bundle,
    comment: "The day of the date for yesterday.") }
  
  // MARK: - Private
  
  private func fetchAllWeatherObserved() {
    self.dataModule.getWeatherObserved()
      .sink { completion in
        switch completion {
        case .finished:
          print("\(String(describing: Self.self)): .finished")
          
        case .failure:
          print("\(String(describing: Self.self)): .failure")
        }
      } receiveValue: { results in
        switch results {
        case let .success(weatherObserved):
          self.weatherObservedCount = weatherObserved.count
          
        case .failure:
          print("\(String(describing: Self.self)): .failure")
        }
      }
      .store(in: &self.bindings)
  }
  
  private func setupBindings() {
    self.fetchAllWeatherObserved()
    
    if weatherObserved.city == nil {
      if let shortName = weatherObserved.shortName {
        self.title = shortName
      } else if let name = weatherObserved.name {
        self.title = name
      }
      
      self.detailedTitle = nil
      
    } else if let city = weatherObserved.city {
      self.title = city
      
      if let shortName = weatherObserved.shortName {
        self.detailedTitle = shortName
      } else if let name = weatherObserved.name {
        self.detailedTitle = name
      }
    }
    
    if let date = weatherObserved.dateObserved {
      if date.isToday {
        self.date = "\(self.today), \(date.toString(.custom("HH:mm"))) \(self.clock)"
        
      } else if date.isYesterday {
        self.date = "\(self.yesterday), \(date.toString(.custom("HH:mm"))) \(self.clock)"
        
      } else {
        self.date = "\(date.toString(.custom("dd.MM.yyyy, HH:mm"))) \(self.clock)"
      }
    }
    
    if let values = weatherObserved.valueArray?.weatherValues {
      for item in values {
        if let value = item.value, let unit = item.unit {
          let number = NSNumber(value: value)
          
          switch item.type {
          case .temperature:
            self.temperature = "\(number.toString(digits: 1))\(unit)"
            
          default: continue
          }
        }
      }
    }
  }
}
