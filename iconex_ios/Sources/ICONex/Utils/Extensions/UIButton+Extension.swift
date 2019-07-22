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
    
    func styleLight() {
        self.setBackgroundImage(UIImage(color: UIColor.lightTheme.background.normal), for: .normal)
        self.setTitleColor(UIColor.lightTheme.text.normal, for: .normal)
        self.setBackgroundImage(UIImage(color: UIColor.lightTheme.background.pressed), for: .highlighted)
        self.setTitleColor(UIColor.lightTheme.text.pressed, for: .highlighted)
        self.setBackgroundImage(UIImage(color: UIColor.lightTheme.background.selected), for: .selected)
        self.setTitleColor(UIColor.lightTheme.text.selected, for: .selected)
        self.setBackgroundImage(UIImage(color: UIColor.lightTheme.background.disabled), for: .disabled)
        self.setTitleColor(UIColor.lightTheme.text.disabled, for: .disabled)
    }
    
    func styleDark() {
        self.setBackgroundImage(UIImage(color: UIColor.darkTheme.background.normal), for: .normal)
        self.setTitleColor(UIColor.darkTheme.text.normal, for: .normal)
        self.setBackgroundImage(UIImage(color: UIColor.darkTheme.background.pressed), for: .highlighted)
        self.setTitleColor(UIColor.darkTheme.text.pressed, for: .highlighted)
        self.setBackgroundImage(UIImage(color: UIColor.darkTheme.background.selected), for: .selected)
        self.setTitleColor(UIColor.darkTheme.text.selected, for: .selected)
        self.setBackgroundImage(UIImage(color: UIColor.darkTheme.background.disabled), for: .disabled)
        self.setTitleColor(UIColor.darkTheme.text.disabled, for: .disabled)
    }
}
