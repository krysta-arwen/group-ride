//
//  RideDetailViewController.swift
//  GroupRide
//
//  Created by Krysta Deluca on 8/2/18.
//  Copyright © 2018 Krysta Deluca. All rights reserved.
//

import UIKit
import Alamofire
import Kanna

class RideDetailViewController: UIViewController {
    
    @IBOutlet weak var rideDescriptionTextView: UITextView!
    var ride: Ride!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !ride.name.isEmpty {
            self.navigationItem.title = ride.name
        }
        
        getRideDetail()
    }

    func getRideDetail() {
        if !ride.detail.isEmpty {
            let rideUrl = ride.detail.trimmingCharacters(in: .whitespacesAndNewlines)
            //Get html from website
            Alamofire.request("http://www.midnightridazz.com/" + rideUrl)
                .validate()
                .responseString { response in
                    if response.result.isSuccess {
                        if let html = response.result.value {
                            self.parseHTML(html: html)
                        }
                    } else {
                        print(response.result.error.debugDescription)
                        self.rideDescriptionTextView.text = "\(NSLocalizedString("noRideDescription", comment: ""))"
                    }
            }
        }
    }
    
    func parseHTML(html: String) -> Void {
        if let doc = try? HTML(html: html, encoding: String.Encoding.utf8) {
            // Search for nodes by CSS selector
            for url in doc.css("td[class^='content']") {
                if let text = url.text {
                    rideDescriptionTextView.text = self.prepareDescription(description: text)
                }
            }
        }
    }
    
    //Remove name and date from description
    func prepareDescription(description: String) -> String {
        var trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedDescription.hasPrefix(ride.name){
            trimmedDescription = trimmedDescription.replacingOccurrences(of: ride.name, with: "", options: .anchored, range: nil)
        }
        
        //Remove date from description
        let index = trimmedDescription.index(trimmedDescription.startIndex, offsetBy: 4)
        if trimmedDescription[index] == "." {
            trimmedDescription = String(trimmedDescription.dropFirst(8))
            print(trimmedDescription)
        } else {
            trimmedDescription = String(trimmedDescription.dropFirst(9))
            print(trimmedDescription)
        }
 
        return trimmedDescription
    }

}
