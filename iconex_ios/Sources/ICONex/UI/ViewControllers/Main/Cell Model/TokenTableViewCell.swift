//
//  TokenTableViewCell.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 20/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class TokenTableViewCell: UITableViewCell {
    @IBOutlet weak var symbolView: UIView!
    @IBOutlet weak var symbolNicknameLabel: UILabel!
    
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var fullnameLabel: UILabel!
    
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var unitBalanceLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var isLoading: Bool = true {
        willSet {
            if newValue {
                self.spinner.startAnimating()
            } else {
                self.spinner.stopAnimating()
            }
            
            self.balanceLabel.isHidden = newValue
            self.unitBalanceLabel.isHidden = newValue
            self.unitLabel.isHidden = newValue
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        symbolView.corner(16)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
