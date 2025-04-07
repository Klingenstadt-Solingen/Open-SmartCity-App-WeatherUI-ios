//
//  OSCAWeatherStationCollectionViewCell.swift
//  OSCAWeatherUI
//
//  Created by Ömer Kurutay on 11.02.22.
//

import OSCAEssentials
import UIKit

public final class OSCAWeatherStationCollectionViewCell: UICollectionViewCell {
  static let reuseIdentifier = String(describing: OSCAWeatherStationCollectionViewCell.self)

  @IBOutlet private var cellView: UIView!
  @IBOutlet private var imageView: UIImageView!
  @IBOutlet private var titleLabel: UILabel!
  @IBOutlet private var valueLabel: UILabel!

  private var weatherCell: WeatherCell!

  override public func awakeFromNib() {
    super.awakeFromNib()

    layer.cornerRadius = OSCAWeatherUI.configuration.cornerRadius
    layer.masksToBounds = true

    cellView.backgroundColor = OSCAWeatherUI.configuration.cardsBackgroundColor.withAlphaComponent(0.25)
    imageView.tintColor = self.foregroundColor

    titleLabel.font = OSCAWeatherUI.configuration.fontConfig.smallLight
    titleLabel.textColor = self.foregroundColor.withAlphaComponent(0.5)

    valueLabel.font = OSCAWeatherUI.configuration.fontConfig.subheaderLight
    valueLabel.textColor = self.foregroundColor
  }

  func fill(with weatherCell: WeatherCell) {
    self.weatherCell = weatherCell
    
    self.imageView.transform = CGAffineTransform(rotationAngle: 0)

    titleLabel?.text = weatherCell.title
    valueLabel?.text = weatherCell.value
    
    if(weatherCell.type == .waterPlayground || weatherCell.type == .swimmingSignal) {
      valueLabel.numberOfLines = 2
      valueLabel.font = valueLabel.font.withSize(12)
      valueLabel.textAlignment = .center
    }
    
    if let iconUrl = weatherCell.iconUrl {
      fetchImage(from: iconUrl, completion: self.onIconReceived)
    } else {
      getLocalIcon()
    }
  }
  
  private func onIconReceived(_ icon: UIImage?) {
    guard let icon = icon else {
      getLocalIcon()
      return
    }
    DispatchQueue.main.async {
      self.imageView.image = icon
    }
  }
  
  private var foregroundColor: UIColor {
    if let tintColor = OSCAWeatherUI.configuration.cardsContentTint {
      return tintColor
      
    } else {
      let bottomColor = OSCAWeatherUI.configuration.backgroundColors.last ?? OSCAWeatherUI.configuration.colorConfig.whiteColor
      
      return bottomColor.isDarkColor
        ? OSCAWeatherUI.configuration.colorConfig.whiteDark
        : OSCAWeatherUI.configuration.colorConfig.blackColor
    }
  }
}

extension OSCAWeatherStationCollectionViewCell {
  func fetchImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
    guard let url = URL(string: urlString) else {
      completion(nil)
      return
    }
    
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
      guard let data = data, error == nil else {
        completion(nil)
        return
      }
      let image = UIImage(data: data)
      completion(image)
    }
    
    task.resume()
  }
  
  func getLocalIcon() {
    switch weatherCell.imageName {
    case "humidity":
      if #available(iOS 15.0, *) {
        imageView.image = UIImage(systemName: weatherCell.imageName)
      } else {
        imageView.image = UIImage(named: "humidity-light-svg",
                                  in: OSCAWeatherUI.bundle,
                                  with: .none)
      }

    case "barometer":
      if #available(iOS 14.0, *) {
        imageView.image = UIImage(systemName: weatherCell.imageName)
      } else {
        imageView.image = UIImage(named: "tachometer-light-svg",
                                  in: OSCAWeatherUI.bundle,
                                  with: .none)
      }

    case let str where str.contains("location.north-"):
      imageView.image = UIImage(systemName: "location.north")
      
      let degrees = CGFloat(Double(str.split(separator: "-").last ?? "0") ?? 0)
      let radians: CGFloat = (degrees + 180) * (.pi / 180)
      imageView.transform = CGAffineTransform(rotationAngle: radians)
    case "person-swimming":
      imageView.image = UIImage(named: "person-swimming", in: OSCAWeatherUI.bundle, with: .none)?.withRenderingMode(.alwaysTemplate).withTintColor(.white)
      imageView.contentMode = .scaleAspectFit
      
    default:
      imageView.image = UIImage(systemName: weatherCell.imageName)
    }
  }
}
