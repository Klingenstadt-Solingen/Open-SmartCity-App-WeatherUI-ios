//
//  OSCAWeatherStationViewController.swift
//  OSCAWeatherUI
//
//  Created by Ömer Kurutay on 11.02.22.
//

import OSCAWeather
import OSCAEssentials
import UIKit
import Combine

public final class OSCAWeatherStationViewController: UIViewController, Alertable {
  @IBOutlet private var collectionView: UICollectionView!
  
  private let refreshControl = UIRefreshControl()
  
  private var viewModel: OSCAWeatherStationViewModel!
  private var bindings = Set<AnyCancellable>()
  
  /// Called after the controller's view is loaded into memory.
  public override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    setupBindings()
    viewModel.viewDidLoad()
  }
  
  private func setupViews() {
    refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    refreshControl.tintColor = OSCAWeatherUI.configuration.colorConfig.grayColor
    collectionView.refreshControl = refreshControl
    collectionView.backgroundColor = .clear
    collectionView.delegate = self
    collectionView.dataSource = self
  }
  
  private func setupBindings() {
    viewModel.$weatherObservedCells
      .receive(on: RunLoop.main)
      .sink(receiveValue: { [weak self] _ in
        self?.collectionView.reloadData()
      })
      .store(in: &bindings)
    
    let stateValueHandler: (OSCAWeatherStationViewModelState) -> Void = { [weak self] state in
      guard let `self` = self else { return }
      
      switch state {
      case .loading:
        self.beginLoadingAnimation()
        
      case .finishedLoading:
        self.endLoadingAnimation()
        
      case let .error(error):
        self.endLoadingAnimation()
        print("Error: \(error.localizedDescription)")
      }
    }
    
    viewModel.$state
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: stateValueHandler)
      .store(in: &bindings)
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let barAppearance = UINavigationBarAppearance()
    barAppearance.configureWithTransparentBackground()
    barAppearance.titleTextAttributes = [.foregroundColor: self.foregroundColor]
    barAppearance.largeTitleTextAttributes = [.foregroundColor: self.foregroundColor]
    
    let navigationBar = self.navigationController?.navigationBar
    navigationBar?.prefersLargeTitles = false
    navigationBar?.tintColor = self.foregroundColor
    navigationBar?.standardAppearance = barAppearance
    navigationBar?.scrollEdgeAppearance = barAppearance
  }
  
  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if OSCAWeatherUI.configuration.hasGradient {
      self.view.addGradient(
        colors: OSCAWeatherUI.configuration.backgroundColors,
        locations: [0.0, 0.2, 1.0],
        startPoint: CGPoint(x: 0.0, y: 0.0),
        endPoint: CGPoint(x: 0.0, y: 1.0),
        type: .axial)
    } else {
      self.view.backgroundColor = OSCAWeatherUI.configuration.backgroundColors.first ?? OSCAWeatherUI.configuration.colorConfig.primaryColor
    }
  }
  
  @objc private func refreshData() {
    viewModel.refreshData()
  }
  
  private var foregroundColor: UIColor {
    let topColor = OSCAWeatherUI.configuration.backgroundColors.first ?? OSCAWeatherUI.configuration.colorConfig.primaryColor
    
    return topColor.isDarkColor
      ? OSCAWeatherUI.configuration.colorConfig.whiteDark
      : OSCAWeatherUI.configuration.colorConfig.blackColor
  }
  
  private func beginLoadingAnimation() {
    collectionView.refreshControl?.beginRefreshing()
    UIView.animate(withDuration: 0.25, delay: 0, options: .beginFromCurrentState) {
      self.collectionView.contentOffset.y = -(self.refreshControl.frame.height)
    }
  }
  
  private func endLoadingAnimation() {
    collectionView.refreshControl?.endRefreshing()
    UIView.animate(withDuration: 0.25, delay: 0, options: .beginFromCurrentState) {
      self.collectionView.contentOffset.y = .zero
    }
  }
}

// MARK: - instantiate view conroller
extension OSCAWeatherStationViewController: StoryboardInstantiable {
  public static func create(with viewModel: OSCAWeatherStationViewModel) -> OSCAWeatherStationViewController {
    let vc = Self.instantiateViewController(OSCAWeatherUI.bundle)
    vc.viewModel = viewModel
    return vc
  }
}

extension OSCAWeatherStationViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  
  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    viewModel.numberOfSections
  }
  
  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    let width = collectionView.frame.width
    let height = collectionView.frame.height / 2
    return CGSize(width: width, height: height)
  }
  
  public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionView.elementKindSectionHeader:
      guard let header = collectionView.dequeueReusableSupplementaryView(
        ofKind: kind,
        withReuseIdentifier: OSCAWeatherStationCollectionReusableView.reuseIdentifier,
        for: indexPath) as? OSCAWeatherStationCollectionReusableView
      else { return UICollectionReusableView() }
      
      guard let weatherObserved = viewModel.currentWeatherObserved
      else { return header }
      header.fill(with: OSCAWeatherStationCollectionReusableViewModel(dataModule: self.viewModel.dataModule, weatherObserved: weatherObserved), mainViewModel: viewModel)
      
      return header
      
    default: return UICollectionReusableView()
    }
  }
  
  public func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
    return viewModel.numberOfItemsInSection
  }
  
  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: OSCAWeatherStationCollectionViewCell.reuseIdentifier,
      for: indexPath) as? OSCAWeatherStationCollectionViewCell
    else { return UICollectionViewCell() }
    
    guard let weatherCell = viewModel.weatherObservedCells?[indexPath.row]
    else { return UICollectionViewCell() }
    
    cell.fill(with: weatherCell)
    
    return cell
  }
  
  public func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = collectionView.frame.size.width - 32
    let minWidth: CGFloat = 125
    let spacing: CGFloat = 8
    var cols: Int = 1
    for i in 1 ... 6 {
      let calcWidth = (width - ((CGFloat(cols) - 1) * spacing)) / CGFloat(cols)
      if calcWidth < minWidth {
        break
      }
      cols = i
    }
    let cellWidth = (width - ((CGFloat(cols) - 1) * spacing)) / CGFloat(cols)
    return CGSize(width: cellWidth, height: cellWidth)
  }
}

// MARK: - Deeplinking
extension OSCAWeatherStationViewController {
  private func selectItem(with index: Int) -> Void {
    
  }// end private func selectItem with index
  
  func didReceiveDeeplinkDetail(with objectId: String) -> Void {
    viewModel.didReceiveDeeplinkDetail(with: objectId)
  }// end func didReceiveDeeplinkDetail
}// extension final class OSCAWeatherStationViewController
