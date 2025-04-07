//
//  WeatherStationFlow+OSCADeeplinkHandeble.swift
//  OSCAWeatherUI
//
//  Created by Stephan Breidenbach on 08.09.22.
//

import Foundation
import OSCAEssentials

extension OSCAWeatherFlowCoordinator: OSCADeeplinkHandeble {
  ///```console
  ///xcrun simctl openurl booted \
  /// "solingen://sensorstation/detail?station=O9ukYZqbSE"
  /// ```
  public func canOpenURL(_ url: URL) -> Bool {
    let deeplinkScheme: String = dependencies
      .deeplinkScheme
    return url.absoluteString.hasPrefix("\(deeplinkScheme)://sensorstation")
  }// end public func canOpenURL
  
  public func openURL(_ url: URL,
                      onDismissed:(() -> Void)?) throws -> Void {
    guard canOpenURL(url)
    else { return }
    let deeplinkParser = DeeplinkParser()
    if let payload = deeplinkParser.parse(content: url) {
      switch payload.target {
      case "detail":
        let stationId = payload.parameters["station"]
        showWeatherMain(with: stationId,
                        onDismissed: onDismissed)
      default:
        showWeatherMain(animated: true,
                        onDismissed: onDismissed)
      }
    } else {
      showWeatherMain(animated: true,
                      onDismissed: onDismissed)
    }// end if
  }// end public func openURL
  
  public func showWeatherMain(with stationId: String? = nil,
                              onDismissed:(() -> Void)?) -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function): stationId: \(stationId ?? "NIL")")
#endif
    /// is there an object id?
    if let stationId = stationId {
      /// is there a weather station main view controller
      if let weatherStationMainVC = weatherStationVC {
        weatherStationMainVC.didReceiveDeeplinkDetail(with: stationId)
      } else {
        showWeatherMain(animated: true, onDismissed: nil)
        guard let weatherStationMainVC = weatherStationVC
        else { return }
        weatherStationMainVC.didReceiveDeeplinkDetail(with: stationId)
      }// end if
    }// end
  }// end public func showWeatherMain
}// end extension final class OSCAWeatherFlowCoordinator
