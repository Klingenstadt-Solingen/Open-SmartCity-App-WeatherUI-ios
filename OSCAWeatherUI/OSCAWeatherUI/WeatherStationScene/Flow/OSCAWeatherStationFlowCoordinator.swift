//
//  OSCAWeatherStationFlowCoordinator.swift
//  OSCAWeatherUI
//
//  Created by Ömer Kurutay on 14.02.22.
//

import OSCAEssentials
import OSCAWeather
import Foundation

public protocol OSCAWeatherFlowCoordinatorDependencies {
  var deeplinkScheme: String { get }
  func makeOSCAWeatherStationViewController(actions: OSCAWeatherStationViewModelActions) -> OSCAWeatherStationViewController
  func makeOSCAWeatherStationSelectionViewController(actions: OSCAWeatherStationSelectionViewModelActions) -> OSCAWeatherStationSelectionViewController
}

public final class OSCAWeatherFlowCoordinator: Coordinator {
  /**
   `children`property for conforming to `Coordinator` protocol is a list of `Coordinator`s
   */
  public var children: [Coordinator] = []
  
  /**
   router injected via initializer: `router` will be used to push and pop view controllers
   */
  public let router: Router
  
  /**
   dependencies injected via initializer DI conforming to the `OSCAWeatherStationFlowCoordinatorDependencies` protocol
   */
  let dependencies: OSCAWeatherFlowCoordinatorDependencies
  
  /**
   weather station view controller `OSCAWeatherStationViewController`
   */
  weak var weatherStationVC: OSCAWeatherStationViewController?
  weak var weatherStationSelectionVC: OSCAWeatherStationSelectionViewController?
  
  public init(router: Router, dependencies: OSCAWeatherFlowCoordinatorDependencies) {
    self.router = router
    self.dependencies = dependencies
  }
  
  private func showWeatherStationSelection() -> Void {
    if let weatherStationSelectionVC = weatherStationSelectionVC {
      weatherStationSelectionVC.dismiss(animated: true)
    }// end if
    let actions = OSCAWeatherStationSelectionViewModelActions()
    let vc = self.dependencies.makeOSCAWeatherStationSelectionViewController(
      actions: actions)
    self.router.present(vc,
                        animated: true,
                        onDismissed: nil)
    self.weatherStationSelectionVC = vc
  }// end private func showWeatherStationSelection
  
  func showWeatherMain(animated: Bool,
                       onDismissed: (() -> Void)?) -> Void {
    let actions = OSCAWeatherStationViewModelActions(
      showWeatherStationSelection: self.showWeatherStationSelection)
    
    let vc = self.dependencies.makeOSCAWeatherStationViewController(actions: actions)
    self.router.present(vc,
                        animated: animated,
                        onDismissed: onDismissed)
    self.weatherStationVC = vc
  }// end func showWeatherMain
  
  public func present(animated: Bool, onDismissed: (() -> Void)?) {
    // Note: here we keep strong reference with actions, this way this flow do not need to be strong referenced
    showWeatherMain(animated: animated,
                    onDismissed: onDismissed)
  }// end public func present
}
