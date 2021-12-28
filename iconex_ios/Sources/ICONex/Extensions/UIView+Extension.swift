//
//  UIView+Extension.swift
//  iconex_ios
//
//  Created by a1ahn on 19/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension UIView {
    func setCurrentPage() {
        self.constraints.forEach {
            if $0.firstAttribute == .width {
                $0.constant = 14
            }
        }
        self.corner(3)
        self.backgroundColor = .white
        self.clipsToBounds = false
        self.layoutIfNeeded()
    }
    
    func setNonCurrentPage() {
        self.constraints.forEach {
            if $0.firstAttribute == .width {
                $0.constant = 6
            }
        }
        self.corner(3)
        self.backgroundColor = UIColor.init(white: 1, alpha: 0.5)
        self.clipsToBounds = false
        self.layoutIfNeeded()
    }
}

// MARK : UIView
extension UIView {
    func border(_ width: CGFloat, _ color: UIColor) {
        self.layer.borderWidth = width
        self.layer.borderColor = color.cgColor
    }
    
    func corner(_ radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
    
    func mintBox() {
        self.corner(8)
        self.border(0.5, .mint6)
        self.backgroundColor = .mint4
    }
}

extension UIView {
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

// ToolTip
extension UIView {
    // mini tooltip
    func showMiniToolTip(positionY: CGFloat) {
        let message = "ICON P-Rep Election"
        let toolTip = makeMiniToolTip(message, positionY)
        
        showToastView(toolTip)
        hideToastView(toolTip)
    }
    
    func makeMiniToolTip(_ messsage: String, _ positionY: CGFloat) -> UIView {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 12)
        label.textColor = .white
        label.text = messsage
        label.sizeToFit()
        
        let bubbleSize = CGSize(width: label.frame.width + 36,
                                height: label.frame.height + 24)
        
        let bubbleWidth = bubbleSize.width
        let bubbleHeight = bubbleSize.height
        
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: bubbleWidth - 14, y: bubbleHeight-8))
        
        bezierPath.addLine(to: CGPoint(x: bubbleWidth - 14, y: bubbleHeight))
        bezierPath.addLine(to: CGPoint(x: bubbleWidth - 24, y: bubbleHeight-8))
        
        bezierPath.addLine(to: CGPoint(x: 8, y: bubbleHeight-8))
        bezierPath.addCurve(to: CGPoint(x: 0, y: bubbleHeight - 16), controlPoint1: CGPoint(x: 3, y: bubbleHeight-8), controlPoint2: CGPoint(x: 0, y: bubbleHeight - 11))
        bezierPath.addLine(to: CGPoint(x: 0, y: 8))
        bezierPath.addCurve(to: CGPoint(x: 8, y: 0), controlPoint1: CGPoint(x: 0, y: 3), controlPoint2: CGPoint(x: 3, y: 0))
        bezierPath.addLine(to: CGPoint(x: bubbleWidth - 8, y: 0))
        bezierPath.addCurve(to: CGPoint(x: bubbleWidth, y: 8), controlPoint1: CGPoint(x: bubbleWidth-3, y: 0), controlPoint2: CGPoint(x: bubbleWidth, y: 3))
        bezierPath.addLine(to: CGPoint(x: bubbleWidth, y: bubbleHeight - 16))
        bezierPath.addCurve(to: CGPoint(x: bubbleWidth - 8, y: bubbleHeight-8), controlPoint1: CGPoint(x: bubbleWidth, y: bubbleHeight-11), controlPoint2: CGPoint(x: bubbleWidth-3, y: bubbleHeight-8))
        bezierPath.close()
        
        let outgoingMessageLayer = CAShapeLayer()
        outgoingMessageLayer.path = bezierPath.cgPath
        outgoingMessageLayer.frame = CGRect(x: 0,
                                            y: 0,
                                            width: bubbleWidth,
                                            height: bubbleHeight)
        
        outgoingMessageLayer.fillColor = UIColor(white: 38.0 / 255.0, alpha: 0.9).cgColor
        
        let popView = UIView(frame: CGRect(origin: CGPoint(x: self.frame.width-bubbleWidth-36, y: positionY+mySafeAreaInsets.top-label.frame.height), size: CGSize(width: bubbleWidth, height: bubbleHeight)))
        popView.layer.addSublayer(outgoingMessageLayer)
        popView.backgroundColor = .clear
        
        popView.addSubview(label)
        label.textColor = UIColor.init(white: 1, alpha: 0.9)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: popView.centerXAnchor).isActive = true
        label.topAnchor.constraint(equalTo: popView.topAnchor, constant: 8).isActive = true
        label.bottomAnchor.constraint(equalTo: popView.bottomAnchor, constant: -15).isActive = true
        return popView
    }
}

// Toast
extension UIView {
    
    // animation
    func showToastView(_ toastView: UIView) {
        toastView.alpha = 0.0
        
        self.addSubview(toastView)
        
        UIView.animate(withDuration: 0.7, delay: 0.0, options: .curveEaseOut, animations: {
            toastView.alpha = 1.0
        })
    }
    
    func hideToastView(_ toastView: UIView) {
        UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseIn, animations: {
            toastView.alpha = 0.0
        }) { _ in
            toastView.removeFromSuperview()
        }
    }
}

private extension UIView {
    var mySafeAreaInsets: UIEdgeInsets {
        return self.safeAreaInsets
    }
}
