//
//  SelectCoinTokenTableViewCell.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 29/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class SelectCoinTokenTableViewCell: UITableViewCell {

    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var fullNameLabel: UILabel!
    
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var dollarLabel: UILabel!
    @IBOutlet weak var usdPriceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
