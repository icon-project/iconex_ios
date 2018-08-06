//
//  MainWalletCell.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class MainWalletCell: UITableViewCell {

    @IBOutlet weak var coinNameLabel: UILabel!
    @IBOutlet weak var coinValueLabel: UILabel!
    @IBOutlet weak var exchangeValueLabel: UILabel!
    @IBOutlet weak var coinTypeLabel: UILabel!
    @IBOutlet weak var exchangeTypeLabel: UILabel!
    @IBOutlet weak var rearContainer: UIView!
    @IBOutlet weak var indicator: IXIndicator!
    @IBOutlet weak var swapBack: UIView!
    @IBOutlet weak var swapLabel: UILabel!
    @IBOutlet weak var swapButton: UIButton!
    
    let disposeBag = DisposeBag()
    
    var isLoading: Bool = false {
        willSet {
            if newValue {
                coinNameLabel.isHidden = false
                coinValueLabel.isHidden = true
                exchangeValueLabel.isHidden = true
                rearContainer.isHidden = true
                indicator.isHidden = false
            } else {
                coinNameLabel.isHidden = false
                coinValueLabel.isHidden = false
                exchangeValueLabel.isHidden = false
                rearContainer.isHidden = false
                indicator.isHidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        exchangeTypeLabel.textColor = UIColor.lightTheme.background.normal
        exchangeValueLabel.textColor = UIColor.lightTheme.background.normal
        isLoading = false
        swapBack.layer.masksToBounds = true
        swapBack.layer.cornerRadius = swapBack.frame.height / 2
        swapLabel.text = "Swap.Swap".localized
        swapLabel.textColor = UIColor.white
        swapLabel.backgroundColor = UIColor.black
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
