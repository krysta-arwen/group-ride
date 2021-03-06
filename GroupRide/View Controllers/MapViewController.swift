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
    let uid = UserDefaults.standard.string(forKey: "uid")
    let db = Firestore.firestore()
    let geoFirestore = GeoFirestore(collectionRef: Firestore.firestore().collection("userLocations"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkUserLogin()
        
        //Set up location manager
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        
        //Round button
        locationButton.layer.cornerRadius = 5
        locationButton.clipsToBounds = true
        locationButton.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        
        //Set title
        if trackingLocation() {
            locationButton.setTitle("\(NSLocalizedString("trackingLocation", comment: ""))", for: .normal)
        } else {
            locationButton.setTitle("\(NSLocalizedString("trackLocation", comment: ""))", for: .normal)
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
            locationButton.setTitle("\(NSLocalizedString("trackLocation", comment: ""))", for: .normal)
            stopTrackingUserLocation()
            UserDefaults.standard.set(false, forKey: userDefaultsKey)
        }
        
    }
    
    //Show notification to allow location tracking
    func showLocationAlert(sender: UIButton) {
        let parameters = ["Email" : UserDefaults.standard.object(forKey: "Email")]
        Analytics.logEvent("enableLocationTracking", parameters: parameters)
        
        let alertController = UIAlertController(title: "\(NSLocalizedString("locationTracking", comment: ""))", message: "\(NSLocalizedString("enableLocationTracking", comment: ""))", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "\(NSLocalizedString("cancel", comment: ""))", style: .cancel) { (alert) in
            print("User tapped Cancel")
        }
        
        let settingsAction = UIAlertAction(title: "\(NSLocalizedString("settings", comment: ""))", style: .default, handler: { (alert) in
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
                
                let parameters = ["Email" : UserDefaults.standard.object(forKey: "Email")]
                Analytics.logEvent("noLocationAccess", parameters: parameters)
                
            case .authorizedAlways, .authorizedWhenInUse:
                print("Access")
            }
        } else {
            print("Location services are not enabled")
        }
    }
    
    //Show alert to enter ride name
    func showRideEntry(sender: UIButton) {
        let alertController = UIAlertController(title: "\(NSLocalizedString("rideName", comment: ""))", message: "\(NSLocalizedString("enterRideName", comment: ""))", preferredStyle: .alert)
        
        saveAction = UIAlertAction(title: "\(NSLocalizedString("save", comment: ""))", style: .default, handler: { (alert) in
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
            self.rideTextField.placeholder = "\(NSLocalizedString("rideNamePlaceholder", comment: ""))"
        }
        
        //Add notification to disable/enable save button
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object:alertController.textFields?[0], queue: OperationQueue.main) { (notification) -> Void in
            let textField = alertController.textFields?[0] as! UITextField
            self.saveAction.isEnabled = !textField.text!.isEmpty
        }
        
        let cancelAction = UIAlertAction(title: "\(NSLocalizedString("cancel", comment: ""))", style: .cancel)
        
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        
        alertController.popoverPresentationController?.sourceRect = sender.frame
        alertController.popoverPresentationController?.sourceView = view
        
        present(alertController, animated: true, completion: nil)
    }
    
    func trackUserLocation(rideName: String) {
        locationManager.startUpdatingLocation()
        
        //Create firestore document
        if let location = userLocation, let uid = uid {
            geoFirestore.setLocation(location: location, forDocumentWithID: uid)
            
            //Save rider's name and ride's name
            db.collection("users").document(uid).setData([
                "ride" : rideName,
                "username" : UserDefaults.standard.string(forKey: "Username")
            ]) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
            
            //Analytics
            let parameters = ["Email" : UserDefaults.standard.object(forKey: "Email"), "Ride Name" : rideName]
            Analytics.logEvent("trackingLocation", parameters: parameters)
            
            //Set button title
            locationButton.setTitle("\(NSLocalizedString("trackingLocation", comment: ""))", for: .normal)
            UserDefaults.standard.set(true, forKey: userDefaultsKey)
        } else {
            //Pop alert
            let alertController = UIAlertController(title: "\(NSLocalizedString("locationTracking", comment: ""))", message: "\(NSLocalizedString("unableToTrackLocation", comment: ""))", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
            
            //Analytics
            let parameters = ["Email" : UserDefaults.standard.object(forKey: "Email"), "Ride Error" : "\(NSLocalizedString("unableToTrackLocation", comment: ""))"]
            Analytics.logEvent("failedToTrackLocation", parameters: parameters)
            
            locationButton.setTitle("\(NSLocalizedString("trackLocation", comment: ""))", for: .normal)
            UserDefaults.standard.set(false, forKey: userDefaultsKey)
        }
    }
    
    func stopTrackingUserLocation() {
        let geoFirestoreRef = Firestore.firestore().collection("userLocations")
        let geoFirestore = GeoFirestore(collectionRef: geoFirestoreRef)
        
        if let uid = uid {
            //Remove location from collection
            geoFirestore.removeLocation(forDocumentWithID: uid)
            
            //Remove ride from collection
            db.collection("users").document(uid).updateData([
                "ride": FieldValue.delete()
                ]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        print("Document successfully updated")
                    }
            }
            
            //Analytics
            let parameters = ["Email" : UserDefaults.standard.object(forKey: "Email")]
            Analytics.logEvent("stoppedTrackingLocation", parameters: parameters)
            
            locationManager.stopUpdatingLocation()
        }
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
                if key != self.uid {
                    let bikeMarker = GMSMarker()
                    bikeMarker.icon = #imageLiteral(resourceName: "mapIcon")
                    self.getRideName(uid: key!, completion: { (ride) in
                        bikeMarker.title = ride
                    })
                    
                    self.getRiderName(uid: key!, completion: { (rider) in
                        bikeMarker.snippet = rider
                    })
                    bikeMarker.userData = key
                    bikeMarker.position = CLLocationCoordinate2D(latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!)
                    bikeMarker.map = self.mapView
                    self.mapMarkers.append(bikeMarker)
                }
            })
            
            //Observe exit
            let exitQueryHandle = circleQuery.observe(.documentExited, with: { (key, location) in
                if key != self.uid {
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
                
                if key != self.uid {
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
                    bikeMarker.icon = #imageLiteral(resourceName: "mapIcon")
                    self.getRideName(uid: key!, completion: { (ride) in
                        bikeMarker.title = ride
                    })
                    
                    self.getRiderName(uid: key!, completion: { (rider) in
                        bikeMarker.snippet = rider
                    })
                    bikeMarker.userData = key
                    bikeMarker.position = CLLocationCoordinate2D(latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!)
                    bikeMarker.map = self.mapView
                    self.mapMarkers.append(bikeMarker)
                }
            })
        }
        
    }
    
    func getRideName(uid: String, completion: @escaping (_ text: String) -> Void) {
        var ride = "\(NSLocalizedString("noRideProvided", comment: ""))"
        let docRef = db.collection("users").document(uid)
        
        docRef.getDocument { (document, error) in
            guard let document = document else {
                print("No document returned")
                completion(ride)
                return
            }
            
            if let dataDescription = document.data(), let rideName = dataDescription["ride"] {
                ride = rideName as! String
                completion(ride)
            }
        }
    }
    
    func getRiderName(uid: String, completion: @escaping (_ text: String) -> Void) {
        var rider = "\(NSLocalizedString("noUsernameProvided", comment: ""))"
        let docRef = db.collection("users").document(uid)
        
        docRef.getDocument { (document, error) in
            guard let document = document else {
                print("No document returned")
                completion(rider)
                return
            }
            
            if let dataDescription = document.data(), let riderName = dataDescription["username"]{
                rider = riderName as! String
                completion(rider)
            } else {
                print("Document does not exist in cache")
            }
        }
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
        
        userLocation = location
        
        if !queryAdded {
            observeQuery()
            queryAdded = true
        }

        if trackingLocation() {
            geoFirestore.setLocation(location: location, forDocumentWithID: uid!)
        } else {
            mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
            locationManager.stopUpdatingLocation()
        }
    }
}
