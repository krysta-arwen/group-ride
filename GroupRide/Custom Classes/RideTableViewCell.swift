//
//  RideTableViewCell.swift
//  GroupRide
//
//  Created by Krysta Deluca on 8/8/18.
//  Copyright © 2018 Krysta Deluca. All rights reserved.
//

import UIKit

class RideTableViewCell: UITableViewCell {
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var rideLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
