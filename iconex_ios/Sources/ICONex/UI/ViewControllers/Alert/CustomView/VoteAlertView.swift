//
//  VoteAlertView.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 13/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import BigInt

class VoteAlertView: UIView {
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var prepTitleLabel: UILabel!
    
    
    @IBOutlet weak var votedPrep: UILabel!
    @IBOutlet weak var prepTotal: UILabel!
    @IBOutlet weak var estimatedStepTitleLabel: UILabel!
    
    @IBOutlet weak var estimatedStepLabel: UILabel!
    
    @IBOutlet weak var stepPriceTitleLabel: UILabel!
    @IBOutlet weak var stepPriceLabel: UILabel!
    @IBOutlet weak var usdPriceLabel: UILabel!
    @IBOutlet weak var dollarLabel: UILabel!
    
    var voteInfo: VoteInfo? {
        willSet {
            guard let info = newValue else { return }
            votedPrep.text = "\(info.count)"
            estimatedStepLabel.size12(text: info.estimatedFee, color: .gray77, weight: .bold, align: .right)
            stepPriceLabel.size12(text: info.maxFee, color: .gray77, weight: .bold, align: .right)
            usdPriceLabel.size12(text: info.usdPrice, color: .gray179, align: .right)
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
        let nib = UINib(nibName: "VoteAlertView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        
        prepTitleLabel.size12(text: "Alert.Vote.Prep".localized, color: .gray77, weight: .bold, align: .left)
        estimatedStepTitleLabel.size12(text: "Alert.Common.StepLimit".localized, color: .gray128, weight: .light, align: .left)
        stepPriceTitleLabel.size12(text: "Alert.Common.EstimatedFee".localized, color: .gray128, weight: .light, align: .left)
        dollarLabel.size12(text: "$", color: .gray179, align: .right)
    }

}
