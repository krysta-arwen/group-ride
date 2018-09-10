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
    
    let titles = ["\(NSLocalizedString("name", comment: ""))", "\(NSLocalizedString("username", comment: ""))", "\(NSLocalizedString("ride", comment: ""))", "\(NSLocalizedString("bike", comment: ""))", "\(NSLocalizedString("description", comment: ""))"]
    var descriptions: [String]!
    var textLimitLength = 20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkProfile()
        
        editTableView.tableFooterView = UIView()
        editTableView.delegate = self
        editTableView.dataSource = self
        editTableView.alwaysBounceVertical = false
        
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
            descriptions.append("\(NSLocalizedString("noNameSaved", comment: ""))")
        }
        
        if let username = UserDefaults.standard.string(forKey: "Username") {
            descriptions.append(username)
        } else {
            descriptions.append("\(NSLocalizedString("noUsernameSaved", comment: ""))")
        }
        
        if let bike = UserDefaults.standard.object(forKey: "Ride") as? String {
            descriptions.append(bike)
        } else {
            descriptions.append("\(NSLocalizedString("noRideSaved", comment: ""))")
        }
        
        if let ride = UserDefaults.standard.object(forKey: "Bike") as? String {
            descriptions.append(ride)
        } else {
            descriptions.append("\(NSLocalizedString("noBikeSaved", comment: ""))")
        }
        
        if let description = UserDefaults.standard.object(forKey: "Description") as? String {
            descriptions.append(description)
        } else {
            descriptions.append("\(NSLocalizedString("noDescriptionSaved", comment: ""))")
        }
    }
    
    //Check if necessary fields are empty
    func checkEmptyField() -> Bool {
        var emptyFields = 0
        var indexPath = IndexPath(row: 0, section: 0)
        let nameCell = editTableView.cellForRow(at: indexPath) as! EditProfileTableViewCell
        nameCell.errorLabel.alpha = 0
        
        if descriptions[0] == "\(NSLocalizedString("noNameSaved", comment: ""))" || descriptions[0] == "" {
            nameCell.errorLabel.text = "\(NSLocalizedString("emptyName", comment: ""))"
            UIView.animate(withDuration: 1) {
                nameCell.errorLabel.alpha = 1
            }
            emptyFields += 1
        }
        
        indexPath = IndexPath(row: 1, section: 0)
        let usernameCell = editTableView.cellForRow(at: indexPath) as! EditProfileTableViewCell
        usernameCell.errorLabel.alpha = 0
        
        if descriptions[1] == "\(NSLocalizedString("noUsernameSaved", comment: ""))" || descriptions[1] == "" {
            usernameCell.errorLabel.text = "\(NSLocalizedString("emptyUsername", comment: ""))"
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
        saveUsername()
        userDefaults.set(descriptions[2], forKey: "Ride")
        userDefaults.set(descriptions[3], forKey: "Bike")
        userDefaults.set(descriptions[4], forKey: "Description")
        userDefaults.synchronize()
    }
    
    func saveUsername() {
        if UserDefaults.standard.string(forKey: "Username") != descriptions[1] {
            if let user = Auth.auth().currentUser {
                //Create request to change username in firebase profile
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = descriptions[1]
                
                changeRequest.commitChanges(){ (error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                }
            }
        }
        
        UserDefaults.standard.set(descriptions[1], forKey: "Username")
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
        if var value = textView.text {
            value = value.trimmingCharacters(in: .whitespacesAndNewlines)
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
