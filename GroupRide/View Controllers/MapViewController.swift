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
    var queryAdded = false
    var rideTextField: UITextField!
    var saveAction: UIAlertAction!
    var userLocation: CLLocation!
    var circleQuery: GFSQuery!
    var mapMarkers: [GMSMarker]!
    

    private let locationManager = CLLocationManager()
    
    let userDefaultsKey = "TrackingLocation"
    let db = Firestore.firestore()
    let geoFirestore = GeoFirestore(collectionRef: Firestore.firestore().collection("userLocations"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkUserLogin()
        
        //Set up location manager
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.allowsBackgroundLocationUpdates = true
        
        //Round button
        locationButton.layer.cornerRadius = 5
        locationButton.clipsToBounds = true
        locationButton.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        
        //Set title
        if trackingLocation() {
            locationButton.setTitle("Tracking Location", for: .normal)
        } else {
            locationButton.setTitle("Track Location", for: .normal)
        }
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        mapMarkers = []
    }

    func checkUserLogin() {
        if Auth.auth().currentUser == nil {
            //Return to log in page
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window = UIWindow(frame: UIScreen.main.bounds)
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let rootViewController = mainStoryboard.instantiateViewController(withIdentifier: "logInNavigation")
            
            appDelegate.window!.rootViewController = rootViewController
            appDelegate.window!.makeKeyAndVisible()
            
            UserDefaults.standard.set(false, forKey: "LoggedIn")
            UserDefaults.standard.synchronize()
        }
    }
    
    @IBAction func trackLocationTapped(_ sender: UIButton) {
        sender.pulse()
        
        if !trackingLocation() {
            checkLocationTrackingAuthorization(sender: sender)
            showRideEntry(sender: sender)
        } else {
            locationButton.setTitle("Track Location", for: .normal)
            stopTrackingUserLocation()
            UserDefaults.standard.set(false, forKey: userDefaultsKey)
        }
        
    }
    
    //Show notification to allow location tracking
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
            }
        } else {
            print("Location services are not enabled")
        }
    }
    
    //Show alert to enter ride name
    func showRideEntry(sender: UIButton) {
        let alertController = UIAlertController(title: "Ride Name", message: "To track your ride, please enter the name of the ride", preferredStyle: .alert)
        
        saveAction = UIAlertAction(title: "Save", style: .default, handler: { (alert) in
            guard let textField = self.rideTextField else {
                return;
            }
            
            //Start tracking location if user entered ride name
            if let name = textField.text {
                self.trackUserLocation(rideName: name)
            }
        })
        
        saveAction.isEnabled = false
        
        alertController.addTextField { (textField) in
            self.rideTextField = textField
            self.rideTextField.placeholder = "Ride Name..."
        }
        
        //Add notification to disable/enable save button
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object:alertController.textFields?[0], queue: OperationQueue.main) { (notification) -> Void in
            let textField = alertController.textFields?[0] as! UITextField
            self.saveAction.isEnabled = !textField.text!.isEmpty
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        
        alertController.popoverPresentationController?.sourceRect = sender.frame
        alertController.popoverPresentationController?.sourceView = view
        
        present(alertController, animated: true, completion: nil)
    }
    
    func trackUserLocation(rideName: String) {
        let username = UserDefaults.standard.string(forKey: "Username")
        
//        locationManager.startUpdatingLocation()
        
        //Create firestore document
        if let location = userLocation, let uid = UserDefaults.standard.string(forKey: "uid") {
            geoFirestore.setLocation(location: location, forDocumentWithID: uid)
            
            //Save rider's name and ride's name
            db.collection("userLocations").document(uid).setData([
                "username" : username!,
                "ride" : rideName
            ], merge: true) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
            
            //Set button title
            locationButton.setTitle("Tracking Location", for: .normal)
            UserDefaults.standard.set(true, forKey: userDefaultsKey)
        } else {
            //Pop alert
            let alertController = UIAlertController(title: "Location Tracking", message: "Unable to track your location at this time.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
            
            locationButton.setTitle("Track Location", for: .normal)
            UserDefaults.standard.set(false, forKey: userDefaultsKey)
        }
    }
    
    func stopTrackingUserLocation() {
        let geoFirestoreRef = Firestore.firestore().collection("userLocations")
        let geoFirestore = GeoFirestore(collectionRef: geoFirestoreRef)
        
        if let uid = UserDefaults.standard.string(forKey: "uid") {
            //Remove location from collection
            geoFirestore.removeLocation(forDocumentWithID: uid)
            
            //Remove username and ride from collection
            db.collection("userLocations").document(uid).updateData([
                "username": FieldValue.delete(),
                "ride": FieldValue.delete()
                ]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        print("Document successfully updated")
                    }
            }
        }
        
        locationManager.stopUpdatingLocation()
    }
    
    //Check if user is currently tracking location
    func trackingLocation() -> Bool {
        return UserDefaults.standard.bool(forKey: userDefaultsKey)
    }
    
    func observeQuery() {
        // Query using CLLocation
        if let userLocation = userLocation {
            circleQuery = geoFirestore.query(withCenter: userLocation, radius: 48.5)
            
            //Observe key entry
            let entryQueryHandle = circleQuery.observe(.documentEntered, with: { (key, location) in
                print("The document with documentID '\(key)' entered the search area and is at location '\(location)'")
                
                if key != UserDefaults.standard.string(forKey: "uid") {
                    let bikeMarker = GMSMarker()
                    bikeMarker.title = self.getRiderName(uid: key!)
                    bikeMarker.snippet = self.getRideName(uid: key!)
                    bikeMarker.userData = key
                    bikeMarker.position = CLLocationCoordinate2D(latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!)
                    bikeMarker.map = self.mapView
                    self.mapMarkers.append(bikeMarker)
                }
            })
            
            //Observe exit
            let exitQueryHandle = circleQuery.observe(.documentExited, with: { (key, location) in
                print("The document with documentID '\(key)' entered the search area and is at location '\(location)'")
                
                if key != UserDefaults.standard.string(forKey: "uid") {
                    if let mapMarkers = self.mapMarkers {
                        for marker in mapMarkers {
                            if marker.userData as! String == key {
                                let index = mapMarkers.index(of: marker)
                                marker.map = nil
                                self.mapMarkers.remove(at: index!)
                            }
                        }
                    }
                }
            })
            
            //Observe moving
            let moveQueryHandle = circleQuery.observe(.documentMoved, with: { (key, location) in
                print("The document with documentID '\(key)' entered the search area and is at location '\(location)'")
                
                if key != UserDefaults.standard.string(forKey: "uid") {
                    //Remove previous marker
                    if let mapMarkers = self.mapMarkers {
                        for marker in mapMarkers {
                            if marker.userData as! String == key {
                                let index = mapMarkers.index(of: marker)
                                marker.map = nil
                                self.mapMarkers.remove(at: index!)
                            }
                        }
                    }
                    
                    //Add new marker
                    let bikeMarker = GMSMarker()
                    bikeMarker.title = self.getRiderName(uid: key!)
                    bikeMarker.snippet = self.getRideName(uid: key!)
                    bikeMarker.userData = key
                    bikeMarker.position = CLLocationCoordinate2D(latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!)
                    bikeMarker.map = self.mapView
                    self.mapMarkers.append(bikeMarker)
                }
            })
        }
        
    }
    
    func getRideName(uid: String) -> String {
        var ride = "No ride provided"
        let docRef = db.collection("userLocations").document(uid)
        
        docRef.getDocument { (document, error) in
            guard let document = document else {
                print("No document returned")
                return
            }
            
            let dataDescription = document.data()
            print(dataDescription!["ride"])
            ride = dataDescription!["ride"] as! String
        }
        
        return ride
    }
    
    func getRiderName(uid: String) -> String {
        var rider = "No username provided"
        let docRef = db.collection("userLocations").document(uid)
        
        docRef.getDocument { (document, error) in
            guard let document = document else {
                print("No document returned")
                return
            }
            
            if let dataDescription = document.data() {
                rider = dataDescription["username"] as! String
            } else {
                print("Document does not exist in cache")
            }
        }
        
        return rider
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
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
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
        
//        if let query = circleQuery {
//            circleQuery.removeAllObservers()
//        }
        
        userLocation = location
        
        if !queryAdded {
            observeQuery()
            queryAdded = true
        }

        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        
        locationManager.stopUpdatingLocation()
    }
}
