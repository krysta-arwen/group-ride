//
//  PhotoViewController.swift
//  GroupRide
//
//  Created by Krysta Deluca on 8/2/18.
//  Copyright © 2018 Krysta Deluca. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {

    @IBOutlet weak var fullScreenImage: UIImageView!
    var profileImage: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fullScreenImage.image = profileImage
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func doneButtonTapped(_ sender: Any) {
        let parameters = ["Email" : UserDefaults.standard.object(forKey: "Email")]
        Analytics.logEvent("exitedPictureFullScreen", parameters: parameters)
        
        dismiss(animated: true, completion: nil)
    }
}
