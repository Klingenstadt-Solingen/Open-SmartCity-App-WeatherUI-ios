//
//  OSCAWeatherStationSelectionViewController.swift
//  OSCAWeatherUI
//

import OSCAEssentials
import OSCAWeather
import UIKit
import Combine
import MapKit
import CoreLocation

public final class OSCAWeatherListViewController: UIViewController, StoryboardInstantiable, UITextFieldDelegate, MKMapViewDelegate, UICollectionViewDelegate, ActivityIndicatable, Alertable, UITableViewDelegate {
    
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var tableHeaderView: UIView!
    
    public var activityIndicatorView: ActivityIndicatorView = ActivityIndicatorView(style: .large)
    
    @IBOutlet private var mapViewContainer: UIView!
    @IBOutlet private var mapView: MKMapView!
    
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet var collectionViewHeightConstraint: NSLayoutConstraint!
    
    private typealias DataSource = UICollectionViewDiffableDataSource<OSCAWeatherListViewModel.Section, OSCAWeatherObserved>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<OSCAWeatherListViewModel.Section, OSCAWeatherObserved>
    
    
    private var viewModel: OSCAWeatherListViewModel!
    private var bindings = Set<AnyCancellable>()
    
    private var dataSource: DataSource!
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupBindings()
        viewModel.viewDidLoad()
    }
    
    public var didLoadContent   : ((Int) -> Void)?
    
    public func refreshContent() {
        self.viewModel.refreshContent()
    }
    
    
    private func setupViews() {
        configureDataSource()
        setupMapView()
        setupCollectionView()
    }
    private func setupMapView() {
        mapView.delegate = self
        tableView.delegate = self
        
        tableHeaderView.backgroundColor =  OSCAWeatherUI.configuration.colorConfig.backgroundColor
        tableView.backgroundColor =  OSCAWeatherUI.configuration.colorConfig.backgroundColor
        
        self.navigationItem.title = viewModel.screenTitle
        
        mapView.layer.cornerRadius = OSCAWeatherUI.configuration.cornerRadius
        mapView.backgroundColor =  OSCAWeatherUI.configuration.colorConfig.backgroundColor
        
        zoomToAnnotations(mapView: self.mapView, annotations: self.viewModel.weatherObservedAnnotations)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateLocation),
            name: .userLocationDidChange,
            object: nil)
        self.view.backgroundColor = OSCAWeatherUI.configuration.colorConfig.backgroundColor
    }
    
    private func setupCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.backgroundColor =  OSCAWeatherUI.configuration.colorConfig.backgroundColor
        if #available(iOS 17.4, *) {
            self.collectionView.bouncesHorizontally = false
            self.tableView.bouncesHorizontally = false
            self.collectionView.bouncesVertically = true
            self.tableView.bouncesVertically = true
        }
        
        self.collectionView.showsHorizontalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false
        
        let identifier: String  = OSCAWeatherListClassicCellView.identifier
        let nib = UINib(nibName: identifier, bundle: OSCAWeatherUI.bundle)
        self.collectionView.register(nib,
                                     forCellWithReuseIdentifier: identifier)
        
        self.collectionView.collectionViewLayout = self.createLayout()
        self.collectionViewHeightConstraint.constant = 150
        self.collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let height = OSCAWeatherUI.configuration.stationWidget.itemHeight
        let section: NSCollectionLayoutSection
        
        let columns: Int = 3
        let spacing: CGFloat = 8
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.298),
                                              heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: .flexible(3), top: nil,
                                                         trailing: .flexible(3), bottom: nil)
        
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
        
        section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        
        var layout = UICollectionViewCompositionalLayout(section: section)
        layout.configuration.scrollDirection = .vertical
        
        
        return layout
    }
    
    
    private func setupBindings() {
        viewModel.$allWeatherObserved
            .receive(on: RunLoop.main)
            .dropFirst()
            .sink(receiveValue: { [weak self] allWeatherObserved in
                guard let `self` = self else { return }
                
                let annotations = self.mapView.annotations
                if !annotations.isEmpty {
                    self.mapView.removeAnnotations(annotations)
                }
                self.mapView.addAnnotations(self.viewModel.weatherObservedAnnotations)
                
                self.zoomToAnnotations(mapView: self.mapView, annotations: self.mapView.annotations)
                
                self.updateSections(allWeatherObserved)
            })
            .store(in: &bindings)
        
        
        let startLoading = {
            self.collectionView.isUserInteractionEnabled = false
            self.showActivityIndicator()
        }
        
        let finishLoading = {
            self.collectionView.isUserInteractionEnabled = true
            self.hideActivityIndicator()
            self.view.layoutIfNeeded()
        }
        
        let stateValueHandler: (OSCAWeatherListViewModelState) -> Void = { [weak self] state in
            guard let _ = self else { return }
            
            switch state {
            case .loading:
                startLoading()
                
            case .finishedLoading:
                finishLoading()
                
            case let .error(error):
                finishLoading()
                self?.showAlert(
                    title: self?.viewModel.alertTitleError ?? "",
                    message: error.localizedDescription,
                    actionTitle: self?.viewModel.alertActionConfirm ?? "")
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
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
    
    
    private func updateSections(_ weatherObserved: [OSCAWeatherObserved]) {
        configureDataSource()
        var snapshot = Snapshot()
        snapshot.appendSections([.allWeatherObserved])
        snapshot.appendItems(weatherObserved)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    @objc private func updateLocation() {
        viewModel.updateLocation()
    }
    
    public static func create(with viewModel: OSCAWeatherListViewModel) -> OSCAWeatherListViewController {
        let vc = Self.instantiateViewController(OSCAWeatherUI.bundle)
        vc.viewModel = viewModel
        return vc
    }
    
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
        self.viewModel.didSelectItem(annotation.objectId!)
        dismiss(animated: true, completion: nil)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        self.viewModel.didSelectItem(at: indexPath.item)
        dismiss(animated: true, completion: nil)
    }
    
    private func configureDataSource() -> Void {
        self.dataSource = DataSource(
            collectionView: self.collectionView,
            cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: OSCAWeatherListClassicCellView.identifier,
                    for: indexPath) as? OSCAWeatherListClassicCellView
                else { return UICollectionViewCell() }
                
                cell.viewModel = OSCAWeatherListClassicCellViewModel(
                    weatherStation: item)
                
                return cell
            })
    }
    
    
}
