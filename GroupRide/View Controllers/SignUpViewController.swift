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
        
        emailField.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
                self.showAlert(message: "Enter a name, an email and a password.")
                return
        }
        
        //Create user with Firebase
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if let error = error {
                if error._code == AuthErrorCode.invalidEmail.rawValue {
                    self.showAlert(message: "Enter a valid email.")
                } else if error._code == AuthErrorCode.emailAlreadyInUse.rawValue {
                    self.showAlert(message: "Email already in use.")
                } else {
                    self.showAlert(message: "Error: \(error.localizedDescription)")
                }
                print(error.localizedDescription)
                return
            }
            
            if let user = Auth.auth().currentUser {
                self.setUserName(user: user, name: name)
            }
            
            //Save profile to user collection
            self.ref = self.db.collection("users").addDocument(data: [
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
            self.performSegue(withIdentifier: "ShowMapFromSignUp", sender: nil)
        }
    }
    
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "iChat", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

}
