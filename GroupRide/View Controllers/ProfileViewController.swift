//
//  SecondViewController.swift
//  GroupRide
//
//  Created by Krysta Deluca on 5/9/18.
//  Copyright © 2018 Krysta Deluca. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate {

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var profileTableView: UITableView!
    
    let titles = ["Name", "Username", "Ride", "Bike", "Description"]
    var descriptions: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load profile
        updateProfile()
        
        //Trim profile picture
        profilePicture.layer.cornerRadius = profilePicture.frame.height / 2.0
        profilePicture.clipsToBounds = true
        
        //Add gesture recognizer to image view
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognezer:)))
        profilePicture.isUserInteractionEnabled = true
        profilePicture.addGestureRecognizer(tapGestureRecognizer)
        
        //Set up table view
        profileTableView.tableFooterView = UIView()
        
        profileTableView.delegate = self
        profileTableView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateProfile()
    }
    
    //Functions for showing image full screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowImageFullScreen" {
            let toViewController = segue.destination as UIViewController
            toViewController.transitioningDelegate = self
        }
    }
    
    @objc func imageTapped(tapGestureRecognezer: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "ShowImageFullScreen", sender: nil)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let customModalAnimator = CustomModalAnimator()
        customModalAnimator.pushing = true
        
        return customModalAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let customModalAnimator = CustomModalAnimator()
        customModalAnimator.pushing = false
        
        return customModalAnimator
    }
    
    //Unwind segue for edit profile
    @IBAction func unwindWithSegue(_ segue: UIStoryboardSegue) { }
    
    func updateProfile() {
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
        
        profileTableView.reloadData()
    }
    
    @objc func logOutTapped(sender: UIButton) {
        
        do {
            try Auth.auth().signOut()
            
            UserDefaults.standard.set(false, forKey: "LoggedIn")
            UserDefaults.standard.set(false, forKey: "TrackingLocation")
            UserDefaults.standard.removeObject(forKey: "uid")
            UserDefaults.standard.removeObject(forKey: "Username")
            UserDefaults.standard.removeObject(forKey: "Ride")
            UserDefaults.standard.removeObject(forKey: "Bike")
            UserDefaults.standard.removeObject(forKey: "Description")
            UserDefaults.standard.synchronize()
            
            //Set rootview to log in screen after log out
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window = UIWindow(frame: UIScreen.main.bounds)
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let rootViewController = mainStoryboard.instantiateViewController(withIdentifier: "logInNavigation")
            
            appDelegate.window!.rootViewController = rootViewController
            appDelegate.window!.makeKeyAndVisible()
        } catch let error as NSError {
            print (error.localizedDescription)
        }
    }
    
    //Set up table view
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as! CustomTableViewCell
        let title = titles[indexPath.row]
        let description = descriptions[indexPath.row]
        
        cell.titleLabel.text = title
        cell.descriptionLabel.text = description
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension;
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0;
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == 0 else { return nil }
        
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 100))
        
        let logOutButton = UIButton(frame: CGRect(x: 0, y: 0, width: 130, height: 44.0))
        logOutButton.center = footerView.center
        logOutButton.setTitle("Log Out", for: .normal)
        logOutButton.titleLabel?.font = UIFont(name: "Arial", size: 17.0)
        logOutButton.backgroundColor = .lightGray
        logOutButton.layer.cornerRadius = 10.0
        logOutButton.addTarget(self, action: #selector(self.logOutTapped(sender:)), for: .touchUpInside)
        
        footerView.addSubview(logOutButton)
        
        return footerView
    }
}

