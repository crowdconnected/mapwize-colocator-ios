//
//  SettingsViewController.swift
//  Indoor Tracking Colocator
//
//  Created by TCode on 23/01/2020.
//  Copyright © 2020 Mobile Developer. All rights reserved.
//

import Foundation
import UIKit
import CCLocation

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var clientKeyTF: UITextField!
    @IBOutlet weak var serverSC: UISegmentedControl!
    @IBOutlet weak var deviceIDLabel: UILabel!
    
    @IBOutlet weak var mapwizeVenueTF: UITextField!
    @IBOutlet weak var mapwizeAPITF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
    }
    
    private func updateViews() {
        if let client = UserDefaults.standard.value(forKey: kClientKeyStorageKey) as? String {
            clientKeyTF.text = client
        } else {
            clientKeyTF.text = ""
        }
        
        if let servID = UserDefaults.standard.value(forKey: kServerIndexStorageKey) as? Int {
            serverSC.selectedSegmentIndex = servID
        } else {
            serverSC.selectedSegmentIndex = 0
        }
        
        if let venueID = UserDefaults.standard.value(forKey: kMapwizeVenueIDKey) as? String {
            mapwizeVenueTF.text = venueID
        } else {
            mapwizeVenueTF.text = ""
        }
        
        if let mapwizeAPIKey = UserDefaults.standard.value(forKey: kMapwizeAPIKey) as? String {
            mapwizeAPITF.text = mapwizeAPIKey
        } else {
            mapwizeAPITF.text = ""
        }
    }
    
    private func reconnectCCLocation() {
        // Default server is Staging
        let serverIndex = UserDefaults.standard.value(forKey: kServerIndexStorageKey) as? Int ?? 0
        
        guard let clientKey = UserDefaults.standard.value(forKey: kClientKeyStorageKey) as? String else {
                showAlert(message: "Colocator Client Key is missing")
                return
        }
        
        CCLocation.sharedInstance.stop()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if serverIndex == 0 {
                CCLocation.sharedInstance.start(apiKey: clientKey, urlString: kCCUrlStaging)
            } else if serverIndex == 1 {
                CCLocation.sharedInstance.start(apiKey: clientKey)
            } else {
                CCLocation.sharedInstance.start(apiKey: clientKey, urlString: kCCUrlDevelopment)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.actionGetDeviceID(self)
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func actionChangeClientKey(_ sender: Any) {
        if clientKeyTF.text?.count != 8 {
            showAlert(message: "The App Key seems incorrect")
            return
        }
        
        UserDefaults.standard.set(clientKeyTF.text!, forKey: kClientKeyStorageKey)
        reconnectCCLocation()
    }
    
    @IBAction func actionServerSC(_ sender: UISegmentedControl) {
        UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: kServerIndexStorageKey)
        reconnectCCLocation()
    }
    
    @IBAction func actionChangeMapwizeVenueID(_ sender: Any) {
        if let venueID = mapwizeVenueTF.text,
        venueID.count > 15 {
            UserDefaults.standard.set(venueID, forKey: kMapwizeVenueIDKey)
        } else {
            showAlert(message: "The Mapwize Venue ID seems incorrect")
        }
    }
    
    @IBAction func actionChangeMapwizeAPI(_ sender: Any) {
        if let newAPI = mapwizeAPITF.text,
            newAPI.count > 20 {
                UserDefaults.standard.set(newAPI, forKey: kMapwizeAPIKey)
        } else {
            showAlert(message: "The Mapwize API seems incorrect")
        }
    }
    
    @IBAction func actionGetDeviceID(_ sender: Any) {
        if let id = CCLocation.sharedInstance.getDeviceId() {
            self.deviceIDLabel.text = "\(id.uppercased())"
        }
    }
    
    @IBAction func actionBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
