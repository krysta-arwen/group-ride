//
//  LogInViewController.swift
//  GroupRide
//
//  Created by Krysta Deluca on 8/9/18.
//  Copyright © 2018 Krysta Deluca. All rights reserved.
//

import UIKit
import FirebaseAuth

class LogInViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        //Move view up when keyboard will show
        self.view.frame.origin.y = -100
    }
    
    @objc func keyboardHidden(notification: NSNotification) {
        self.view.frame.origin.y = 0
    }

    @IBAction func logInButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, let password = passwordTextField.text, email.count > 0, password.count > 0 else {
            self.showAlert(message: "\(NSLocalizedString("emailAndPasswordEntry", comment: ""))")
            
            let parameters = [String : Any]()
            Analytics.logEvent("missingLogInInfo", parameters: parameters)
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if let error = error {
                if error._code == AuthErrorCode.userNotFound.rawValue {
                    self.showAlert(message: "\(NSLocalizedString("noUsers", comment: ""))")
                    
                    let parameters = ["Error" : error._code]
                    Analytics.logEvent("noUserWithEmail", parameters: parameters)
                } else if error._code == AuthErrorCode.wrongPassword.rawValue {
                    self.showAlert(message: "\(NSLocalizedString("incorrectLogIn", comment: ""))")
                    
                    let parameters = ["Error" : error._code]
                    Analytics.logEvent("wrongEmailOrPassword", parameters: parameters)
                } else {
                    self.showAlert(message: "Error: \(error.localizedDescription)")
                    let castedError = error as NSError
                    let firebaseError = AuthErrorCode(rawValue: castedError.code)
                   
                    let parameters = ["Error" : firebaseError]
                    Analytics.logEvent("miscellaneousLogInError", parameters: parameters)
                    print(castedError.code)
                }
                print(error.localizedDescription)
                return
            }
            
            if let user = Auth.auth().currentUser {
                AuthenticationManager.sharedInstance.didLogIn(user: user)
                UserDefaults.standard.set(user.uid as String, forKey: "uid")
                UserDefaults.standard.set(user.displayName as! String, forKey: "Username")
                UserDefaults.standard.set(true, forKey: "LoggedIn")
                UserDefaults.standard.set(user.email as! String, forKey: "Email")
                UserDefaults.standard.synchronize()
                
                let parameters = ["Email" : user.email]
                Analytics.logEvent("logInSuccessful", parameters: parameters)
                self.performSegue(withIdentifier: "ShowMapFromLogIn", sender: nil)
            }
        }
    }
    
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "\(NSLocalizedString("logIn", comment: ""))", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
