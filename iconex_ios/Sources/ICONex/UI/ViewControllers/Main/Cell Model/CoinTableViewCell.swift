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
    @IBOutlet weak var powerTitle: UILabel!
    @IBOutlet weak var iscoreTitle: UILabel!
    
    @IBOutlet weak var stakeLabel: UILabel!
    @IBOutlet weak var powerLabel: UILabel!
    @IBOutlet weak var iscoreLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        logoImageView.image = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
