//
//  FirstViewController.swift
//  GroupRide
//
//  Created by Krysta Deluca on 5/9/18.
//  Copyright © 2018 Krysta Deluca. All rights reserved.
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var locationSwitch: UISwitch!
    
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Reports user location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func locationTrackingChanged(_ sender: UISwitch) {
        if locationSwitch.isOn {
            checkLocationTrackingAuthorization(sender: sender)
        }
    }
    
    //Show notification to turn location tracking on
    func showLocationAlert(sender: UISwitch) {
        let alertController = UIAlertController(title: "Location Tracking", message: "To track your ride, you must enable location tracking in Settings", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in
            print("User tapped Cancel")
        }
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { (alert) in
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(appSettings)
            }
        })
        
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        
        alertController.popoverPresentationController?.sourceRect = sender.frame
        alertController.popoverPresentationController?.sourceView = view
        
        present(alertController, animated: true, completion: nil)
    }
    
    func checkLocationTrackingAuthorization(sender: UISwitch) {
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                print("No access")
                showLocationAlert(sender: sender)
                locationSwitch.setOn(false, animated: true)
                
            case .authorizedAlways, .authorizedWhenInUse:
                print("Access")
            }
        } else {
            print("Location services are not enabled")
        }
    }
}

//Conform map view controller to protocol
extension MapViewController: CLLocationManagerDelegate {
    //User changes location permission
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        locationManager.startUpdatingLocation()
        
        //Adds blue dot for current location and centering on user's location
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    
    //User moves
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        
        locationManager.stopUpdatingLocation()
    }
}
