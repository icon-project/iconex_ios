//
//  UILabel+Extension.swift
//  iconex_ios
//
//  Created by a1ahn on 29/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    func size12(text: String, color: UIColor = .black, weight: UIFont.Weight = .regular) {
        set(text: text, size: 12, height: 18/12, color: color, weight: weight)
    }
    
    func size14(text: String, color: UIColor = .black, weight: UIFont.Weight = .regular) {
        set(text: text, size: 14, height: 20/14, color: color, weight: weight)
    }
    
    func size16(text: String, color: UIColor = .black, weight: UIFont.Weight = .regular) {
        set(text: text, size: 16, height: 24/16, color: color, weight: weight)
    }
    
    func size18(text: String, color: UIColor = .black, weight: UIFont.Weight = .regular) {
        set(text: text, size: 18, height: 24/18, color: color, weight: weight)
    }
    
    func set(text: String, size: CGFloat, height: CGFloat, color: UIColor = .black, weight: UIFont.Weight = .regular) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = height
        
        var font: UIFont
        if text.rangeOfCharacter(from: CharacterSet.decimalDigits, options: .caseInsensitive, range: nil) != nil {
            Log("Contains number")
            if weight == .regular {
                font = UIFont(name: "NanumSquareR", size: size)!
            } else {
                font = UIFont(name: "NanumSquareB", size: size)!
            }
        } else {
            font = UIFont.systemFont(ofSize: size, weight: weight)
        }
        
        let attributedString = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraphStyle])
        
        self.attributedText = attributedString
    }
}
