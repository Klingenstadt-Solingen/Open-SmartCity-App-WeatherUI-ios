//
//  OSCAWeatherStationSelectionFlowCoordinator.swift
//  OSCAWeatherUI
//
//  Created by Ömer Kurutay on 07.10.22.
//

import OSCAEssentials
import OSCAWeather
import UIKit

public protocol OSCAWeatherStationSelectionFlowCoordinatorDependencies {
  var deeplinkScheme: String { get }
  func makeOSCAWeatherStationSelectionViewController(actions: OSCAWeatherStationSelectionViewModelActions) -> OSCAWeatherStationSelectionViewController
}

public final class OSCAWeatherStationSelectionFlowCoordinator: Coordinator {
  /**
   `children`property for conforming to `Coordinator` protocol is a list of `Coordinator`s
   */
  public var children: [Coordinator] = []
  
  /**
   router injected via initializer: `router` will be used to push and pop view controllers
   */
  public let router: Router
  
  /**
   dependencies injected via initializer DI conforming to the `OSCAWeatherStationStationSelectionFlowCoordinatorDependencies` protocol
   */
  let dependencies: OSCAWeatherStationSelectionFlowCoordinatorDependencies
  
  weak var weatherStationSelectionVC: OSCAWeatherStationSelectionViewController?
  
  private var didSelectStation: ((String) -> Void)? = nil
  
  public init(router: Router, dependencies: OSCAWeatherStationSelectionFlowCoordinatorDependencies,
              didSelectStation: ((String) -> Void)? = nil) {
    self.router = router
    self.dependencies = dependencies
    self.didSelectStation = didSelectStation
  }
  
  private func showWeatherStationSelection(animated: Bool,
                                           onDismissed: (() -> Void)?) -> Void {
    if let weatherStationSelectionVC = weatherStationSelectionVC {
      weatherStationSelectionVC.dismiss(animated: true)
    }// end if
    let actions = OSCAWeatherStationSelectionViewModelActions(didSelectStation: self.didSelectStation)
    let vc = self.dependencies.makeOSCAWeatherStationSelectionViewController(
      actions: actions)
    let nav = UINavigationController(rootViewController: vc)
    self.router.presentModalViewController(
      nav,
      animated: true,
      onDismissed: nil)
    self.weatherStationSelectionVC = vc
  }// end private func showWeatherStationSelection
  
  public func present(animated: Bool, onDismissed: (() -> Void)?) {
    // Note: here we keep strong reference with actions, this way this flow do not need to be strong referenced
    showWeatherStationSelection(animated: animated,
                                onDismissed: onDismissed)
  }// end public func present
}
