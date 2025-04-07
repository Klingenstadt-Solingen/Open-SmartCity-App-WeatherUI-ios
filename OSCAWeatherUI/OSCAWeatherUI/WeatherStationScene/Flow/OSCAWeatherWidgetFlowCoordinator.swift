//
//  OSCAWeatherWidgetFlowCoordinator.swift
//  OSCAWeatherUI
//
//  Created by Ömer Kurutay on 10.05.23.
//

import OSCAEssentials
import Foundation

public protocol OSCAWeatherWidgetFlowCoordinatorDependencies {
  func makeOSCAWeatherStationWidgetViewController(actions: OSCAWeatherStationWidgetViewModel.Actions) -> OSCAWeatherStationWidgetViewController
}

public final class OSCAWeatherWidgetFlowCoordinator: Coordinator {
  /**
   `children`property for conforming to `Coordinator` protocol is a list of `Coordinator`s
   */
  public var children: [Coordinator] = []
  /**
   router injected via initializer: `router` will be used to push and pop view controllers
   */
  public let router: Router
  /**
   dependencies injected via initializer DI conforming to the `OSCAWeatherWidgetFlowCoordinatorDependencies` protocol
   */
  let dependencies: OSCAWeatherWidgetFlowCoordinatorDependencies
  /**
   waste view controller `OSCAWeatherStationWidgetViewController`
   */
  public weak var weatherStationWidgetVC: OSCAWeatherStationWidgetViewController?
  
  public init(router: Router, dependencies: OSCAWeatherWidgetFlowCoordinatorDependencies) {
    self.router = router
    self.dependencies = dependencies
  }
  
  func showWeatherStationWidget(animated: Bool, onDismissed: (() -> Void)?) -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    let actions = OSCAWeatherStationWidgetViewModel.Actions()
    let vc = self.dependencies
      .makeOSCAWeatherStationWidgetViewController(actions: actions)
    self.weatherStationWidgetVC = vc
  }
  
  public func present(animated: Bool, onDismissed: (() -> Void)?) {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    self.showWeatherStationWidget(
      animated: animated,
      onDismissed: onDismissed)
  }
}

extension OSCAWeatherWidgetFlowCoordinator {
  /**
   add `child` `Coordinator`to `children` list of `Coordinator`s and present `child` `Coordinator`
   */
  public func presentChild(_ child: Coordinator, animated: Bool, onDismissed: (() -> Void)? = nil) {
    self.children.append(child)
    child.present(animated: animated) { [weak self, weak child] in
      guard let self = self, let child = child else { return }
      self.removeChild(child)
      onDismissed?()
    }
  }
  
  private func removeChild(_ child: Coordinator) {
    /// `children` includes `child`!!
    guard let index = self.children.firstIndex(where: { $0 === child })
    else { return }
    self.children.remove(at: index)
  }
}
