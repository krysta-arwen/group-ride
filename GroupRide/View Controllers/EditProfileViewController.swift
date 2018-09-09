//
//  EditProfileViewController.swift
//  GroupRide
//
//  Created by Krysta Deluca on 6/11/18.
//  Copyright © 2018 Krysta Deluca. All rights reserved.
//

import UIKit

class EditProfileViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var editTableView: UITableView!
    var activeTextView: UITextView?
    
    let titles = ["Name", "Username", "Ride", "Bike", "Description"]
    var descriptions: [String]!
    var textLimitLength = 20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkProfile()
        
        editTableView.tableFooterView = UIView()
        editTableView.delegate = self
        editTableView.dataSource = self
        
        //Looks for single or multiple taps
         let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        //If there are any empty fields, don't exit view
        view.endEditing(true)
        
        if !checkEmptyField() {
            saveProfile()
        } else {
            return
        }
            
        performSegue(withIdentifier: "returnToProfile", sender: self)
    }

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "returnToProfile", sender: self)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //Check if there is a saved profile
    func checkProfile() {
        descriptions = []
        
        if let name = UserDefaults.standard.object(forKey: "Name") as? String {
            descriptions.append(name)
        } else {
            descriptions.append("No name saved.")
        }
        
        if let username = UserDefaults.standard.string(forKey: "Username") {
            descriptions.append(username)
        } else {
            descriptions.append("No username saved.")
        }
        
        if let bike = UserDefaults.standard.object(forKey: "Ride") as? String {
            descriptions.append(bike)
        } else {
            descriptions.append("No ride saved.")
        }
        
        if let ride = UserDefaults.standard.object(forKey: "Bike") as? String {
            descriptions.append(ride)
        } else {
            descriptions.append("No bike saved.")
        }
        
        if let description = UserDefaults.standard.object(forKey: "Description") as? String {
            descriptions.append(description)
        } else {
            descriptions.append("No description saved.")
        }
    }
    
    //Check if necessary fields are empty
    func checkEmptyField() -> Bool {
        var emptyFields = 0
        var indexPath = IndexPath(row: 0, section: 0)
        let nameCell = editTableView.cellForRow(at: indexPath) as! EditProfileTableViewCell
        nameCell.errorLabel.alpha = 0
        
        if descriptions[0] == "No name saved." {
            nameCell.errorLabel.text = "You must enter a name."
            UIView.animate(withDuration: 1) {
                nameCell.errorLabel.alpha = 1
            }
            emptyFields += 1
        }
        
        indexPath = IndexPath(row: 1, section: 0)
        let usernameCell = editTableView.cellForRow(at: indexPath) as! EditProfileTableViewCell
        usernameCell.errorLabel.alpha = 0
        
        if descriptions[1] == "No username saved." {
            usernameCell.errorLabel.text = "You must enter a username."
            UIView.animate(withDuration: 1) {
                usernameCell.errorLabel.alpha = 1
            }
            emptyFields += 1
        }
        
        return emptyFields > 0
    }
    
    //Save Profile
    func saveProfile() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(descriptions[0], forKey: "Name")
        userDefaults.set(descriptions[1], forKey: "Username")
        userDefaults.set(descriptions[2], forKey: "Ride")
        userDefaults.set(descriptions[3], forKey: "Bike")
        userDefaults.set(descriptions[4], forKey: "Description")
    }
    
    //Set up table view
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditProfileCell", for: indexPath) as! EditProfileTableViewCell
        let title = titles[indexPath.row]
        let description = descriptions[indexPath.row]
        
        cell.titleLabel.text = title
        cell.descriptionTextView.text = description
        
        cell.descriptionTextView.tag = indexPath.row
        cell.descriptionTextView.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension;
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0;
    }
}

extension EditProfileViewController: UITextViewDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if let value = textView.text {
            descriptions[textView.tag] = value
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        activeTextView = textView
        
        DispatchQueue.main.async {
            textView.selectAll(nil)
        }
    }
    
    //Resize text view
    func textViewDidChange(_ textView: UITextView) {
        let size = textView.bounds.size
        let newSize = textView.sizeThatFits(CGSize(width: size.width,
                                                   height: CGFloat.greatestFiniteMagnitude))
        
        // Resize the cell only when cell's size is changed
        if size.height != newSize.height {
            UIView.setAnimationsEnabled(false)
            editTableView.beginUpdates()
            editTableView.endUpdates()
            UIView.setAnimationsEnabled(true)
            
            let thisIndexPath = IndexPath(row: textView.tag, section: 0)
            editTableView.scrollToRow(at: thisIndexPath,
                                      at: .bottom,
                                              animated: false)
        }
    }
}
