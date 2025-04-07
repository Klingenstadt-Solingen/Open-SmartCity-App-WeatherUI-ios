//
//  OSCAWeatherStationWidgetExtendedCellView.swift
//  OSCAWeatherUI
//
//  Created by Mammut Nithammer on 24.06.22.
//

import OSCAEssentials
import UIKit
import Combine

public final class OSCAWeatherStationWidgetExtendedCellView: UICollectionViewCell {
  public static let identifier = String(describing: OSCAWeatherStationWidgetExtendedCellView.self)
  
  @IBOutlet private var temperatureLabel: UILabel!
  @IBOutlet private var stationNameLabel: UILabel!
  @IBOutlet private var windSpeedLabel: UILabel!
  @IBOutlet private var windSpeedImageView: UIImageView!
  @IBOutlet private var airPressureLabel: UILabel!
  @IBOutlet private var airPressureImageView: UIImageView!
  @IBOutlet private var rainLabel: UILabel!
  @IBOutlet private var rainImageView: UIImageView!
  @IBOutlet private var sunrainImageView: UIImageView!
  
  private var bindings = Set<AnyCancellable>()
  
  private let sunColor = UIColor(hex: "#F8AF18") ?? .systemOrange
  
  public var viewModel: OSCAWeatherStationWidgetExtendedCellViewModel! {
    didSet { self.setupView() }
  }
  
  private func setupView() {
    self.contentView.backgroundColor = OSCAWeatherUI.configuration.colorConfig
      .secondaryBackgroundColor
    self.contentView.layer.cornerRadius = OSCAWeatherUI.configuration.cornerRadius
    self.contentView.layer.masksToBounds = true
    
    self.temperatureLabel.text = self.viewModel.temperatureString
    self.windSpeedLabel.text = self.viewModel.windSpeed
    self.airPressureLabel.text = self.viewModel.airPressure
    self.rainLabel.text = self.viewModel.rainString
    self.stationNameLabel.text = self.viewModel.stationName
    
    self.temperatureLabel.font = OSCAWeatherUI.configuration.fontConfig.titleHeavy
      .withSize(28)
    self.windSpeedLabel.font = OSCAWeatherUI.configuration.fontConfig.bodyHeavy
    self.airPressureLabel.font = OSCAWeatherUI.configuration.fontConfig.bodyHeavy
    self.rainLabel.font = OSCAWeatherUI.configuration.fontConfig.bodyHeavy
    self.stationNameLabel.font = OSCAWeatherUI.configuration.fontConfig.bodyHeavy
    
    self.temperatureLabel.textColor = OSCAWeatherUI.configuration.colorConfig.textColor
    self.windSpeedLabel.textColor = OSCAWeatherUI.configuration.colorConfig.grayDark
    self.airPressureLabel.textColor =  OSCAWeatherUI.configuration.colorConfig.grayDark
    self.rainLabel.textColor = OSCAWeatherUI.configuration.colorConfig.grayDark
    self.stationNameLabel.textColor = OSCAWeatherUI.configuration.colorConfig.textColor
    
    self.stationNameLabel.numberOfLines = 2
    
    self.sunrainImageView.image = self.viewModel.isRaining
      ? UIImage(systemName: "cloud.rain.fill")
      : UIImage(systemName: "sun.max.fill")
    self.sunrainImageView.tintColor = self.viewModel.isRaining
      ? .systemGray2
      : self.sunColor
    self.sunrainImageView.contentMode = .scaleAspectFill
    
    self.windSpeedImageView.isHidden = OSCAWeatherUI.configuration.stationWidget
      .isIconHidden
    self.windSpeedImageView.image = UIImage(systemName: "wind")
    self.windSpeedImageView.tintColor = OSCAWeatherUI.configuration
      .colorConfig.grayDark
    self.windSpeedImageView.contentMode = .scaleAspectFill
    
    self.airPressureImageView.isHidden = OSCAWeatherUI.configuration.stationWidget
      .isIconHidden
    let airPressureImage: UIImage?
    if #available(iOS 14.0, *) {
      airPressureImage = UIImage(systemName: "barometer")
    } else {
      airPressureImage = UIImage(
        named: "tachometer-light-svg",
        in: OSCAWeatherUI.bundle,
        with: nil)?
        .withRenderingMode(.alwaysTemplate)
    }
    self.airPressureImageView.image = airPressureImage
    self.airPressureImageView.tintColor = OSCAWeatherUI.configuration
      .colorConfig.grayDark
    self.airPressureImageView.contentMode = .scaleAspectFill
    
    self.rainImageView.isHidden = OSCAWeatherUI.configuration.stationWidget
      .isIconHidden
    self.rainImageView.image = UIImage(systemName: "cloud.rain")
    self.rainImageView.tintColor = OSCAWeatherUI.configuration
      .colorConfig.grayDark
    self.rainImageView.contentMode = .scaleAspectFill
  }
}
