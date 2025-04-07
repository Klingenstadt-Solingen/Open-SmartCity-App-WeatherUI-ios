//
//  OSCAWeatherUI.swift
//  OSCAWeatherUI
//
//  Created by Ömer Kurutay on 11.02.22.
//  Reviewed by Stephan Breidenbach on 21.06.22
//

import OSCAEssentials
import OSCAWeather
import Foundation
import UIKit
import OSCAWeatherUI

public protocol OSCAWeatherUIModuleConfig: OSCAUIModuleConfig {
    var cornerRadius: Double { get set }
    var shadow: OSCAShadowSettings { get set }
    var hasGradient: Bool { get set }
    var deeplinkScheme: String { get set }
}

public struct OSCAWeatherUIDependencies {
    let dataModule: OSCAWeather
    let moduleConfig: OSCAWeatherUIConfig
    let analyticsModule: OSCAAnalyticsModule?
    
    public init(dataModule: OSCAWeather,
                moduleConfig: OSCAWeatherUIConfig,
                analyticsModule: OSCAAnalyticsModule? = nil
    ) {
        self.dataModule = dataModule
        self.moduleConfig   = moduleConfig
        self.analyticsModule = analyticsModule
    }
}

public struct OSCAWeatherUIConfig: OSCAWeatherUIModuleConfig {
    /// module title
    public var title: String?
    public var externalBundle : Bundle?
    public var cornerRadius: Double
    public var shadow: OSCAShadowSettings
    public var hasGradient: Bool
    public var backgroundColors: [UIColor]
    public var fontConfig: OSCAFontConfig
    public var colorConfig: OSCAColorConfig
    /// app deeplink scheme URL part before `://`
    public var deeplinkScheme      : String = "solingen"
    public var selectedWeatherObservedId: String
    public var cardsBackgroundColor: UIColor
    public var cardsContentTint: UIColor?
    public var stationWidget: StationWidget
    
    public init(title: String?,
                externalBundle: Bundle? = nil,
                cornerRadius: Double,
                shadow: OSCAShadowSettings,
                hasGradient: Bool = true,
                backgroundColors: [UIColor]? = nil,
                fontConfig: OSCAFontConfig,
                colorConfig: OSCAColorConfig,
                deeplinkScheme: String = "solingen",
                selectedWeatherObservedId: String,
                cardsBackgroundColor: UIColor? = nil,
                cardsContentTint: UIColor? = nil,
                stationWidget: StationWidget = StationWidget()) {
        self.title = title
        self.externalBundle = externalBundle
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.hasGradient = hasGradient
        self.backgroundColors = backgroundColors ?? [
            colorConfig.primaryColor,
            colorConfig.primaryColor,
            colorConfig.whiteColor]
        self.fontConfig = fontConfig
        self.colorConfig = colorConfig
        self.deeplinkScheme = deeplinkScheme
        self.selectedWeatherObservedId = selectedWeatherObservedId
        self.cardsBackgroundColor = cardsBackgroundColor ?? self.colorConfig.whiteColor.withAlphaComponent(0.25)
        self.cardsContentTint = cardsContentTint
        self.stationWidget = stationWidget
    }
}

// MARK: Station Widget Config
extension OSCAWeatherUIConfig {
    public struct StationWidget {
        public var title              : String?
        public var maxItems           : Int
        public var itemHeight         : CGFloat
        public var allowExtendedLayout: Bool
        public var isIconHidden       : Bool
        
        public init(title              : String? = nil,
                    maxItems           : Int = 3,
                    itemHeight         : CGFloat = 112,
                    allowExtendedLayout: Bool = false,
                    isIconHidden       : Bool = false) {
            self.title               = title
            self.maxItems            = maxItems
            self.itemHeight          = itemHeight
            self.allowExtendedLayout = allowExtendedLayout
            self.isIconHidden        = isIconHidden
        }
    }
}

// MARK: - Keys
extension OSCAWeatherUI {
    /// UserDefaults object keys
    public enum Keys: String {
        case weatherStationWidgetVisibility = "Weather_Station_Widget_Visibility"
        case weatherStationWidgetPosition   = "Weather_Station_Widget_Position"
    }
}

public struct OSCAWeatherUI: OSCAUIModule {
    /// module DI container
    private var moduleDIContainer: OSCAWeatherUIDIContainer!
    public var version: String = "1.0.3"
    public var bundlePrefix: String = "de.osca.weather.ui"
    
    public internal(set) static var configuration: OSCAWeatherUIConfig!
    /// module `Bundle`
    ///
    /// **available after module initialization only!!!**
    public internal(set) static var bundle: Bundle!
    
    /**
     create module and inject module dependencies
     - Parameter mduleDependencies: module dependencies
     */
    public static func create(with moduleDependencies: OSCAWeatherUIDependencies) -> OSCAWeatherUI {
        var module: Self = Self.init(config: moduleDependencies.moduleConfig)
        module.moduleDIContainer = OSCAWeatherUIDIContainer(dependencies: moduleDependencies)
        return module
    }
    
    /// public initializer with module configuration
    /// - Parameter config: module configuration
    public init(config: OSCAUIModuleConfig) {
#if SWIFT_PACKAGE
        Self.bundle = Bundle.module
#else
        guard let bundle: Bundle = Bundle(identifier: self.bundlePrefix) else { fatalError("Module bundle not initialized!") }
        Self.bundle = bundle
#endif
        guard let extendedConfig = config as? OSCAWeatherUIConfig else { fatalError("Config couldn't be initialized!")}
        OSCAWeatherUI.configuration = extendedConfig
    }
    
    /**
     public module interface `getter`for `OSCAWeatherStationFlowCoordinator`
     - Parameter router: router needed or the navigation graph
     */
    public func getWeatherFlowCoordinator(router: Router) -> OSCAWeatherFlowCoordinator {
        let flow = self.moduleDIContainer.makeWeatherStationFlowCoordinator(router: router)
        return flow
    }
    
    /**
     public module interface `getter`for `OSCAWeatherStationSelectionFlowCoordinator`
     - Parameter router: router needed or the navigation graph
     */
    public func getWeatherStationSelectionFlowCoordinator(router: Router, didSelectStation: ((String) -> Void)? = nil) -> OSCAWeatherStationSelectionFlowCoordinator {
        let flow = self.moduleDIContainer.makeWeatherStationSelectionFlowCoordinator(router: router, didSelectStation: didSelectStation)
        return flow
    }
    
    /**
     public module interface `getter`for `OSCAWeatherStationSelectionFlowCoordinator`
     - Parameter router: router needed or the navigation graph
     */
    public func getWeatherListFlowCoordinator(router: Router, didSelectStation: ((String) -> Void)? = nil) -> OSCAWeatherListFlowCoordinator {
        let flow = self.moduleDIContainer.makeWeatherListFlowCoordinator(router: router, didSelectStation: didSelectStation)
        return flow
    }
    
    /**
     public module interface `getter`for `OSCAWeatherWidgetFlowCoordinator`
     - Parameter router: router needed or the navigation graph
     */
    public func getWeatherWidgetFlowCoordinator(router: Router) -> OSCAWeatherWidgetFlowCoordinator {
        self.moduleDIContainer
            .makeWeatherWidgetFlowCoordinator(router: router)
    }
}
