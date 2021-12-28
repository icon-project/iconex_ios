//
//  PasswordAlertView.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 06/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class PasswordAlertView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var inputBoxView: IXInputBox!
    
    var placeholder: String = "" {
        willSet {
            inputBoxView.set(state: .normal, placeholder: newValue)
        }
    }
    
    var alertType: InputAlertType = .password {
        willSet {
            switch newValue {
            case .password:
                inputBoxView.set(inputType: .secure)
            case .walletName:
                inputBoxView.set(inputType: .name)
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
        let nib = UINib(nibName: "PasswordAlertView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
    }
}

enum InputAlertType {
    case password, walletName
}
