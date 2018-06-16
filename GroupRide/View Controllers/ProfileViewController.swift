//
//  SecondViewController.swift
//  GroupRide
//
//  Created by Krysta Deluca on 5/9/18.
//  Copyright © 2018 Krysta Deluca. All rights reserved.
//

import UIKit
import CoreData

class ProfileViewController: UIViewController, NSFetchedResultsControllerDelegate {
    var profiles = [Profile]()
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var rideLabel: UILabel!
    @IBOutlet weak var bikeLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    
    //Create fetched results controller object
    var fetchedResultsController: NSFetchedResultsController<Profile>?
    var blockOperations: [BlockOperation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        let managedContext = appDelegate.persistentContainer.viewContext
//        let indexPath = IndexPath(row: 1, section: 0)
//        
//        //Get all Person objects and sort by first name
//        let fetchRequest = NSFetchRequest<Profile>(entityName: "Profile")
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
//        
//        //Create results controller and pass request to it
//        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: "PersonsCache")
//        fetchedResultsController?.delegate = self
//        
//        do {
//            try fetchedResultsController?.performFetch()
//        } catch {
//            fatalError("Unable to fetch: \(error)")
//        }
        
        //Check if there is a saved profile and update labels if there is
        if checkEntity() {
            let userDefaults = UserDefaults.standard

            let name = userDefaults.object(forKey: "Name") as? String
            let username = userDefaults.object(forKey: "Username") as? String
            let description = userDefaults.object(forKey: "Description") as? String
            let bike = userDefaults.object(forKey: "Bike") as? String
            let ride = userDefaults.object(forKey: "Ride") as? String
            
            nameLabel.text = name
            usernameLabel.text = username
            descriptionLabel.text = description
            bikeLabel.text = bike
            rideLabel.text = ride
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if checkEntity() {
            let userDefaults = UserDefaults.standard
            
            let name = userDefaults.object(forKey: "Name") as? String
            let username = userDefaults.object(forKey: "Username") as? String
            let description = userDefaults.object(forKey: "Description") as? String
            let bike = userDefaults.object(forKey: "Bike") as? String
            let ride = userDefaults.object(forKey: "Ride") as? String
            
            nameLabel.text = name
            usernameLabel.text = username
            descriptionLabel.text = description
            bikeLabel.text = bike
            rideLabel.text = ride
        }
    }
    
    //Unwind segue for edit profile
    @IBAction func unwindWithSegue(_ segue: UIStoryboardSegue) { }
    
    //Check if there is a saved profile
    func checkEntity() -> Bool {
        return UserDefaults.standard.object(forKey: "Name") != nil
        
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        let managedObjectContext = appDelegate.persistentContainer.viewContext
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Profile")
//        fetchRequest.includesSubentities = false
//
//        var entitiesCount = 0
//
//        do {
//            entitiesCount = try managedObjectContext.count(for: fetchRequest)
//        }
//        catch {
//            print("error executing fetch request: \(error)")
//        }
//
//        return entitiesCount > 0
    }
}

