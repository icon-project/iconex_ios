//
//  PreventTextField.swift
//  ios-authenticator
//
//  Created by Ahn on 2017. 6. 14..
//  Copyright © 2017년 Ahn. All rights reserved.
//

import UIKit

class PreventTextField: UITextField {
    
    var isPreventPaste: Bool = false
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        for subview in self.subviews {
            if subview is UIButton {
                let button = subview as! UIButton
                button.setImage(#imageLiteral(resourceName: "icInputDelete"), for: .normal)
            }
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(UIResponderStandardEditActions.paste(_:)), #selector(UIResponderStandardEditActions.copy(_:)):
            return !isPreventPaste
        
        default:
            return false
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
}

extension CALayer {
    var customBorderColor: UIColor {
        set {
            self.borderColor = newValue.cgColor
        }
        
        get {
            return UIColor(cgColor: self.borderColor!)
        }
    }
}
