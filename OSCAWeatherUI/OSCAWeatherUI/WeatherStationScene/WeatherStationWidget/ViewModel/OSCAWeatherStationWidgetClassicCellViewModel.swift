//
//  OSCAWeatherStationWidgetClassicCellViewModel.swift
//  OSCAWeatherUI
//
//  Created by Mammut Nithammer on 24.06.22.
//

import OSCAEssentials
import OSCAWeather
import Foundation

public final class OSCAWeatherStationWidgetClassicCellViewModel {
  let station: OSCAWeatherObserved
  
  var temperatureString: String {
    guard let value = self.station.valueArray?.weatherValues
      .first(where: { $0.type == .temperature })?.value,
          let unit = self.station.valueArray?.weatherValues
      .first(where: { $0.type == .temperature })?.unit
    else { return "n/a" }
    return "\(NSNumber(value: value).toString(digits: 1))\(unit)"
  }
  
  var rainString: String {
    guard let value = self.station.valueArray?.weatherValues
      .first(where: { $0.type == .precipitation })?.value,
          let unit = self.station.valueArray?.weatherValues
      .first(where: { $0.type == .precipitation })?.unit
    else { return "n/a" }
    return "\(NSNumber(value: value).toString(digits: 1)) \(unit)"
  }
  
  var stationName: String { self.station.shortName ?? "n/a" }
  
  var isRaining: Bool {
    guard let value = self.station.valueArray?.weatherValues
      .first(where: { $0.type == .precipitation })?.value
    else { return false }
    return value > 0.3
  }
  
  public init(weatherStation: OSCAWeatherObserved) {
    self.station = weatherStation
  }
}
