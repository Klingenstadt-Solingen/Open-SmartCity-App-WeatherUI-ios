//
//  OSCAWeatherStationCollectionCellViewModel.swift
//  OSCAWeatherUI
//
//  Created by Ömer Kurutay on 17.02.22.
//

import Foundation
import OSCAEssentials
import OSCAWeather

public final class OSCAWeatherStationCollectionCellViewModel {
  private let weatherObserved: OSCAWeatherObserved!

  // MARK: Initializer

  public init(weatherObserved: OSCAWeatherObserved) {
    self.weatherObserved = weatherObserved

    setupBindings()
  }

  // MARK: - OUTPUT

  var cells: [WeatherCell] = []

  // MARK: - Private

  private func setupBindings() {
    guard let values = weatherObserved.valueArray else { return }
    
    let weatherValues = values.weatherValues
    let sunCycleData = values.sunCycleValues
    
    for item in weatherValues {
      switch item.type {
      case .uvIndex:
        cells.append(WeatherCell(item, defaultLocalIcon: "sun.max", type: item.type))

      case .precipitation:
        cells.append(WeatherCell(item, defaultLocalIcon: "cloud.rain", type: item.type))

      case .humidity:
        cells.append(WeatherCell(item, defaultLocalIcon: "humidity", type: item.type))

      case .airPressure:
        cells.append(WeatherCell(item, defaultLocalIcon: "barometer", type: item.type))

      case .windSpeed:
        cells.append(WeatherCell(item, defaultLocalIcon: "wind", type: item.type))

      case .windDirection:
        cells.append(WeatherCell(item, defaultLocalIcon: "location.north-\(item.value ?? 0)", type: item.type))
          
      case .globalRadiation:
          cells.append(WeatherCell(item, defaultLocalIcon: "sun.min", type: item.type))
      case .waterOnSurface:
          cells.append(WeatherCell(item, defaultLocalIcon: "water.waves", type: item.type))
        
      case .waterPlayground:
        cells.append(WeatherCell(item, defaultLocalIcon: "water.waves", type: item.type))
      case .swimmingSignal:
        cells.append(WeatherCell(item, defaultLocalIcon: "person-swimming", type: item.type))
      default: continue
      }
    }
    
    sunCycleData.forEach { sunCycle in
      switch sunCycle.type {
      case .sunrise:
        cells.append(WeatherCell(sunCycle, defaultLocalIcon: "sunrise.fill", type: .sunrise))
      case .sunset:
        cells.append(WeatherCell(sunCycle, defaultLocalIcon: "sunset.fill", type: .sunset))
      default: break
      }
    }
  }
}

struct WeatherCell {
  var defaultLocalIcon: String
  var iconUrl: String?
  var title: String = ""
  var value: String = ""
  var type: OSCAWeatherObserved.ValueTypes? = nil
  
  public var imageName: String { self.defaultLocalIcon }

  init(_ item: OSCAWeatherObserved.Value, defaultLocalIcon: String, type: OSCAWeatherObserved.ValueTypes?) {
    self.defaultLocalIcon = defaultLocalIcon
    iconUrl = item.iconUrl
    title = item.name ?? ""
    self.type = type
   
    if let value = item.value {
      let number = NSNumber(value: value)
      var stringValue: String = ""

      switch item.type {
      case .precipitation, .windSpeed:
        stringValue = number.toString(digits: 1)

      case .windDirection:
        stringValue = windDirectionFromDegrees(degrees: value)

      case .waterPlayground:
        stringValue = number == 1 ? "geöffnet" : "geschlossen"
        
      case .swimmingSignal:
        stringValue = number == 1 ? "Baden erlaubt" : "Baden verboten"
      case .sunrise, .sunset:
        let date = Date(timeIntervalSince1970: value)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        self.title = item.name?.capitalized ?? "n/a"
        stringValue = formatter.string(from: date)
      default:
        stringValue = number.toString(digits: 0)
      }

      self.value = item.unit != nil
        ? "\(stringValue) \(item.unit!)"
        : stringValue
    }
  }
  
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

  private func windDirectionFromDegrees(degrees: Double) -> String {
    var localDirections: [String] = []
    let directions = [
      "weaher_cardinal_direction_n",
      "weaher_cardinal_direction_nne",
      "weaher_cardinal_direction_ne",
      "weaher_cardinal_direction_ene",
      "weaher_cardinal_direction_e",
      "weaher_cardinal_direction_ese",
      "weaher_cardinal_direction_se",
      "weaher_cardinal_direction_sse",
      "weaher_cardinal_direction_s",
      "weaher_cardinal_direction_ssw",
      "weaher_cardinal_direction_sw",
      "weaher_cardinal_direction_wsw",
      "weaher_cardinal_direction_w",
      "weaher_cardinal_direction_wnw",
      "weaher_cardinal_direction_nw",
      "weaher_cardinal_direction_nnw"]
    for direction in directions {
      localDirections.append(NSLocalizedString(
        direction,
        bundle: self.bundle,
        comment: ""))
    }
    let i: Int = Int((degrees + 11.25) / 22.5)
    return localDirections[i % 16]
  }
}

/*
extension WeatherCell {
  init(_ item: OSCAWeatherObserved.Value, imageName: String) {
    self.imageName = imageName
    if let dateTime = item.value {
      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm"
      
      let timeString = formatter.string(from: dateTime)
      self.value = timeString
    }
    
    self.title = item.name?.capitalized ?? ""
  }
}
*/
