//
//  StakeAlertView.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 05/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class StakeAlertView: UIView {
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var timeRequiredTitleLabel: UILabel!
    @IBOutlet weak var stepLimitTitleLabel: UILabel!
    @IBOutlet weak var estimatedFeeTitleLabel: UILabel!
    
    @IBOutlet weak var timeRequiredLabel: UILabel!
    @IBOutlet weak var stepLimitLabel: UILabel!
    @IBOutlet weak var estimatedFeeLabel: UILabel!
    @IBOutlet weak var estimatedFeeUSDLabel: UILabel!
    
    @IBOutlet weak var unstakeContainerView: UIView!
    @IBOutlet weak var unstakeCancelView: UIView!
    @IBOutlet weak var unstakeCancelLabel: UILabel!
    
    var isStake: Bool = true {
        willSet {
            if !newValue {
                timeRequiredLabel.size12(text: info!.timeRequired, color: .mint1, weight: .medium, align: .right)
            }
        }
    }
    var isCancel: Bool = false {
        willSet {
            if newValue {
                unstakeContainerView.isHidden = false
                unstakeCancelView.layer.cornerRadius = 8
                unstakeCancelView.layer.borderColor = UIColor.mint5.cgColor
                unstakeCancelView.layer.borderWidth = 0.5
                
                unstakeCancelLabel.size12(text: "Alert.UnStakeCancel.Infomation".localized, color: .mint1, weight: .regular, align: .left, lineBreakMode: .byWordWrapping)
                unstakeCancelLabel.numberOfLines = 2
            }
        }
    }
    
    var info: StakeInfo? {
        willSet {
            timeRequiredLabel.size12(text: newValue!.timeRequired, color: .gray77, weight: .medium, align: .right)
            stepLimitLabel.size12(text: newValue!.stepLimit, color: .gray77, weight: .medium, align: .right)
            estimatedFeeLabel.size12(text: newValue!.estimatedFee, color: .gray77, weight: .medium, align: .right)
            estimatedFeeUSDLabel.size12(text: newValue!.estimatedFeeUSD, color: .gray179, weight: .regular, align: .right)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func xibSetup() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "StakeAlertView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        
        unstakeContainerView.isHidden = true
        
        timeRequiredTitleLabel.size12(text: "Alert.Stake.Time".localized, color: .gray128, weight: .light, align: .left)
        stepLimitTitleLabel.size12(text: "Alert.Common.StepLimit".localized, color: .gray128, weight: .light, align: .left)
        estimatedFeeTitleLabel.size12(text: "Alert.Common.EstimatedFee".localized, color: .gray128, weight: .light, align: .left)
    }
}
