//
//  UIColor+Extension.swift
//  iconex_ios
//
//  Created by a1ahn on 19/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import UIKit

// MARK: UIColor
extension UIColor {
    enum mintButton {
        case normal
        case pressed
        case disabled
        
        var background: UIColor {
            switch self {
            case .normal:
                return .mint3
                
            case .pressed:
                return .mint3
                
            case .disabled:
                return .gray242
            }
        }
            
        var text: UIColor {
            switch self {
            case .normal:
                return .mint1
                
            case .pressed:
                return .mint1
                
            case .disabled:
                return .gray179
            }
        }
    }
    
    enum darkButton {
        case normal
        case pressed
        case disabled
        
        var background: UIColor {
            switch self {
            case .normal:
                return .gray77
                
            case .pressed:
                return UIColor(64, 64, 64)
                
            case .disabled:
                return .gray242
            }
        }
        
        var text: UIColor {
            switch self {
            case .normal, .pressed:
                return .white
                
            case .disabled:
                return .gray179
            }
        }
    }
    
    public enum Step {
        case checked
        case current
        case standBy
        
        var line: UIColor {
            switch self {
            case .checked:
                return UIColor.white
                
            case .current:
                return UIColor.white
                
            case .standBy:
                return UIColor(6, 138, 153)
            }
        }
        
        var text: UIColor {
            switch self {
            case .checked:
                return UIColor(0xFFFFFF, alpha: 0.5)
                
            case .current:
                return UIColor.white
                
            case .standBy:
                return UIColor(6, 138, 153)
            }
        }
    }
    
    static var warn: UIColor {
        return UIColor(242, 48, 48)
    }
    
    convenience init(_ red: Int, _ green: Int, _ blue: Int, _ alpha: CGFloat = 1.0) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }
    
    convenience init(_ hex: Int, alpha: CGFloat = 1.0) {
        self.init(red: CGFloat((hex >> 16) & 0xff), green: CGFloat((hex >> 8) & 0xff), blue: CGFloat(hex & 0xff), alpha: alpha)
    }
    
}
