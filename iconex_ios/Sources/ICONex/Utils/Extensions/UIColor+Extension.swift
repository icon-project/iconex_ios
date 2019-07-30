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
    public enum darkTheme {
        case background
        case text
        
        var normal: UIColor {
            switch self {
            case .background:
                return UIColor(38, 38, 38)
                
            case .text:
                return UIColor(255, 255, 255)
            }
        }
        
        var selected: UIColor {
            switch self {
            case .background:
                return UIColor(0, 0, 0)
                
            case .text:
                return UIColor(255, 255, 255)
            }
        }
        
        var pressed: UIColor {
            switch self {
            case .background:
                return UIColor(0, 0, 0)
                
            case .text:
                return UIColor(255, 255, 255)
            }
        }
        
        var disabled: UIColor {
            switch self {
            case .background:
                return UIColor(230, 230, 230)
                
            case .text:
                return UIColor(179, 179, 179)
            }
        }
    }
    
    public enum lightTheme {
        case background
        case text
        
        var normal: UIColor {
            switch self {
            case .background:
                return UIColor(26, 170, 186)
                
            case .text:
                return UIColor.white
            }
        }
        
        var selected: UIColor {
            switch self {
            case .background:
                return UIColor(18, 117, 128)
                
            case .text:
                return UIColor.white
            }
        }
        
        var pressed: UIColor {
            switch self {
            case .background:
                return UIColor(18, 117, 128)
                
            case .text:
                return UIColor.white
            }
        }
        
        var disabled: UIColor {
            switch self {
            case .background:
                return UIColor(230, 230, 230)
                
            case .text:
                return UIColor(179, 179, 179)
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
