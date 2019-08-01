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
    
    func cornered() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 4
        self.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    }
    
    func mint() {
        setBackgroundImage(UIImage(color: .mint2), for: .normal)
        setTitleColor(.white, for: .normal)
        setBackgroundImage(UIImage(color: UIColor.mintButton.disabled.background), for: .disabled)
        setTitleColor(UIColor.mintButton.disabled.text, for: .disabled)
        setTitleColor(UIColor(0, 135, 153), for: .highlighted)
        setBackgroundImage(color: .mint2, state: .highlighted)
        titleLabel?.font = .systemFont(ofSize: 16)
    }
    
    func lightMint() {
        setBackgroundImage(UIImage(color: UIColor.mintButton.normal.background), for: .normal)
        setTitleColor(UIColor.mintButton.normal.text, for: .normal)
        setBackgroundImage(UIImage(color: UIColor.mintButton.disabled.background), for: .disabled)
        setTitleColor(UIColor.mintButton.disabled.text, for: .disabled)
        titleLabel?.font = .systemFont(ofSize: 16)
    }
    
    func lightMintRounded() {
        lightMint()
        corner(12)
    }
    
    func dark() {
        setBackgroundImage(UIImage(color: UIColor.darkButton.normal.background), for: .normal)
        setTitleColor(UIColor.darkButton.normal.text, for: .normal)
        setBackgroundImage(UIImage(color: UIColor.darkButton.disabled.background), for: .disabled)
        setTitleColor(UIColor.darkButton.disabled.text, for: .disabled)
        titleLabel?.font = .systemFont(ofSize: 16)
    }
    
    func darkRounded() {
        dark()
        corner(12)
    }
    
    func round02() {
        setBackgroundImage(UIImage(color: .gray242), for: .normal)
        setTitleColor(.gray77, for: .normal)
        setBackgroundImage(UIImage(color: .gray230), for: .highlighted)
        setBackgroundImage(UIImage(color: .gray242), for: .disabled)
        setTitleColor(.gray179, for: .disabled)
        titleLabel?.font = .systemFont(ofSize: 16)
        corner(12)
    }
    
    func line01() {
        setBackgroundImage(UIImage(color: .white), for: .normal)
        setTitleColor(.gray128, for: .normal)
        setBackgroundImage(UIImage(color: .gray250), for: .highlighted)
        setTitleColor(UIColor(217, 217, 217), for: .disabled)
        border(1, .gray230)
        titleLabel?.font = .systemFont(ofSize: 12)
    }
    
    func line02() {
        setBackgroundImage(UIImage(color: .white), for: .normal)
        setTitleColor(.gray128, for: .normal)
        setBackgroundImage(UIImage(color: .gray250), for: .highlighted)
        setTitleColor(UIColor(217, 217, 217), for: .disabled)
        border(1, .gray230)
        titleLabel?.font = .systemFont(ofSize: 16)
    }
}
