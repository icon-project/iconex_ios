//
//  SendAlertView.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 06/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class SendAlertView: UIView {
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var sendAmountTitleLabel: UILabel!
    @IBOutlet weak var stepLimitTitleLabel: UILabel!
    @IBOutlet weak var estimatedTitleLabel: UILabel!
    @IBOutlet weak var addressTitleLabel: UILabel!
    
    @IBOutlet weak var sendAmountLabel: UILabel!
    @IBOutlet weak var stepLimitLabel: UILabel!
    @IBOutlet weak var estimateMaxLabel: UILabel!
    @IBOutlet weak var estimateUSDLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    var info: SendInfo? {
        willSet {
            guard let info = newValue else { return }
            
            if info.transaction == nil {
                stepLimitTitleLabel.isHidden = true
                stepLimitLabel.isHidden = true
                estimatedTitleLabel.text =  "Alert.Send.ETH.Fee".localized
                
                if let token = info.token {
                    sendAmountTitleLabel.text = String(format: "Alert.Send.Value.Token".localized, token.symbol)
                } else {
                    sendAmountTitleLabel.text = "Alert.Send.Value.ETH".localized
                }
                
            } else {
                stepLimitTitleLabel.text = "Alert.Common.StepLimit".localized
                estimatedTitleLabel.text =  "Alert.Common.EstimatedFee".localized
                
                if let token = info.token {
                    sendAmountTitleLabel.text = String(format: "Alert.Send.Value.Token".localized, token.symbol)
                } else {
                    sendAmountTitleLabel.text = "Alert.Send.Value.ICX".localized
                }
            }
            
            sendAmountLabel.size18(text: info.amount, color: .mint1, weight: .regular, align: .right)
            stepLimitLabel.size12(text: info.stepLimit, color: .gray77, weight: .bold, align: .right)
            estimateMaxLabel.size12(text: info.estimatedFee, color: .gray77,  weight: .bold, align: .right)
            estimateUSDLabel.size12(text: info.estimatedUSD, color: .gray179,  weight: .regular, align: .right)
            addressLabel.size12(text: info.receivingAddress, color: .gray77,  weight: .bold, align: .left)
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
        let nib = UINib(nibName: "SendAlertView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        
        addressTitleLabel.text = "Alert.Send.Address".localized
    }
}
