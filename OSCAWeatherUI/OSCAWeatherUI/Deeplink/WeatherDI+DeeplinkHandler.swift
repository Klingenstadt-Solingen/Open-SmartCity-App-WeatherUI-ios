//
//  WeatherDI+DeeplinkHandler.swift
//  OSCAWeatherUI
//
//  Created by Stephan Breidenbach on 08.09.22.
//

import Foundation
extension OSCAWeatherUIDIContainer {
  var deeplinkScheme: String {
    return self
      .dependencies
      .moduleConfig
      .deeplinkScheme
  }// end var deeplinkScheme
}// end extension final class OSCAWeatherUIDIContainer
