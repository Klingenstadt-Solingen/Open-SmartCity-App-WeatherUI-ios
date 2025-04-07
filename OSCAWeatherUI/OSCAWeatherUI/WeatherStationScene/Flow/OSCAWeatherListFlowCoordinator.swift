//
//  OSCAWeatherListCoordinator.swift
//  OSCAWeatherUI
//
//

import OSCAEssentials
import OSCAWeather
import UIKit

public protocol OSCAWeatherListFlowCoordinatorDependencies {
    var deeplinkScheme: String { get }
    func makeOSCAWeatherListViewController(actions: OSCAWeatherListViewModelActions) -> OSCAWeatherListViewController
}

public final class OSCAWeatherListFlowCoordinator: Coordinator {
    /**
     `children`property for conforming to `Coordinator` protocol is a list of `Coordinator`s
     */
    public var children: [Coordinator] = []
    
    /**
     router injected via initializer: `router` will be used to push and pop view controllers
     */
    public let router: Router
    
    /**
     dependencies injected via initializer DI conforming to the `OSCAWeatherListFlowCoordinatorDependencies` protocol
     */
    let dependencies: OSCAWeatherListFlowCoordinatorDependencies
    
    weak var weatherListVC: OSCAWeatherListViewController?
    
    private var didSelectStation: ((String) -> Void)? = nil
    
    public init(router: Router, dependencies: OSCAWeatherListFlowCoordinatorDependencies,
                didSelectStation: ((String) -> Void)? = nil) {
        self.router = router
        self.dependencies = dependencies
        self.didSelectStation = didSelectStation
    }
    
    private func showWeatherList(animated: Bool,
                                 onDismissed: (() -> Void)?) -> Void {
        if let weatherListVC = weatherListVC {
            weatherListVC.dismiss(animated: true)
        }
        let actions = OSCAWeatherListViewModelActions(didSelectStation: self.didSelectStation)
        let vc = self.dependencies.makeOSCAWeatherListViewController(
            actions: actions)
        let nav = UINavigationController(rootViewController: vc)
        self.router.presentModalViewController(
            nav,
            animated: true,
            onDismissed: nil)
        self.weatherListVC = vc
    }
    
    public func present(animated: Bool, onDismissed: (() -> Void)?) {
        // Note: here we keep strong reference with actions, this way this flow do not need to be strong referenced
        showWeatherList(animated: animated,
                        onDismissed: onDismissed)
    }
}
