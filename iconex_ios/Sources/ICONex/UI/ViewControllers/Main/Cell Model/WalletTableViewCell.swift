//
//  WalletTableViewCell.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 20/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class WalletTableViewCell: UITableViewCell {

    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var currencyUnitLabel: UILabel!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var isLoading: Bool = true {
        willSet {
            if newValue {
                spinner.startAnimating()
            } else {
                spinner.stopAnimating()
            }
            
            self.balanceLabel.isHidden = newValue
            self.currencyLabel.isHidden = newValue
            self.currencyUnitLabel.isHidden = newValue
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
