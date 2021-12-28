//
//  CoinTableViewCell.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 20/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class CoinTableViewCell: UITableViewCell {
    // basic
    @IBOutlet weak var basicView: UIView!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var unitBalanceLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    
    // stake
    @IBOutlet weak var stakeTitle: UILabel!
    @IBOutlet weak var iscoreTitle: UILabel!
    
    @IBOutlet weak var stakeLabel: UILabel!
    @IBOutlet weak var stakedPercentLabel: UILabel!
    @IBOutlet weak var iscoreLabel: UILabel!
    
    @IBOutlet weak var balanceSpinner: UIActivityIndicatorView!
    @IBOutlet weak var stakeSpinner: UIActivityIndicatorView!
    
    var isLoadingBalance: Bool = true {
        willSet {
            if newValue {
                self.balanceSpinner.startAnimating()
            } else {
                self.balanceSpinner.stopAnimating()
            }
            
            self.balanceLabel.isHidden = newValue
            self.unitBalanceLabel.isHidden = newValue
            self.unitLabel.isHidden = newValue
        }
    }
    
    var isLoadingStake: Bool = true {
        willSet {
            if newValue {
                self.stakeSpinner.startAnimating()
            } else {
                self.stakeSpinner.stopAnimating()
            }
            
            self.stakeLabel.isHidden = newValue
            self.stakedPercentLabel.isHidden = newValue
            self.iscoreLabel.isHidden = newValue
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        logoImageView.image = nil
        
        self.stakeTitle.size12(text: "Staked", color: .gray77, weight: .light)
        self.iscoreTitle.size12(text: "I-Score", color: .gray77, weight: .light)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
