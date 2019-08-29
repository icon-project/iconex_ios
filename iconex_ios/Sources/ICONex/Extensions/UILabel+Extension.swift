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
    func size11(text: String, color: UIColor = .black, weight: UIFont.Weight = .regular, align: NSTextAlignment = .left) {
        set(text: text, size: 11, height: 13, color: color, weight: weight, align: align)
    }
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
    
    func size20(text: String, color: UIColor = .black, weight: UIFont.Weight = .regular, align: NSTextAlignment = .left) {
        set(text: text, size: 20, height: 24, color: color, weight: weight, align: align)
    }
    
    func setBalanceAttr(text: String, color: UIColor = .white, weight: UIFont.Weight = .light, align: NSTextAlignment = .center) {
        set(text: text, size: 42, height: 47, color: color, weight: .light, align: align)
    }

    func set(text: String, size: CGFloat, height: CGFloat, color: UIColor = .black, weight: UIFont.Weight = .regular, align: NSTextAlignment = .left, lineBreak: NSLineBreakMode = NSLineBreakMode.byTruncatingTail) {
        var font: UIFont
        
        let digitSet = CharacterSet.decimalDigits
        let charSet = digitSet.union(CharacterSet(charactersIn: ",."))
        
        if text.rangeOfCharacter(from: charSet.inverted, options: .caseInsensitive, range: nil) != nil {
            font = UIFont.systemFont(ofSize: size, weight: weight)
        } else {
            if weight == .regular {
                font = UIFont(name: "NanumSquareR", size: size)!
            } else {
                font = UIFont(name: "NanumSquareB", size: size)!
            }
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = height - size - (font.lineHeight - font.pointSize)
        paragraphStyle.alignment = align
        paragraphStyle.lineBreakMode = lineBreak
        
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
