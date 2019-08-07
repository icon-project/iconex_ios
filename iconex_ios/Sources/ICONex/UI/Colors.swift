//
//  Colors.swift
//  iconex_ios
//
//  Created by a1ahn on 29/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import UIKit

enum SymbolColor {
    case A, B, C, D, E, F, G, H, I, J, K, L
    
    var background: UIColor {
        switch self {
        case .A:
            return #colorLiteral(red: 0.3058823529, green: 0.5647058824, blue: 0.8705882353, alpha: 1)
            
        case .B:
            return #colorLiteral(red: 0.4509803922, green: 0.3607843137, blue: 0.8, alpha: 1)
            
        case .C:
            return #colorLiteral(red: 0.7098039216, green: 0.2784313725, blue: 0.8, alpha: 1)
            
        case .D:
            return #colorLiteral(red: 0.2509803922, green: 0.6392156863, blue: 0.2392156863, alpha: 1)
            
        case .E:
            return #colorLiteral(red: 0.9019607843, green: 0.4156862745, blue: 0.1607843137, alpha: 1)
            
        case .F:
            return #colorLiteral(red: 0.5019607843, green: 0.3254901961, blue: 0.2235294118, alpha: 1)
            
        case .G:
            return #colorLiteral(red: 0.9019607843, green: 0.6901960784, blue: 0, alpha: 1)
            
        case .H:
            return #colorLiteral(red: 0.9019607843, green: 0.2705882353, blue: 0.8274509804, alpha: 1)
            
        case .I:
            return #colorLiteral(red: 0.2784313725, green: 0.3294117647, blue: 1, alpha: 1)
            
        case .J:
            return #colorLiteral(red: 0.4431372549, green: 0.7215686275, blue: 0, alpha: 1)
            
        case .K:
            return #colorLiteral(red: 0.9333333333, green: 0.2196078431, blue: 0.3647058824, alpha: 1)
            
        case .L:
            return #colorLiteral(red: 0.3294117647, green: 0.4509803922, blue: 0.2705882353, alpha: 1)
        }
    }
}

extension UIColor {
    
    /// (0, 162, 184)
    static let mint1 = UIColor(0, 162, 184)
    /// (0, 180, 204)
    static let mint2 = UIColor(0, 180, 204)
    /// (182, 235, 242)
    static let mint3 = UIColor(182, 235, 242)
    /// (245, 254, 255)
    static let mint4 = UIColor(245, 254, 255)
    /// (0, 135, 153)
    static let mint5 = UIColor(0, 135, 153)
    /// (182, 235, 242)
    static let mint6 = UIColor(182, 235, 242)
    
    static let gray77 = UIColor(77, 77, 77)
    static let gray128 = UIColor(128, 128, 128)
    static let gray179 = UIColor(179, 179, 179)
    static let gray230 = UIColor(230, 230, 230)
    static let gray242 = UIColor(242, 242, 242)
    static let gray250 = UIColor(250, 250, 250)
    
    /// (242, 88, 73)
    static let error1 = UIColor(242, 88, 73)
    /// (255, 239, 237)
    static let error2 = UIColor(255, 239, 237)
    /// (255, 248, 247)
    static let error3 = UIColor(255, 248, 247)
}
