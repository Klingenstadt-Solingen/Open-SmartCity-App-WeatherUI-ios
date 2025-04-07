//
//  OSCAWeatherStationCollectionReusableView.swift
//  OSCAWeatherUI
//
//  Created by Ömer Kurutay on 16.02.22.
//

import OSCAEssentials
import UIKit
import Combine

public final class OSCAWeatherStationCollectionReusableView: UICollectionReusableView {
  static let reuseIdentifier = String(describing: OSCAWeatherStationCollectionReusableView.self)
  
  @IBOutlet private var stationSelectionButton: UIButton!
  @IBOutlet private var titleContainerStack: UIStackView!
  @IBOutlet private var titleContainer: UIView!
  @IBOutlet private var titleLabel: UILabel!
  @IBOutlet private var changeImageView: UIImageView!
  @IBOutlet private var detailLabel: UILabel!
  @IBOutlet private var dateLabel: UILabel!
  @IBOutlet private var temperatureView: UIView!
  @IBOutlet private var temperatureLabel: UILabel!
  @IBOutlet private var detailsLabel: UILabel!
  @IBOutlet private var detailsSeperatorView: UIView!
  
  private var viewModel: OSCAWeatherStationCollectionReusableViewModel!
  private var mainViewModel: OSCAWeatherStationViewModel!
  private var bindings = Set<AnyCancellable>()
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    
    layer.cornerRadius = OSCAWeatherUI.configuration.cornerRadius
    layer.masksToBounds = true
    
    stationSelectionButton.setTitle("", for: .normal)
    stationSelectionButton.backgroundColor = OSCAWeatherUI.configuration.colorConfig.grayColor.withAlphaComponent(0.075)
    stationSelectionButton.layer.cornerRadius = OSCAWeatherUI.configuration.cornerRadius
    stationSelectionButton.layer.borderWidth = 1
    stationSelectionButton.layer.borderColor = OSCAWeatherUI.configuration.colorConfig.grayColor.withAlphaComponent(0.125).cgColor
    
    titleContainerStack.axis = .vertical
    titleContainerStack.alignment = .fill
    titleContainerStack.distribution = .fill
    titleContainerStack.spacing = 0
    
    titleContainer.backgroundColor = .clear
    
    titleLabel.font = OSCAWeatherUI.configuration.fontConfig.displayLight
    titleLabel.textColor = self.foregroundColor
    titleLabel.baselineAdjustment = .alignCenters
    titleLabel.adjustsFontSizeToFitWidth = true
    
    var imageName = ""
    if #available(iOS 14.0, *) {
      imageName = "arrow.triangle.2.circlepath"
    } else {
      imageName = "arrow.2.circlepath"
    }
    let image = UIImage(systemName: imageName)
    image?.withRenderingMode(.alwaysTemplate)
    changeImageView.image = image
    changeImageView.tintColor = self.foregroundColor
    
    detailLabel.font = OSCAWeatherUI.configuration.fontConfig.bodyLight
    detailLabel.textColor = self.foregroundColor.withAlphaComponent(0.5)
    detailLabel.textAlignment = .center
    
    dateLabel.font = OSCAWeatherUI.configuration.fontConfig.captionLight
    dateLabel.textColor = self.foregroundColor
    
    temperatureView.backgroundColor = .clear
    
    temperatureLabel.font = .systemFont(ofSize: 80, weight: .thin)
    temperatureLabel.textColor = self.foregroundColor
    
    detailsLabel.font = OSCAWeatherUI.configuration.fontConfig.bodyLight
    detailsLabel.textColor = self.foregroundColor
    
    detailsSeperatorView.backgroundColor = self.foregroundColor.withAlphaComponent(0.4)
  }
  
  func fill(with viewModel: OSCAWeatherStationCollectionReusableViewModel, mainViewModel: OSCAWeatherStationViewModel) {
    self.viewModel = viewModel
    self.mainViewModel = mainViewModel
    self.setupBindings()
    
    self.stationSelectionButton.isEnabled = self.viewModel.weatherObservedCount > 1
      ? true : false
    self.changeImageView.isHidden = self.viewModel.weatherObservedCount > 1
      ? false : true
    
    titleLabel.text = viewModel.title
    detailLabel.isHidden = viewModel.detailedTitle == nil ? true : false
    detailLabel.text = viewModel.detailedTitle
    dateLabel.text = viewModel.date
    temperatureLabel.text = viewModel.temperature
    detailsLabel.text = viewModel.details
  }
  
  private func setupBindings() {
    self.viewModel.$weatherObservedCount
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] weatherObservedCount in
        self?.stationSelectionButton.isEnabled = weatherObservedCount > 1
          ? true : false
        self?.changeImageView.isHidden = weatherObservedCount > 1
        ? false : true
      })
      .store(in: &self.bindings)
  }
  
  private var foregroundColor: UIColor {
    let topColor = OSCAWeatherUI.configuration.backgroundColors.first ?? OSCAWeatherUI.configuration.colorConfig.primaryColor
    
    return topColor.isDarkColor
      ? OSCAWeatherUI.configuration.colorConfig.whiteDark
      : OSCAWeatherUI.configuration.colorConfig.blackColor
  }
  
  @IBAction func stationSelectionButtonTouch(_ sender: UIButton) {
    mainViewModel.stationSelectionButtonTouch()
  }
}
