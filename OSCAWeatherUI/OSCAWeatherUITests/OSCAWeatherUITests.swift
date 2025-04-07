//
//  OSCAWeatherUITests.swift
//
//
//  Created by Ömer Kurutay on 11.02.22.
//  Reviewed by Stephan Breidenbach on 21.06.22
//
#if canImport(XCTest) && canImport(OSCATestCaseExtension)
import XCTest
@testable import OSCAWeatherUI
@testable import OSCAWeather
import OSCAEssentials
import OSCATestCaseExtension

final class OSCAWeatherUITests: XCTestCase {
  static let moduleVersion = "1.0.4"
  override func setUpWithError() throws {
    try super.setUpWithError()
  }// end override fun setUp
  
  func testModuleInit() throws -> Void {
    let uiModule = try makeDevUIModule()
    XCTAssertNotNil(uiModule)
    XCTAssertEqual(uiModule.version, OSCAWeatherUITests.moduleVersion)
    XCTAssertEqual(uiModule.bundlePrefix, "de.osca.weather.ui")
    let bundle = OSCAWeather.bundle
    XCTAssertNotNil(bundle)
    let uiBundle = OSCAWeatherUI.bundle
    XCTAssertNotNil(uiBundle)
    let configuration = OSCAWeatherUI.configuration
    XCTAssertNotNil(configuration)
    XCTAssertNotNil(self.devPlistDict)
    XCTAssertNotNil(self.productionPlistDict)
  }// end func testModuleInit
  
  func testContactUIConfiguration() throws -> Void {
    let _ = try makeDevUIModule()
    let uiModuleConfig = try makeUIModuleConfig()
    XCTAssertEqual(OSCAWeatherUI.configuration.title, uiModuleConfig.title)
    XCTAssertEqual(OSCAWeatherUI.configuration.colorConfig.accentColor, uiModuleConfig.colorConfig.accentColor)
    XCTAssertEqual(OSCAWeatherUI.configuration.fontConfig.bodyHeavy, uiModuleConfig.fontConfig.bodyHeavy)
  }// end func testEventsUIConfiguration
}// end final class OSCAWeatherUITests

// MARK: - factory methods
extension OSCAWeatherUITests {
  public func makeDevModuleDependencies() throws -> OSCAWeatherDependencies {
    let networkService = try makeDevNetworkService()
    let userDefaults   = try makeUserDefaults(domainString: "de.osca.weather.ui")
    let dependencies = OSCAWeatherDependencies(
      networkService: networkService,
      userDefaults: userDefaults)
    return dependencies
  }// end public func makeDevModuleDependencies
  
  public func makeDevModule() throws -> OSCAWeather {
    let devDependencies = try makeDevModuleDependencies()
    // initialize module
    let module = OSCAWeather.create(with: devDependencies)
    return module
  }// end public func makeDevModule
  
  public func makeProductionModuleDependencies() throws -> OSCAWeatherDependencies {
    let networkService = try makeProductionNetworkService()
    let userDefaults   = try makeUserDefaults(domainString: "de.osca.weather.ui")
    let dependencies = OSCAWeatherDependencies(
      networkService: networkService,
      userDefaults: userDefaults)
    return dependencies
  }// end public func makeProductionModuleDependencies
  
  public func makeProductionModule() throws -> OSCAWeather {
    let productionDependencies = try makeProductionModuleDependencies()
    // initialize module
    let module = OSCAWeather.create(with: productionDependencies)
    return module
  }// end public func makeProductionModule
  
  public func makeUIModuleConfig() throws -> OSCAWeatherUIConfig {
    return OSCAWeatherUIConfig(title: "OSCAWeatherUI",
                               cornerRadius: 10.0,
                               shadow: OSCAShadowSettings(opacity: 0.3,
                                                          radius: 10,
                                                          offset: CGSize(width: 0, height: 2)),
                               fontConfig: OSCAFontSettings(),
                               colorConfig: OSCAColorSettings(),
                               selectedWeatherObservedId: "")
  }// end public func makeUIModuleConfig
  
  public func makeDevUIModuleDependencies() throws -> OSCAWeatherUIDependencies {
    let module      = try makeDevModule()
    let uiConfig    = try makeUIModuleConfig()
    return OSCAWeatherUIDependencies( dataModule: module,
                                      moduleConfig: uiConfig)
  }// end public func makeDevUIModuleDependencies
  
  public func makeDevUIModule() throws -> OSCAWeatherUI {
    let devDependencies = try makeDevUIModuleDependencies()
    // init ui module
    let uiModule = OSCAWeatherUI.create(with: devDependencies)
    return uiModule
  }// end public func makeUIModule
  
  public func makeProductionUIModuleDependencies() throws -> OSCAWeatherUIDependencies {
    let module      = try makeProductionModule()
    let uiConfig    = try makeUIModuleConfig()
    return OSCAWeatherUIDependencies( dataModule: module,
                                      moduleConfig: uiConfig)
  }// end public func makeProductionUIModuleDependencies
  
  public func makeProductionUIModule() throws -> OSCAWeatherUI {
    let productionDependencies = try makeProductionUIModuleDependencies()
    // init ui module
    let uiModule = OSCAWeatherUI.create(with: productionDependencies)
    return uiModule
  }// end public func makeProductionUIModule
}// end extension OSCAWeatherUITests
#endif
