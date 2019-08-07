//
//  IScoreAlertView.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 06/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class IScoreAlertView: UIView {
    
    @IBOutlet var contentView: UIView!
    
    // title
    @IBOutlet weak var currentIScoreTitleLabel: UILabel!
    @IBOutlet weak var canReceiveTitleLabel: UILabel!
    @IBOutlet weak var stepLimitTitleLabel: UILabel!
    @IBOutlet weak var estimatedFeeTItleLabel: UILabel!
    
    @IBOutlet weak var currentIScoreLabel: UILabel!
    @IBOutlet weak var canReceiveLabel: UILabel!
    @IBOutlet weak var stepLimitLabel: UILabel!
    @IBOutlet weak var estimatedFeeLabel: UILabel!
    @IBOutlet weak var estimatedUSDLabel: UILabel!
    
    var info: IScoreClaimInfo? {
        willSet {
            currentIScoreLabel.size18(text: newValue!.currentIScore, color: .mint1, weight: .regular, align: .right)
            canReceiveLabel.size18(text: newValue!.youcanReceive, color: .mint1, weight: .regular, align: .right)
            stepLimitLabel.size12(text: newValue!.stepLimit, color: .gray77, weight: .bold, align: .right)
            estimatedFeeLabel.size12(text: newValue!.estimatedFee, color: .gray77, weight: .bold, align: .right)
            estimatedUSDLabel.size12(text: newValue!.estimateUSD, color: .gray179, weight: .regular, align: .right)
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
        let nib = UINib(nibName: "IScoreAlertView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        
        currentIScoreTitleLabel.size12(text: "Alert.Iscore.Current".localized, color: .gray77, weight: .bold, align: .left)
        canReceiveTitleLabel.size12(text: "Alert.Iscore.Value".localized, color: .gray77, weight: .bold, align: .left)
        stepLimitTitleLabel.size12(text: "Alert.Common.StepLimit".localized, color: .gray128, weight: .light, align: .left)
        estimatedFeeTItleLabel.size12(text: "Alert.Common.EstimatedFee".localized, color: .gray128, weight: .light, align: .left)
    }
}
