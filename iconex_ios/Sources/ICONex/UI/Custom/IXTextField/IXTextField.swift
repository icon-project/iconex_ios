//
//  IXTextField.swift
//  iconex_ios
//
//  Created by a1ahn on 29/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class IXTextField: UITextField {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        for subview in subviews {
            if let label = subview as? UILabel {
                label.minimumScaleFactor = 0.5
                label.adjustsFontSizeToFitWidth = true
            }
        }
    }
    
    var canPaste:Bool = true
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(UIResponderStandardEditActions.paste(_:)),
             #selector(UIResponderStandardEditActions.cut(_:)),
             #selector(UIResponderStandardEditActions.copy(_:)),
             #selector(UIResponderStandardEditActions.select(_:)),
             #selector(UIResponderStandardEditActions.selectAll(_:)):
            return canPaste
            
        default:
            return false
        }
    }
}
