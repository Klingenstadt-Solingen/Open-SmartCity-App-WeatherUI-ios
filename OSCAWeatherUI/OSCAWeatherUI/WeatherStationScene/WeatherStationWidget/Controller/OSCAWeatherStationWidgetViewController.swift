//
//  OSCAWeatherStationWidgetViewController.swift
//  OSCAWeatherUI
//
//  Created by Ömer Kurutay on 10.05.23.
//

import OSCAEssentials
import OSCAWeather
import UIKit
import Combine

public final class OSCAWeatherStationWidgetViewController: UIViewController, Alertable, ActivityIndicatable, WidgetExtender {
  
  public var activityIndicatorView: ActivityIndicatorView = ActivityIndicatorView(style: .large)
  
  @IBOutlet private var collectionView: UICollectionView!
  
  @IBOutlet var collectionViewHeightConstraint: NSLayoutConstraint!
  
  private typealias DataSource = UICollectionViewDiffableDataSource<OSCAWeatherStationWidgetViewModel.Section, OSCAWeatherObserved>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<OSCAWeatherStationWidgetViewModel.Section, OSCAWeatherObserved>
  
  private var viewModel: OSCAWeatherStationWidgetViewModel!
  private var bindings = Set<AnyCancellable>()
  
  private var dataSource: DataSource!
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    self.setupViews()
    self.setupBindings()
    self.viewModel.viewDidLoad()
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let colorConfig = self.viewModel.colorConfig
    self.navigationController?.setup(
      largeTitles: false,
      tintColor: colorConfig.navigationTintColor,
      titleTextColor: colorConfig.navigationTitleTextColor,
      barColor: colorConfig.navigationBarColor)
  }
  
  private func setupViews() {
    self.view.backgroundColor = .clear
    
    self.navigationItem.title = self.viewModel.widgetTitle
    
    self.setupActivityIndicator()
    self.setupCollectionView()
  }
  
  private func setupCollectionView() {
    self.collectionView.delegate = self
    self.collectionView.backgroundColor = .clear
    
    let identifier: String
    
    switch self.viewModel.cellMode {
    case .classic:
      identifier = OSCAWeatherStationWidgetClassicCellView.identifier
      
    case .extended:
      identifier = OSCAWeatherStationWidgetExtendedCellView.identifier
    }
    
    let nib = UINib(nibName: identifier, bundle: OSCAWeatherUI.bundle)
    self.collectionView.register(nib,
                                 forCellWithReuseIdentifier: identifier)
    self.collectionView.collectionViewLayout = self.createLayout()
    self.collectionViewHeightConstraint.constant = 150
  }
  
  private func createLayout() -> UICollectionViewLayout {
    let height = OSCAWeatherUI.configuration.stationWidget.itemHeight
    let section: NSCollectionLayoutSection
    
    switch self.viewModel.cellMode {
    case .classic:
      let columns: Int = 3
      let width = CGFloat(1 / Double(columns))
      let size = NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(width),
        heightDimension: .fractionalHeight(1.0))
      let item = NSCollectionLayoutItem(layoutSize: size)
      
      let groupSize = NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1.0),
        heightDimension: .absolute(height))
      let group: NSCollectionLayoutGroup
      if #available(iOS 16.0, *) {
        group = NSCollectionLayoutGroup.horizontal(
          layoutSize: groupSize,
          repeatingSubitem: item,
          count: columns)
      } else {
        group = NSCollectionLayoutGroup.horizontal(
          layoutSize: groupSize,
          subitem: item,
          count: columns)
      }
      group.interItemSpacing = .fixed(8)
      
      section = NSCollectionLayoutSection(group: group)
      section.interGroupSpacing = 8
      
    case .extended:
      let size = NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1.0),
        heightDimension: .absolute(height))
      let item = NSCollectionLayoutItem(layoutSize: size)
      
      let groupSize = NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1.0),
        heightDimension: .estimated(height))
      let group = NSCollectionLayoutGroup.vertical(
        layoutSize: groupSize,
        subitems: [item])
      group.interItemSpacing = .fixed(8)
      
      section = NSCollectionLayoutSection(group: group)
      section.interGroupSpacing = 8
    }
    
    return UICollectionViewCompositionalLayout(section: section)
  }
  
  // MARK: - Bindings
  private func setupBindings() {
    self.viewModel.$weatherStations
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] weatherStations in
        guard let `self` = self else { return }
        self.configureDataSource()
        self.updateSections(weatherStations)
      })
      .store(in: &self.bindings)
    
    let startLoading = {
      self.collectionView.isUserInteractionEnabled = false
      self.showActivityIndicator()
    }
    
    let finishLoading = {
      self.collectionView.isUserInteractionEnabled = true
      self.hideActivityIndicator()
      self.view.layoutIfNeeded()
      let height = self.viewModel.weatherStations.count == 0
        ? 100
        : self.collectionView.collectionViewLayout.collectionViewContentSize.height
      self.collectionViewHeightConstraint.constant = height
      
      guard let didLoadContent = self.didLoadContent
      else { return }
      didLoadContent(self.viewModel.weatherStations.count)
    }
    
    let stateValueHandler: (OSCAWeatherStationWidgetViewModel.State) -> Void = { [weak self] state in
      guard let `self` = self else { return }
      
      switch state {
      case .loading:
        startLoading()
        
      case .finishedLoading:
        finishLoading()
        
      case let .error(error):
        finishLoading()
        self.showAlert(
          title: self.viewModel.alertTitleError,
          message: error.localizedDescription,
          actionTitle: self.viewModel.alertActionConfirm)
      }
    }
    
    self.viewModel.$state
      .receive(on: RunLoop.main)
      .sink(receiveValue: stateValueHandler)
      .store(in: &self.bindings)
  }
  
  private func updateSections(_ weatherStations: [OSCAWeatherObserved]) {
    var snapshot = Snapshot()
    snapshot.appendSections([.weatherStations])
    snapshot.appendItems(weatherStations)
    self.dataSource.apply(snapshot, animatingDifferences: true)
  }
  
  // MARK: WidgetExtender
  /// Closure parameter sends the number of weather stations
  public var didLoadContent   : ((Int) -> Void)?
  /// Closure parameter sends a deeplink of type __URL__
  public var performNavigation: ((Any) -> Void)?
  
  public func refreshContent() {
    self.viewModel.refreshContent()
  }
}

extension OSCAWeatherStationWidgetViewController {
  private func configureDataSource() -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    switch self.viewModel.cellMode {
    case .classic:
      self.dataSource = DataSource(
        collectionView: self.collectionView,
        cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell in
          guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OSCAWeatherStationWidgetClassicCellView.identifier,
            for: indexPath) as? OSCAWeatherStationWidgetClassicCellView
          else { return UICollectionViewCell() }
          
          cell.viewModel = OSCAWeatherStationWidgetClassicCellViewModel(
            weatherStation: item)
          
          return cell
        })
      
    case .extended:
      self.dataSource = DataSource(
        collectionView: self.collectionView,
        cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell in
          guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OSCAWeatherStationWidgetExtendedCellView.identifier,
            for: indexPath) as? OSCAWeatherStationWidgetExtendedCellView
          else { return UICollectionViewCell() }
          
          cell.viewModel = OSCAWeatherStationWidgetExtendedCellViewModel(
            weatherStation: item)
          
          return cell
        })
    }
  }
}

// MARK: - Collection View Delegate
extension OSCAWeatherStationWidgetViewController: UICollectionViewDelegate {
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let objectId = self.viewModel.weatherStations[indexPath.row].objectId
    else { return }
    let deeplinkScheme = self.viewModel.moduleConfig.deeplinkScheme
    let deeplink = "\(deeplinkScheme)://sensorstation/detail?station=\(objectId)"
    guard let url = URL(string: deeplink),
          let performNavigation = self.performNavigation
    else { return }
    performNavigation(url)
  }
}

// MARK: - instantiate view conroller
extension OSCAWeatherStationWidgetViewController: StoryboardInstantiable {
  public static func create(with viewModel: OSCAWeatherStationWidgetViewModel) -> OSCAWeatherStationWidgetViewController {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    let vc: Self = Self.instantiateViewController(OSCAWeatherUI.bundle)
    vc.viewModel = viewModel
    return vc
  }
}
