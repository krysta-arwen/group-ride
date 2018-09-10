//
//  CalendarViewController.swift
//  
//
//  Created by Krysta Deluca on 5/29/18.
//

import UIKit
import JTAppleCalendar
import Alamofire
import Kanna

class CalendarViewController: UIViewController {
    
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var calendarView: JTAppleCalendarView!
    
    let formatter = DateFormatter()
    var rides: [Ride]!
    var dates: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "\(NSLocalizedString("rideCalendar", comment: ""))"
        
        setUpCalendarView()
        
        getCalendarData(urlString: "http://www.midnightridazz.com/events.php")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpCalendarView() {
        //Set up spacing
        calendarView.minimumLineSpacing = 1
        calendarView.minimumInteritemSpacing = 1
        
        //Set up labels
        calendarView.visibleDates{ (visibleDates) in
            self.setUpViewsOfCalendar(from: visibleDates)
        }
    }
        
    func setUpViewsOfCalendar(from visibleDates: DateSegmentInfo) {
        let date = visibleDates.monthDates.first!.date
        
        self.formatter.dateFormat = "yyyy"
        self.yearLabel.text = self.formatter.string(from: date)
        
        self.formatter.dateFormat = "MMMM"
        self.monthLabel.text = self.formatter.string(from: date)
    }
    
    //Get html from website
    func getCalendarData(urlString: String) {
        Alamofire.request(urlString)
            .validate()
            .responseString { response in
                if response.result.isSuccess {
                    if let html = response.result.value {
                        self.parseHTML(html: html)
                    }
                } else {
                    print(response.result.error.debugDescription)
                }
        }
    }
    
    func parseHTML(html: String) -> Void {
        rides = []
        
        if let doc = try? HTML(html: html, encoding: String.Encoding.utf8) {
            
            // Search for nodes by CSS selector
            for url in doc.css("a[href*=viewStory]") {
                if var rideTitle = url.text, let rideLink = url["href"] {
                    //Check if response is empty
                    if rideTitle.count > 0 && checkTitle(titleString: rideTitle) {
                        
                        rideTitle = fixDate(titleString: rideTitle)
                        
                        let rideDate = String(rideTitle.suffix(8))
                        rideTitle = String(rideTitle.prefix(rideTitle.count - 8))
                        
                        let newRide = Ride(date: rideDate, name: rideTitle, detail: rideLink)
                        rides.append(newRide)
                    }
                }
            }
            
            fillDates()
        }
    }
    
    //Check if response is valid ride
    func checkTitle(titleString: String) -> Bool {
        let lastCharacters = titleString.suffix(2)

        if let _ = Int(lastCharacters) {
            return true
        }

        return false
    }
    
    //Add missing 0 to dates that need it
    func fixDate(titleString: String) -> String {
        var editedString = titleString
        let stringIndex = editedString.count - 5
        let index = editedString.index(editedString.startIndex, offsetBy: stringIndex)

        if editedString[index] == "." {
            let editedIndex = editedString.index(editedString.startIndex, offsetBy: editedString.count - 4)
            editedString.insert("0", at: editedIndex)
        }
            
        return editedString
    }
    
    func fillDates() {
        dates = []
        
        for ride in rides {
            formatter.dateFormat = "MM.dd.yy"
            let rideDate = formatter.date(from: ride.date)
            
            formatter.dateFormat = "yyyy MM dd"
            formatter.timeZone = Calendar.current.timeZone
            formatter.locale = Calendar.current.locale
            
            let date = formatter.string(from: rideDate!)
            
            dates.append(date)
        }
        
        calendarView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let navVC = segue.destination as! UINavigationController
        let rideVC = navVC.topViewController as! RidesTableViewController
        rideVC.rides = rides
    }
}

extension CalendarViewController: JTAppleCalendarViewDataSource {
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "CustomCell", for: indexPath) as! CustomCell
        cell.dateLabel.text = cellState.text
        
        // Setup text color
        if cellState.dateBelongsTo == .thisMonth {
            cell.dateLabel.textColor = UIColor.white
        } else {
            cell.dateLabel.textColor = UIColor.lightGray
        }
        
        if let dates = dates {
            formatter.dateFormat = "yyyy MM dd"
            formatter.timeZone = Calendar.current.timeZone
            formatter.locale = Calendar.current.locale
            
            let todayString = formatter.string(from: date)
            
            if dates.contains(todayString) {
                cell.redIndicator.isHidden = false
            } else {
                cell.redIndicator.isHidden = true
            }
        }
    }
    
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        formatter.dateFormat = "yyyy MM dd"
        formatter.timeZone = Calendar.current.timeZone
        formatter.locale = Calendar.current.locale
        
        let todayString = formatter.string(from: Date())
        let add6Months = Calendar.current.date(byAdding: .month, value: 6, to: Date())
        let endDateString = formatter.string(from: add6Months!)
        
        let startDate = formatter.date(from: todayString)!
        let endDate = formatter.date(from: endDateString)!
        
        let parameters = ConfigurationParameters(startDate: startDate, endDate: endDate)
        return parameters
    }
}

extension CalendarViewController: JTAppleCalendarViewDelegate {
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "CustomCell", for: indexPath) as! CustomCell
        cell.dateLabel.text = cellState.text
        
        // Setup text color
        if cellState.dateBelongsTo == .thisMonth {
            cell.dateLabel.textColor = UIColor.white
        } else {
            cell.dateLabel.textColor = UIColor.lightGray
        }
        
        if let dates = dates {
            formatter.dateFormat = "yyyy MM dd"
            formatter.timeZone = Calendar.current.timeZone
            formatter.locale = Calendar.current.locale
            
            let todayString = formatter.string(from: date)
            
            if dates.contains(todayString) {
                cell.redIndicator.isHidden = false
            } else {
                cell.redIndicator.isHidden = true
            }
        }
        
        return cell
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let validCell = cell as? CustomCell else {return}
        
        let selectedDate = date
        UserDefaults.standard.set(selectedDate, forKey: "SelectedDate")
        
        if validCell.redIndicator.isHidden == false {
            self.performSegue(withIdentifier: "ShowRidesPage", sender: nil)
        }
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        setUpViewsOfCalendar(from: visibleDates)
    }
}
