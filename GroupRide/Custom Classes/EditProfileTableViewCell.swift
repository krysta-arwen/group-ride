//
//  EditProfileTableViewCell.swift
//  GroupRide
//
//  Created by Krysta Deluca on 8/2/18.
//  Copyright © 2018 Krysta Deluca. All rights reserved.
//

import UIKit

class EditProfileTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var errorLabel: UILabel!
    
    
    var textString: String {
        get {
            return descriptionTextView.text ?? ""
        }
        set {
            if let textView = descriptionTextView {
                textView.text = newValue
                textView.delegate?.textViewDidChange?(textView)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        descriptionTextView.isScrollEnabled = false
        
        let borderColor : UIColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        descriptionTextView.layer.borderWidth = 0.5
        descriptionTextView.layer.borderColor = borderColor.cgColor
        descriptionTextView.layer.cornerRadius = 5.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            descriptionTextView.becomeFirstResponder()
        } else {
            descriptionTextView.resignFirstResponder()
        }
    }

}
