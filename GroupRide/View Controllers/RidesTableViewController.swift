//
//  RideViewController.swift
//  GroupRide
//
//  Created by Krysta Deluca on 8/2/18.
//  Copyright © 2018 Krysta Deluca. All rights reserved.
//

import UIKit

class RidesTableViewController: UITableViewController {
    
    let formatter = DateFormatter()
    var rides: [Ride]!
    var rideNames: [String]!
    var selectedRideName: String!
    
    @IBAction func doneTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        rideNames = []
        
        if let date = UserDefaults.standard.object(forKey: "SelectedDate") as? Date {
            formatter.dateFormat = "MMMM dd, YYYY"
            let selectedDate = formatter.string(from: date)
            
            self.navigationItem.title = selectedDate
        }
        
        //Add names for date
        if let rides = rides {
            for ride in rides {
                formatter.dateFormat = "MM.dd.YY"
                formatter.timeZone = Calendar.current.timeZone
                formatter.locale = Calendar.current.locale
                
                let todayDate = UserDefaults.standard.object(forKey: "SelectedDate") as? Date
                let date = formatter.string(from: todayDate!)
                
                if ride.date == date {
                    rideNames.append(ride.name)
                }
            }
        }
        
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let rideDetailVC = segue.destination as! RideDetailViewController
        
        if let selectedName = selectedRideName {
            rideDetailVC.ride = findSelectedRide()
        }
        
    }
    
    //Find link for selected ride
    func findSelectedRide() -> Ride {
        for ride in rides {
            formatter.dateFormat = "MM.dd.YY"
            formatter.timeZone = Calendar.current.timeZone
            formatter.locale = Calendar.current.locale
            
            let todayDate = UserDefaults.standard.object(forKey: "SelectedDate") as? Date
            let date = formatter.string(from: todayDate!)
            
            if ride.date == date && ride.name == selectedRideName {
                return ride
            }
        }
        
        return Ride(date: "01.01.1990", name: "Ride Not Found", detail: "")
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRideName = rideNames[indexPath.row]
        
        let parameters = ["Email" : UserDefaults.standard.object(forKey: "Email"), "Selected Ride Name" : selectedRideName]
        Analytics.logEvent("selectedRide", parameters: parameters)
        
        self.performSegue(withIdentifier: "ShowRideDetail", sender: nil)
    }
    
    //Set up table view
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rideNames.count
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = UIColor.black
        
        return footerView
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RideTableCell", for: indexPath)
        
        cell.textLabel?.text = rideNames[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension;
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0;
    }
}
