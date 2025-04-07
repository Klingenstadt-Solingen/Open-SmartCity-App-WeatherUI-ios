//
//  OSCAWeatherListClassicCellView.swift
//  OSCAWeatherUI
//

import OSCAEssentials
import UIKit
import Combine

public final class OSCAWeatherListClassicCellView: UICollectionViewCell {
    public static let identifier = String(describing: OSCAWeatherListClassicCellView.self)
    
    @IBOutlet private var temperatureLabel: UILabel!
    @IBOutlet private var stationNameLabel: UILabel!
    @IBOutlet private var rainLabel: UILabel!
    @IBOutlet private var sunrainImageView: UIImageView!
    
    private var bindings = Set<AnyCancellable>()
    
    public var viewModel: OSCAWeatherListClassicCellViewModel! {
        didSet { self.setupView() }
    }
    
    private func setupView() {
        self.contentView.backgroundColor = OSCAWeatherUI.configuration.colorConfig
            .secondaryBackgroundColor
        self.contentView.layer.cornerRadius = OSCAWeatherUI.configuration.cornerRadius
        self.contentView.layer.masksToBounds = true
        
        self.addShadow(with: OSCAWeatherUI.configuration.shadow)
        
        self.temperatureLabel.text = self.viewModel.temperatureString
        self.rainLabel.text = self.viewModel.rainString
        self.stationNameLabel.text = self.viewModel.stationName
        
        self.temperatureLabel.font = OSCAWeatherUI.configuration.fontConfig.subheaderHeavy
        self.rainLabel.font = OSCAWeatherUI.configuration.fontConfig.smallLight
        self.stationNameLabel.font = OSCAWeatherUI.configuration.fontConfig.smallLight
        
        self.temperatureLabel.textColor = OSCAWeatherUI.configuration.colorConfig.textColor
        self.rainLabel.textColor = OSCAWeatherUI.configuration.colorConfig.textColor
        self.stationNameLabel.textColor = OSCAWeatherUI.configuration.colorConfig.textColor
        
        self.stationNameLabel.numberOfLines = 0
        
        self.sunrainImageView.image = self.viewModel.isRaining
        ? UIImage(systemName: "cloud.rain.fill")
        : UIImage(systemName: "sun.max.fill")
        self.sunrainImageView.tintColor = self.viewModel.isRaining
        ? .systemGray2
        : .systemOrange
        self.sunrainImageView.contentMode = .scaleAspectFill
    }
}
