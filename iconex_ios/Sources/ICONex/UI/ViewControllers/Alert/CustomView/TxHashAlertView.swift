//
//  TxHashAlertView.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 06/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class TxHashAlertView: UIView {
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var txHashLabel: UILabel!
    @IBOutlet weak var trackerButton: UIButton!
    
    var info: AlertTxHashInfo? {
        willSet {
            txHashLabel.size12(text: newValue!.txHash, color: .gray77, weight: .regular, align: .center)
            
            trackerButton.rx.tap
                .subscribe { (_) in
                    guard let url = URL(string: newValue!.trackerURL), UIApplication.shared.canOpenURL(url) else { return }
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
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
        let nib = UINib(nibName: "TxHashAlertView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        
        
        let attrString = NSAttributedString(string: "Alert.TxHash.Tracker".localized, attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .light), .foregroundColor: UIColor.mint1, .underlineStyle: NSUnderlineStyle.single.rawValue])
        
        trackerButton.setAttributedTitle(attrString, for: .normal)
        
    }

}
