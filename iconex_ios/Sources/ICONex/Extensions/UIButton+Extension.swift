//
//  UIButton+Extension.swift
//  iconex_ios
//
//  Created by a1ahn on 19/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import UIKit

// MARK: UIButton
extension UIButton {
    func alignVertical(spacing: CGFloat = 5) {
        guard let imageSize = self.imageView?.image?.size, let text = self.titleLabel?.text, let font = self.titleLabel?.font else {
            return
        }
        
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageSize.width, bottom: -(imageSize.height + spacing), right: 0)
        let labelString = NSString(string: text)
        let titleSize = labelString.size(withAttributes: [NSAttributedString.Key.font: font])
        self.imageEdgeInsets = UIEdgeInsets(top: -(titleSize.height + spacing), left: 0, bottom: 0, right: -titleSize.width)
        let edgeOffset = abs(titleSize.height - imageSize.height) / 2.0
        self.contentEdgeInsets = UIEdgeInsets(top: edgeOffset, left: 0, bottom: edgeOffset, right: 0)
    }
    
    func setBackgroundImage(color: UIColor, state: UIControl.State) {
        let backImage = UIImage(color: color)
        self.setBackgroundImage(backImage, for: state)
    }
    
    func rounded() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = self.layer.bounds.size.height / 2
        self.titleLabel?.font = UIFont.systemFont(ofSize: 17)
    }
    
    func cornered(size: CGFloat = 14) {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 4
        self.titleLabel?.font = UIFont.systemFont(ofSize: size)
    }
    
    func mint() {
        setBackgroundImage(color: .mint2, state: .normal)
        setBackgroundImage(color: .mint2, state: .highlighted)
        setBackgroundImage(color: UIColor.mintButton.disabled.background, state: .disabled)
        setTitleColor(.white, for: .normal)
        setTitleColor(UIColor.mintButton.disabled.text, for: .disabled)
        setTitleColor(UIColor(0, 135, 153), for: .highlighted)
        titleLabel?.font = .systemFont(ofSize: 16)
    }
    
    func lightMint() {
        setBackgroundImage(color: UIColor.mintButton.normal.background, state: .normal)
        setBackgroundImage(color: UIColor.mintButton.pressed.background, state: .highlighted)
        setBackgroundImage(color: UIColor.mintButton.disabled.background, state: .disabled)
        setTitleColor(UIColor.mintButton.normal.text, for: .normal)
        setTitleColor(UIColor.mintButton.pressed.text, for: .highlighted)
        setTitleColor(UIColor.mintButton.disabled.text, for: .disabled)
        titleLabel?.font = .systemFont(ofSize: 16)
    }
    
    func lightMintRounded() {
        lightMint()
        corner(12)
    }
    
    func pickerTab() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 4
        setBackgroundImage(color: UIColor.pickerTab.normal.background, state: .normal)
        setBackgroundImage(color: UIColor.pickerTab.pressed.background, state: .highlighted)
        setBackgroundImage(color: UIColor.pickerTab.selected.background, state: .selected)
        setTitleColor(UIColor.pickerTab.normal.text, for: .normal)
        setTitleColor(UIColor.pickerTab.pressed.text, for: .highlighted)
        setTitleColor(UIColor.pickerTab.selected.text, for: .selected)
        titleLabel?.font = .systemFont(ofSize: 12)
    }
    
    func dark() {
        setBackgroundImage(UIImage(color: UIColor.darkButton.normal.background), for: .normal)
        setBackgroundImage(UIImage(color: UIColor.darkButton.pressed.background), for: .highlighted)
        setBackgroundImage(UIImage(color: UIColor.darkButton.disabled.background), for: .disabled)
        setTitleColor(UIColor.darkButton.normal.text, for: .normal)
        setTitleColor(UIColor.darkButton.pressed.text, for: .highlighted)
        setTitleColor(UIColor.darkButton.disabled.text, for: .disabled)
        titleLabel?.font = .systemFont(ofSize: 16)
    }
    
    func darkRounded() {
        dark()
        corner(12)
    }
    
    func gray() {
        setBackgroundImage(UIImage(color: .gray242), for: .normal)
        setBackgroundImage(UIImage(color: .gray230), for: .highlighted)
        setBackgroundImage(UIImage(color: .gray242), for: .disabled)
        setTitleColor(.gray77, for: .normal)
        setTitleColor(.gray179, for: .disabled)
        titleLabel?.font = .systemFont(ofSize: 16)
    }
    
    func round02() {
        gray()
        corner(12)
    }
    
    func gray77round() {
        setBackgroundImage(UIImage(color: .gray77), for: .normal)
        setBackgroundImage(UIImage(color: .gray64), for: .highlighted)
        setBackgroundImage(UIImage(color: .gray242), for: .disabled)
        setTitleColor(.white, for: .normal)
        setTitleColor(.white, for: .highlighted)
        setTitleColor(.gray179, for: .disabled)
        titleLabel?.font = .systemFont(ofSize: 16)
        corner(12)
    }
    
    func line01() {
        setBackgroundImage(color: .white, state: .normal)
        setBackgroundImage(color: .gray250, state: .highlighted)
        setTitleColor(.gray128, for: .normal)
        setTitleColor(UIColor(217, 217, 217), for: .disabled)
        border(1, .gray230)
        titleLabel?.font = .systemFont(ofSize: 12)
    }
    
    func line02() {
        setBackgroundImage(color: .white, state: .normal)
        setBackgroundImage(color: .gray250, state: .highlighted)
        setTitleColor(.gray128, for: .normal)
        setTitleColor(UIColor(217, 217, 217), for: .disabled)
        border(1, .gray230)
        titleLabel?.font = .systemFont(ofSize: 16)
    }
    
    func roundGray230() {
        self.border(1, .gray230)
        self.cornered(size: 12)
        self.setTitleColor(.gray128, for: .normal)
    }
}
