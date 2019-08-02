//
//  UILabel+Extension.swift
//  iconex_ios
//
//  Created by sweeepty on 29/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    func size12(text: String, color: UIColor = .black, weight: UIFont.Weight = .regular, align: NSTextAlignment = .left) {
        set(text: text, size: 12, height: 18, color: color, weight: weight, align: align)
    }
    
    func size14(text: String, color: UIColor = .black, weight: UIFont.Weight = .regular, align: NSTextAlignment = .left) {
        set(text: text, size: 14, height: 20, color: color, weight: weight, align: align)
    }
    
    func size16(text: String, color: UIColor = .black, weight: UIFont.Weight = .regular, align: NSTextAlignment = .left) {
        set(text: text, size: 16, height: 24, color: color, weight: weight, align: align)
    }
    
    func size18(text: String, color: UIColor = .black, weight: UIFont.Weight = .regular, align: NSTextAlignment = .left) {
        set(text: text, size: 18, height: 24, color: color, weight: weight, align: align)
    }
    
    func set(text: String, size: CGFloat, height: CGFloat, color: UIColor = .black, weight: UIFont.Weight = .regular, align: NSTextAlignment = .left) {
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
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = height - size
        paragraphStyle.alignment = align
        
        let attributedString = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraphStyle])
        
        self.attributedText = attributedString
    }
    
    func setLinespace(spacing: CGFloat) {
        if let text = self.text {
            let attributeString = NSMutableAttributedString(string: text)
            let style = NSMutableParagraphStyle()
            
            style.lineSpacing = spacing
            attributeString.addAttribute(NSAttributedString.Key.paragraphStyle,
                                         value: style,
                                         range: NSMakeRange(0, attributeString.length))
            
            self.attributedText = attributeString
        }
    }
}