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
        return !isPreventPaste
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
//    @discardableResult override func becomeFirstResponder() -> Bool {
//        self.layer.borderWidth = 1.0
//        self.layer.customBorderColor = UIColor.buttonBorderC.selected
//        self.superview?.bringSubview(toFront: self)
//        
//        return super.becomeFirstResponder()
//    }
//    
//    @discardableResult override func resignFirstResponder() -> Bool {
//        self.layer.borderWidth = 1.0
//        self.layer.customBorderColor = UIColor.buttonBorderC.normal
//        self.superview?.sendSubview(toBack: self)
//        super.resignFirstResponder()
//        return true
//    }
    
//    override func textRect(forBounds bounds: CGRect) -> CGRect {
//        return CGRect(x: bounds.origin.x + 15, y: bounds.origin.y + 2, width: bounds.size.width - 15, height: bounds.size.height - 2)
//    }
//
//    override func editingRect(forBounds bounds: CGRect) -> CGRect {
//        return self.textRect(forBounds: bounds)
//    }
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
