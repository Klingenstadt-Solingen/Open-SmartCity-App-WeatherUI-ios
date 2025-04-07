//
//  OSCAWeatherStationSelectionTableViewCell.swift
//  OSCAWeatherUI
//
//  Created by Ömer Kurutay on 13.04.22.
//

import OSCAWeather
import OSCAEssentials
import UIKit

public final class OSCAWeatherStationSelectionTableViewCell: UITableViewCell {
  static let identifier = String(describing: OSCAWeatherStationSelectionTableViewCell.self)
  
  @IBOutlet private var titleLabel: UILabel!
  @IBOutlet private var subtitleLabel: UILabel!
  
  func fill(with weatherObserved: OSCAWeatherObserved,
            selectedWeatherObserved: OSCAWeatherObserved?,
            userLocation: OSCAGeoPoint?,
            indexPath: IndexPath) {
    self.backgroundColor = OSCAWeatherUI.configuration.colorConfig.secondaryBackgroundColor
    
    titleLabel.text = weatherObserved.name
    titleLabel.font = OSCAWeatherUI.configuration.fontConfig.bodyHeavy
    titleLabel.textColor = OSCAWeatherUI.configuration.colorConfig.textColor
    
    if userLocation != nil,
       let geopoint = OSCAGeoPoint(weatherObserved.geopoint),
       let distance = geopoint.distanceInKilometers(to: userLocation)
    {
      let formattedDistance = NSNumber(value: distance).toString(digits: 1)
      subtitleLabel.text = "\(formattedDistance) km"
    } else {
      subtitleLabel.text = ""
    }
    subtitleLabel.font = OSCAWeatherUI.configuration.fontConfig.smallLight
    subtitleLabel.textColor = OSCAWeatherUI.configuration.colorConfig.textColor
    
    if let selectedWeatherObserved = selectedWeatherObserved {
      if weatherObserved.objectId == selectedWeatherObserved.objectId {
        accessoryType = .checkmark
      } else {
        accessoryType = .none
      }
    } else {
      if indexPath.row == 0 {
        accessoryType = .checkmark
      } else {
        accessoryType = .none
      }
    }
    
    tintColor = OSCAWeatherUI.configuration.colorConfig.primaryColor
  }
}
