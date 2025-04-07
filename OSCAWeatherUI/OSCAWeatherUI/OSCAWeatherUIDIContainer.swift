//
//  OSCAWeatherUIDIContainer.swift
//  OSCAWeatherUI
//
//  Created by Ömer Kurutay on 11.02.22.
//

import OSCAEssentials
import OSCAWeather
import OSCAWeatherUI

/**
 Every isolated module feature will have its own Dependency Injection Container,
 to have one entry point where we can see all dependencies and injections of the module
 */
final class OSCAWeatherUIDIContainer {
    
    let dependencies: OSCAWeatherUIDependencies
    
    public init(dependencies: OSCAWeatherUIDependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Flow Coordinators
    
    func makeWeatherStationFlowCoordinator(router: Router) -> OSCAWeatherFlowCoordinator {
        OSCAWeatherFlowCoordinator(router: router, dependencies: self)
    }
    
    func makeWeatherStationSelectionFlowCoordinator(router: Router, didSelectStation: ((String) -> Void)? = nil) -> OSCAWeatherStationSelectionFlowCoordinator {
        OSCAWeatherStationSelectionFlowCoordinator(router: router, dependencies: self, didSelectStation: didSelectStation)
    }
    
    func makeWeatherListFlowCoordinator(router: Router, didSelectStation: ((String) -> Void)? = nil) -> OSCAWeatherListFlowCoordinator {
        OSCAWeatherListFlowCoordinator(router: router, dependencies: self, didSelectStation: didSelectStation)
    }
    
    func makeWeatherWidgetFlowCoordinator(router: Router) -> OSCAWeatherWidgetFlowCoordinator {
        OSCAWeatherWidgetFlowCoordinator(router: router, dependencies: self)
    }
}

// MARK: Weather Station
extension OSCAWeatherUIDIContainer: OSCAWeatherFlowCoordinatorDependencies {
    func makeOSCAWeatherStationViewController(actions: OSCAWeatherStationViewModelActions) -> OSCAWeatherStationViewController {
        return OSCAWeatherStationViewController.create(with: makeOSCAWeatherStationViewModel(actions: actions))
    }
    
    func makeOSCAWeatherStationViewModel(actions: OSCAWeatherStationViewModelActions) -> OSCAWeatherStationViewModel {
        return OSCAWeatherStationViewModel(dataModule: dependencies.dataModule, actions: actions)
    }
}

// MARK: Weather Station Selection
extension OSCAWeatherUIDIContainer: OSCAWeatherStationSelectionFlowCoordinatorDependencies {
    func makeOSCAWeatherStationSelectionViewController(actions: OSCAWeatherStationSelectionViewModelActions) -> OSCAWeatherStationSelectionViewController {
        return OSCAWeatherStationSelectionViewController.create(with: makeOSCAWeatherStationSelectionViewModel(actions: actions))
    }
    
    func makeOSCAWeatherStationSelectionViewModel(actions: OSCAWeatherStationSelectionViewModelActions) -> OSCAWeatherStationSelectionViewModel {
        return OSCAWeatherStationSelectionViewModel(dataModule: dependencies.dataModule, actions: actions)
    }
}

// MARK: Weather List
extension OSCAWeatherUIDIContainer: OSCAWeatherListFlowCoordinatorDependencies {
    func makeOSCAWeatherListViewController(actions: OSCAWeatherListViewModelActions) -> OSCAWeatherListViewController {
        return OSCAWeatherListViewController.create(with: makeOSCAWeatherListViewModel(actions: actions))
    }
    
    func makeOSCAWeatherListViewModel(actions: OSCAWeatherListViewModelActions) -> OSCAWeatherListViewModel {
        return OSCAWeatherListViewModel(dataModule: dependencies.dataModule, actions: actions, moduleConfig: self.dependencies.moduleConfig)
    }
}

// MARK: Weather Station Widget
extension OSCAWeatherUIDIContainer: OSCAWeatherWidgetFlowCoordinatorDependencies {
    func makeOSCAWeatherStationWidgetViewController(actions: OSCAWeatherStationWidgetViewModel.Actions) -> OSCAWeatherStationWidgetViewController {
        let viewModel = self.makeOSCAWeatherStationWidgetViewModel(actions: actions)
        return OSCAWeatherStationWidgetViewController.create(with: viewModel)
    }
    
    func makeOSCAWeatherStationWidgetViewModel(actions: OSCAWeatherStationWidgetViewModel.Actions) -> OSCAWeatherStationWidgetViewModel {
        let dependencies = OSCAWeatherStationWidgetViewModel.Dependencies(
            actions: actions,
            dataModule: self.dependencies.dataModule,
            moduleConfig: self.dependencies.moduleConfig)
        return OSCAWeatherStationWidgetViewModel(dependencies: dependencies)
    }
}
