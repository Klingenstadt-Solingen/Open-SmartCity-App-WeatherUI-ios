//
//  OSCAWeatherStationSelectionViewController.swift
//  OSCAWeatherUI
//
//  Created by Ömer Kurutay on 12.04.22.
//

import OSCAEssentials
import OSCAWeather
import UIKit
import Combine
import MapKit
import CoreLocation

public final class OSCAWeatherStationSelectionViewController: UIViewController {
  
  @IBOutlet private var tableHeaderView: UIView!
  @IBOutlet private var mapViewContainer: UIView!
  @IBOutlet private var mapView: MKMapView!
  @IBOutlet private var tableView: UITableView!
  
  private let searchController = UISearchController(searchResultsController: nil)
  
  private typealias DataSource = UITableViewDiffableDataSource<OSCAWeatherStationSelectionViewModel.Section, OSCAWeatherObserved>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<OSCAWeatherStationSelectionViewModel.Section, OSCAWeatherObserved>
  
  private var viewModel: OSCAWeatherStationSelectionViewModel!
  private var bindings = Set<AnyCancellable>()
  
  private var dataSource: DataSource!
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    setupBindings()
    viewModel.viewDidLoad()
  }
  
  private func setupViews() {
    self.view.backgroundColor = OSCAWeatherUI.configuration.colorConfig.backgroundColor
    
    mapView.delegate = self
    tableView.delegate = self
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(updateLocation),
      name: .userLocationDidChange,
      object: nil)
    
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.placeholder = viewModel.searchPlaceholder
    self.navigationItem.searchController = searchController
    self.navigationItem.title = viewModel.screenTitle
    
    if let textfield = searchController.searchBar.value(forKey: "searchField") as? UITextField {
      textfield.font = OSCAWeatherUI.configuration.fontConfig.bodyLight
      textfield.textColor = OSCAWeatherUI.configuration.colorConfig.blackColor
      textfield.tintColor = OSCAWeatherUI.configuration.colorConfig.navigationTintColor
      textfield.backgroundColor = OSCAWeatherUI.configuration.colorConfig.grayLight
      textfield.leftView?.tintColor = OSCAWeatherUI.configuration.colorConfig.grayDarker
      textfield.returnKeyType = .done
      textfield.keyboardType = .default
      textfield.enablesReturnKeyAutomatically = false
      textfield.delegate = self
      
      if let clearButton = textfield.value(forKey: "_clearButton") as? UIButton {
        let templateImage = clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
        clearButton.setImage(templateImage, for: .normal)
        clearButton.tintColor = OSCAWeatherUI.configuration.colorConfig.grayDarker
      }
      
      if let label = textfield.value(forKey: "placeholderLabel") as? UILabel {
        label.attributedText = NSAttributedString(
          string: viewModel.searchPlaceholder,
          attributes: [.foregroundColor: OSCAWeatherUI.configuration.colorConfig.grayDarker])
      }
    }
    
    tableHeaderView.backgroundColor = .clear
    
    mapViewContainer.layer.cornerRadius = OSCAWeatherUI.configuration.cornerRadius
    mapViewContainer.addShadow(with: OSCAWeatherUI.configuration.shadow)
    
    mapView.layer.cornerRadius = OSCAWeatherUI.configuration.cornerRadius
    
    tableView.backgroundColor = .clear
    
    zoomToAnnotations(mapView: self.mapView, annotations: self.viewModel.weatherObservedAnnotations)
  }
  
  private func setupBindings() {
    viewModel.$currentWeatherObserved
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] currentWeatherObserved in
        guard let `self` = self else { return }
        
        let annotations = self.mapView.annotations
        if !annotations.isEmpty {
          self.mapView.removeAnnotations(annotations)
        }
        self.mapView.addAnnotations(self.viewModel.weatherObservedAnnotations)
        
        let annotation = annotations.first(where: {
          guard let objectId = ($0 as? OSCAMapAnnotation)?.objectId
          else { return false }
          return objectId == self.viewModel.selectedWeatherObservedAnnotation?.objectId
        })
        
        if let annotation = annotation {
          self.mapView.selectAnnotation(annotation,
                                        animated: true)
        }
        
        self.updateSections(currentWeatherObserved)
      })
      .store(in: &bindings)
    
    viewModel.$selectedWeatherObserved
      .receive(on: RunLoop.main)
      .sink(receiveValue: { [weak self] selectedWeatherObserved in
        guard let `self` = self else { return }
        
        self.zoomToAnnotations(mapView: self.mapView, annotations: self.mapView.annotations)
        let annotation = self.mapView.annotations.first(where: {
          guard let objectId = ($0 as? OSCAMapAnnotation)?.objectId
          else { return false }
          return objectId == self.viewModel.selectedWeatherObservedAnnotation?.objectId
        })
        
        if let annotation = annotation {
          self.mapView.selectAnnotation(annotation,
                                        animated: true)
        }
        
        self.tableView.reloadData()
      })
      .store(in: &bindings)
    
    let stateValueHandler: (OSCAWeatherStationSelectionViewModelState) -> Void = { [weak self] state in
      guard let _ = self else { return }
      
      switch state {
      case .error(.weatherObservedFetch):
        print("Error: Could not fetch weather data.")
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
    self.navigationController?.setup(
      largeTitles: true,
      tintColor: OSCAWeatherUI.configuration.colorConfig.navigationTintColor,
      titleTextColor: OSCAWeatherUI.configuration.colorConfig.navigationTitleTextColor,
      barColor: OSCAWeatherUI.configuration.colorConfig.navigationBarColor)
    registerForKeyboardNotifications()
  }
  
  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    deregisterFromKeyboardNotifications()
  }
  
  private func zoomToAnnotations(mapView: MKMapView, annotations: [MKAnnotation]) {
      var zoomRect = MKMapRect.null

      annotations.forEach { annotation in
          let annotationPoint = MKMapPoint(annotation.coordinate)
          let pointRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 100, height: 200)

          if zoomRect.isNull {
              zoomRect = pointRect
          } else {
              zoomRect = zoomRect.union(pointRect)
          }
      }

      mapView.setVisibleMapRect(zoomRect, edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: true)
  }
  
  private func registerForKeyboardNotifications(){
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillAppear(notification:)),
      name: UIResponder.keyboardWillShowNotification,
      object: nil)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillDisappear(notification:)),
      name: UIResponder.keyboardWillHideNotification,
      object: nil)
  }
  
  private func deregisterFromKeyboardNotifications(){
    NotificationCenter.default.removeObserver(
      self,
      name: UIResponder.keyboardWillShowNotification,
      object: nil)
    NotificationCenter.default.removeObserver(
      self,
      name: UIResponder.keyboardWillHideNotification,
      object: nil)
  }
  
  private func updateSections(_ weatherObserved: [OSCAWeatherObserved]) {
    configureDataSource()
    var snapshot = Snapshot()
    snapshot.appendSections([.weatherObserved])
    snapshot.appendItems(weatherObserved)
    dataSource.apply(snapshot, animatingDifferences: true)
  }
  
  @objc private func keyboardWillAppear(notification: NSNotification) {
    self.tableView.isScrollEnabled = true
    let info = notification.userInfo!
    let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
    var adjustedHeight = keyboardSize!.height
    if let tabbarSize = tabBarController?.tabBar.frame.size {
      adjustedHeight = keyboardSize!.height - tabbarSize.height
    }
    
    let contentInsets = UIEdgeInsets(top: 0.0,
                                     left: 0.0,
                                     bottom: adjustedHeight,
                                     right: 0.0)
    
    self.tableView.contentInset = contentInsets
    self.tableView.scrollIndicatorInsets = contentInsets
  }
  
  @objc private func keyboardWillDisappear(notification: NSNotification) {
    let contentInsets: UIEdgeInsets = .zero
    self.tableView.contentInset = contentInsets
    self.tableView.scrollIndicatorInsets = contentInsets
  }
  
  @objc private func updateLocation() {
    viewModel.updateLocation()
  }
}

// MARK: - instantiate view conroller
extension OSCAWeatherStationSelectionViewController: StoryboardInstantiable {
  public static func create(with viewModel: OSCAWeatherStationSelectionViewModel) -> OSCAWeatherStationSelectionViewController {
    let vc = Self.instantiateViewController(OSCAWeatherUI.bundle)
    vc.viewModel = viewModel
    return vc
  }
}

extension OSCAWeatherStationSelectionViewController: UISearchResultsUpdating {
  public func updateSearchResults(for searchController: UISearchController) {
    guard let text = searchController.searchBar.text else { return }
    viewModel.updateSearchResults(for: text)
  }
}

extension OSCAWeatherStationSelectionViewController: UITextFieldDelegate {
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    searchController.isActive = false
    return true
  }
}

extension OSCAWeatherStationSelectionViewController {
  private func configureDataSource() -> Void {
    dataSource = DataSource(
      tableView: tableView,
      cellProvider: { (tableView, indexPath, weatherObserved) -> UITableViewCell in
        guard let cell = tableView.dequeueReusableCell(
          withIdentifier: OSCAWeatherStationSelectionTableViewCell.identifier,
          for: indexPath) as? OSCAWeatherStationSelectionTableViewCell
        else { return UITableViewCell() }
        
        cell.fill(
          with: weatherObserved,
          selectedWeatherObserved: self.viewModel.selectedWeatherObserved,
          userLocation: self.viewModel.userLocation,
          indexPath: indexPath)
        
        return cell
      })
  }
}

extension OSCAWeatherStationSelectionViewController: MKMapViewDelegate {
  public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard let annotation = annotation as? OSCAMapAnnotation else { return nil }
    
    let identifier = "Annotation"
    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
    
    if annotationView == nil {
      annotationView = MKMarkerAnnotationView(annotation: annotation,
                                              reuseIdentifier: identifier)
      annotationView!.canShowCallout = true
    } else {
      annotationView!.annotation = annotation
    }
    annotationView!.markerTintColor = OSCAWeatherUI.configuration.colorConfig.primaryColor
    
    return annotationView
  }
  
  public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    guard let annotation = view.annotation as? OSCAMapAnnotation else { return }
    viewModel.didSelectAnnotation(annotation)
  }
}

extension OSCAWeatherStationSelectionViewController: UITableViewDelegate {
  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    viewModel.didSelectItem(at: indexPath.row)
  }
}
