//
//  ViewController.swift
//  Colocator Mapwize iOS
//
//  Created by TCode on 21/02/2020.
//  Copyright © 2020 CrowdConnected. All rights reserved.
//

import UIKit
import CCLocation
import MapwizeUI

class ViewController: UIViewController {
    
    var map: MWZMapwizeView!
    var mapwizeApi: MWZMapwizeApi?
    let indoorLocationProvider = ILIndoorLocationProvider()

    var lastIndoorLocation: ILIndoorLocation? {
        didSet {
            if lastIndoorLocation != nil {
                map.followUserButton.isEnabled = true
            }
        }
    }
    
    let kFloorNumber = 0
    var locationManager: CLLocationManager!

    var mapLoadedSuccessfully = false
    var loadMapTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCCLocation()
        configureLocationProvider()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureMap()
        checkMapLoadingProcess()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        
        map = nil
        mapwizeApi = nil
    }
    
    private func configureCCLocation() {
        locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        
        let ccLocation = CCLocation.sharedInstance
        ccLocation.delegate = self
        ccLocation.registerLocationListener()
    }
    
    private func configureLocationProvider() {
        indoorLocationProvider?.addDelegate(self)
        indoorLocationProvider?.dispatchDidStart()
    }
    
    private func configureMap() {
        guard let mapwizeAPIKey = UserDefaults.standard.value(forKey: kMapwizeAPIKey) as? String,
            let mapwizeVenueID = UserDefaults.standard.value(forKey: kMapwizeVenueIDKey) as? String else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.sendUserToSettings()
                }
                
                return
        }
        
        let mapwizeConfiguration = MWZMapwizeConfiguration(apiKey: mapwizeAPIKey)
        mapwizeApi = MWZMapwizeApiFactory.getApi(mapwizeConfiguration:mapwizeConfiguration)
        
        let mapFrame = view.frame
        let mapUIOptions = MWZUIOptions()
        mapUIOptions.centerOnVenueId = mapwizeVenueID
        
        let mapUISettings = MWZMapwizeViewUISettings()
        mapUISettings.compassIsHidden = false
        mapUISettings.floorControllerIsHidden = false
        mapUISettings.menuButtonIsHidden = true
        mapUISettings.followUserButtonIsHidden = false
        
        map = MWZMapwizeView(frame: mapFrame,
                             mapwizeConfiguration: mapwizeConfiguration,
                             mapwizeOptions: mapUIOptions,
                             uiSettings: mapUISettings)
        map.delegate = self
        map.followUserButton.delegate = self
        
        // Disable followUser button until location is received from IndoorLocationProvider
        map.followUserButton.isEnabled = false
        
        view.addSubview(map)
        addSettingsButton()
    }
    
    private func sendUserToSettings() {
        guard let settingsVC = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") else {
            return
        }
        self.present(settingsVC, animated: true, completion: nil)
        
        let alert = UIAlertController(title: "First things first!",
                                      message: "Enter a Mapwize API key and a Venue ID to continue",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default))
        settingsVC.present(alert, animated: true, completion: nil)
    }
    
    private func addSettingsButton() {
        let settingsButton = UIButton(frame: CGRect(x: 200, y: 20, width: 150, height: 40))
        settingsButton.setTitle("SETTINGS", for: .normal)
        settingsButton.titleLabel?.font = UIFont.init(name: "HelveticaNeue-Medium", size: 16)
        settingsButton.tintColor = .clear
        settingsButton.setTitleColor(.purple, for: .normal)
        settingsButton.addTarget(self, action: #selector(actionSettings), for: .touchUpInside)
        
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(settingsButton)

        settingsButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 100).isActive = true
        settingsButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -3).isActive = true
        
        view.layoutIfNeeded()
    }
    
    private func checkMapLoadingProcess() {
        mapLoadedSuccessfully = false
        loadMapTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false, block: { _ in
            if !self.mapLoadedSuccessfully {
                let alert = UIAlertController(title: "We've got a problem!", message: "It seems like the map can't be loaded with the current Mapwize API Key", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in }))
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    @objc private func actionSettings() {
        guard let settingsVC = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") else {
            return
        }
        self.present(settingsVC, animated: true, completion: nil)
    }
}

extension ViewController: ILIndoorLocationProviderDelegate {
    func provider(_ provider: ILIndoorLocationProvider!, didUpdate location: ILIndoorLocation!) { }
    
    func provider(_ provider: ILIndoorLocationProvider!, didFailWithError error: Error!) { }
    
    func providerDidStart(_ provider: ILIndoorLocationProvider!) { }
    
    func providerDidStop(_ provider: ILIndoorLocationProvider!) { }
}

extension ViewController: MWZComponentFollowUserButtonDelegate {
    func didTapWithoutLocation() { }
    
    func followUserButton(_ followUserButton: MWZComponentFollowUserButton!, didChange followUserMode: MWZFollowUserMode) {
        map.mapView.setFollowUserMode(followUserMode)
    }
    
    func followUserButtonRequiresUserLocation(_ followUserButton: MWZComponentFollowUserButton!) -> ILIndoorLocation! {
        return lastIndoorLocation
    }
    
    func followUserButtonRequiresFollowUserMode(_ followUserButton: MWZComponentFollowUserButton!) -> MWZFollowUserMode {
        return .followUserAndHeading
    }
}

extension ViewController: MWZMapwizeViewDelegate {
    func mapwizeViewDidLoad(_ mapwizeView: MWZMapwizeView!) {
        map.setIndoorLocationProvider(indoorLocationProvider!)
        mapLoadedSuccessfully = true
    }
    
    func mapwizeView(_ mapwizeView: MWZMapwizeView!, didTapOnPlaceInformationButton place: MWZPlace!) { }
    
    func mapwizeView(_ mapwizeView: MWZMapwizeView!, didTapOnPlaceListInformationButton placeList: MWZPlacelist!) { }

    func mapwizeViewDidTap(onFollowWithoutLocation mapwizeView: MWZMapwizeView!) { }

    func mapwizeViewDidTap(onMenu mapwizeView: MWZMapwizeView!) { }

    func mapwizeView(_ mapwizeView: MWZMapwizeView!, shouldShowInformationButtonFor mapwizeObject: MWZObject!) -> Bool {
        if (mapwizeObject is MWZPlace) {
            return true
        }
        return false
    }

    func mapwizeView(_ mapwizeView: MWZMapwizeView!, shouldShowFloorControllerFor floors: [MWZFloor]!) -> Bool {
        if (floors.count > 1) {
            return true
        }
        return false
    }
}

extension ViewController: CCLocationDelegate {
    func didFailToUpdateCCLocation() { }
    
    func ccLocationDidConnect() { }
    
    func ccLocationDidFailWithError(error: Error) { }
    
    func didReceiveCCLocation(_ location: LocationResponse) {
        lastIndoorLocation = ILIndoorLocation(provider: indoorLocationProvider,
                                              latitude: location.latitude,
                                              longitude: location.longitude,
                                              floor: kFloorNumber as NSNumber)
        indoorLocationProvider?.dispatchDidUpdate(lastIndoorLocation)
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) { }
}
