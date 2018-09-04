//
//  FirstViewController.swift
//  GroupRide
//
//  Created by Krysta Deluca on 5/9/18.
//  Copyright © 2018 Krysta Deluca. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase
import Geofirestore

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var buttonTopConstraint: NSLayoutConstraint!
    
    private let locationManager = CLLocationManager()
    let userDefaultsKey = "TrackingLocation"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set up location manager
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        //Add gesture recognizer to view controller
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(swipeRight)
        
        //Round button
        locationButton.layer.cornerRadius = 5
        locationButton.clipsToBounds = true
        locationButton.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        
        //Set title
        if trackingLocation() {
            locationButton.setTitle("Track Location", for: .normal)
        } else {
            locationButton.setTitle("Tracking Location", for: .normal)
        }
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func trackLocationTapped(_ sender: UIButton) {
        sender.pulse()
        
        if !trackingLocation() {
            checkLocationTrackingAuthorization(sender: sender)
            UserDefaults.standard.set(true, forKey: userDefaultsKey)
            trackUserLocation()
        } else {
            locationButton.setTitle("Track Location", for: .normal)
            UserDefaults.standard.set(false, forKey: userDefaultsKey)
        }
        
    }
    
    //Show notification to turn location tracking on
    func showLocationAlert(sender: UIButton) {
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
    
    func checkLocationTrackingAuthorization(sender: UIButton) {
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                print("No access")
                showLocationAlert(sender: sender)
                
            case .authorizedAlways, .authorizedWhenInUse:
                print("Access")
                locationButton.setTitle("Tracking Location", for: .normal)
                UserDefaults.standard.set(true, forKey: userDefaultsKey)
            }
        } else {
            print("Location services are not enabled")
        }
    }
    
    func trackUserLocation() {
        //Create firestore reference
        let geoFirestoreRef = Firestore.firestore().collection("userLocations")
        let geoFirestore = GeoFirestore(collectionRef: geoFirestoreRef)
        
        if let location = locationManager.location, let uid = UserDefaults.standard.string(forKey: "uid") {
            geoFirestore.setLocation(location: location, forDocumentWithID: uid)

        } else {
            let alertController = UIAlertController(title: "Location Tracking", message: "Unable to track your location at this time.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
            
            locationButton.setTitle("Track Location", for: .normal)
            UserDefaults.standard.set(false, forKey: userDefaultsKey)
        }
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                break
            case UISwipeGestureRecognizerDirection.left:
                self.tabBarController
            default:
                break
            }
        }
    }
    
    func trackingLocation() -> Bool {
        return UserDefaults.standard.bool(forKey: userDefaultsKey)
    }
}

extension UIButton {
    
    func pulse() {
        //Add pulse action
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.duration = 0.3
        pulse.fromValue = 0.97
        pulse.toValue = 1.0
        pulse.autoreverses = true
        pulse.repeatCount = 1
        pulse.initialVelocity = 0.3
        pulse.damping = 1.0
        layer.add(pulse, forKey: nil)
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
