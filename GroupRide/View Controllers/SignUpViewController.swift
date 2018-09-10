//
//  SignUpViewController.swift
//  GroupRide
//
//  Created by Krysta Deluca on 8/9/18.
//  Copyright © 2018 Krysta Deluca. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignUpViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    var ref: DocumentReference!
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        //Move view upwards when keyboard shows
        self.view.frame.origin.y = -100
    }
    
    @objc func keyboardHidden(notification: NSNotification) {
        self.view.frame.origin.y = 0
    }
    
    @IBAction func signUpTapped(_ sender: Any) {
        //Check that fields aren't empty
        guard let name = usernameField.text,
            let email = emailField.text,
            let password = passwordField.text,
            name.count > 0,
            email.count > 0,
            password.count > 0
            else {
                self.showAlert(message: "\(NSLocalizedString("missingInfo", comment: ""))")
                return
        }
        
        //Create user with Firebase
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if let error = error {
                if error._code == AuthErrorCode.invalidEmail.rawValue {
                    self.showAlert(message: "\(NSLocalizedString("invalidEmail", comment: ""))")
                } else if error._code == AuthErrorCode.emailAlreadyInUse.rawValue {
                    self.showAlert(message: "\(NSLocalizedString("emailInUse", comment: ""))")
                } else {
                    self.showAlert(message: "Error: \(error.localizedDescription)")
                }
                print(error.localizedDescription)
                return
            }
            
            if let user = Auth.auth().currentUser {
                self.setUserName(user: user, name: name)
                UserDefaults.standard.set(name as String, forKey: "Username")
                UserDefaults.standard.set(user.uid as String, forKey: "uid")
                UserDefaults.standard.synchronize()
                                
                //Save profile to user collection
                self.db.collection("users").document(user.uid).setData([
                    "username": name,
                    "email": email,
                    "uid": Auth.auth().currentUser?.uid
                ]) { error in
                    if let error = error {
                        print("Error adding document: \(error)")
                    } else {
                        print("Document added with ID: \(self.ref!.documentID)")
                    }
                }
            }
        }
    }
    
    func setUserName(user: User, name: String) {
        //Create request to add username to profile
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        
        changeRequest.commitChanges(){ (error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            //Save user details and perform segue
            AuthenticationManager.sharedInstance.didLogIn(user: user)
            UserDefaults.standard.set(true, forKey: "Logged In")
            UserDefaults.standard.synchronize()
            self.performSegue(withIdentifier: "ShowMapFromSignUp", sender: nil)
        }
    }
    
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "\(NSLocalizedString("signUp", comment: ""))", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

}
