//
//  AddressAlertView.swift
//  iconex_ios
//
//  Created by Seungyeon Lee on 2019/08/07.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class AddressAlertView: UIView {
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var addressNameInputBox: IXInputBox!
    @IBOutlet weak var addressInputBox: IXInputBox!
    @IBOutlet weak var qrcodeScanButton: UIButton!
    
    var isICON: Bool = true {
        willSet {
            if newValue {
                addressInputBox.set(state: .normal, placeholder: "Alert.Address.Placeholder.ICX".localized)
            } else {
                addressInputBox.set(state: .normal, placeholder: "Alert.Address.Placeholder.ETH".localized)
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
        let nib = UINib(nibName: "AddressAlertView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        
        addressNameInputBox.set(state: .normal, placeholder: "Alert.Address.Placeholder.Name".localized)
        qrcodeScanButton.layer.cornerRadius = 4
        qrcodeScanButton.border(1, .gray230)
        qrcodeScanButton.layer.shadowColor = UIColor.init(white: 0, alpha: 0.03).cgColor
        
    }
}
