//
//  EditProfileViewController.swift
//  GroupRide
//
//  Created by Krysta Deluca on 6/11/18.
//  Copyright © 2018 Krysta Deluca. All rights reserved.
//

import UIKit
import CoreData

class EditProfileViewController: UIViewController, UITextFieldDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var rideTextField: UITextField!
    @IBOutlet weak var bikeTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    var textLimitLength = 20
    var profiles = [Profile]()
    
    //Create fetched results controller object
    var fetchedResultsController: NSFetchedResultsController<Profile>?
    var blockOperations: [BlockOperation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Set border for text view
        let borderColor : UIColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        descriptionTextView.layer.borderWidth = 0.5
        descriptionTextView.layer.borderColor = borderColor.cgColor
        descriptionTextView.layer.cornerRadius = 5.0
        
        //Set text fields as delegate
        nameTextField.delegate = self
        usernameTextField.delegate = self
        rideTextField.delegate = self
        bikeTextField.delegate = self
        
//        Core Data Stuff
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        let managedContext = appDelegate.persistentContainer.viewContext
//        let indexPath = IndexPath(row: 0, section: 0)
//
//        //Get all Person objects and sort ny first name
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
            
            nameTextField.text = name
            usernameTextField.text = username
            descriptionTextView.text = description
            bikeTextField.text = bike
            rideTextField.text = ride
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        switch textField {
        case nameTextField:
            textLimitLength = 35
        case usernameTextField:
            textLimitLength = 15
        case rideTextField:
            textLimitLength = 20
        case bikeTextField:
            textLimitLength = 20
        default:
            break
        }
        
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= textLimitLength
    }

    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        //If there are any empty fields, don't exit view
        if textFieldCheck() {
            let userDefaults = UserDefaults.standard
            userDefaults.set(nameTextField.text, forKey: "Name")
            userDefaults.set(usernameTextField.text, forKey: "Username")
            userDefaults.set(rideTextField.text, forKey: "Ride")
            userDefaults.set(bikeTextField.text, forKey: "Bike")
            userDefaults.set(descriptionTextView.text, forKey: "Description")
            
//            //Save to core data
//            let appDelegate = UIApplication.shared.delegate as! AppDelegate
//            let context = appDelegate.persistentContainer.viewContext
//            let entity = NSEntityDescription.entity(forEntityName: "Profile", in: context)
//
//            let profile = Profile(entity: entity!, insertInto: context)
//            profile.name = nameTextField.text
//            profile.username = usernameTextField.text
//            profile.ride = rideTextField.text
//            profile.bike = bikeTextField.text
//            profile.profileDescription = descriptionTextView.text
//            appDelegate.saveContext()
            
            performSegue(withIdentifier: "returnToProfile", sender: self)
        }
    }

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "returnToProfile", sender: self)
    }
    
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
    
    //Check if any fields are empty and pop alert
    func textFieldCheck() -> Bool {
        if nameTextField.text?.isEmpty ?? true {
            emptyFieldAlert(textField: "name")
            return false
        } else if usernameTextField.text?.isEmpty ?? true {
            emptyFieldAlert(textField: "username")
            return false
        } else if rideTextField.text?.isEmpty ?? true {
            emptyFieldAlert(textField: "ride")
            return false
        } else if bikeTextField.text?.isEmpty ?? true {
            emptyFieldAlert(textField: "bike")
            return false
        } else if descriptionTextView.text?.isEmpty ?? true {
            emptyFieldAlert(textField: "description")
            return false
        }
        
        return true
        
    }
    
    //Pop alert
    func emptyFieldAlert(textField: String) {
        let alertController = UIAlertController(title: "Empty Field", message: "To save your profile, please enter your \(textField)", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
        alertController.addAction(okAction)

        self.present(alertController, animated: true, completion: nil)
    }
    
}
