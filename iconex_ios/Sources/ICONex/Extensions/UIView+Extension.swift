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
    
    // big tooltip
    func showToolTip(positionY: CGFloat, text: String) {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont(name: "AppleSDGothicNeo-Light", size: 12)
        label.textColor = .white
        label.text = text
        label.setLinespace(spacing: 3.5)
        label.sizeToFit()
        
        let bubbleSize = CGSize(width: label.frame.width + 64,
                                height: label.frame.height + 28 + 6 + 8)
        
        let bubbleWidth = bubbleSize.width
        let bubbleHeight = bubbleSize.height
        
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: bubbleWidth - 8, y: bubbleHeight-8))
        bezierPath.addLine(to: CGPoint(x: 26, y: bubbleHeight-8))
        bezierPath.addLine(to: CGPoint(x: 15, y: bubbleHeight))
        bezierPath.addLine(to: CGPoint(x: 15, y: bubbleHeight-8))
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
        
        let popView = UIView(frame: CGRect(origin: CGPoint(x: 16, y: positionY+mySafeAreaInsets.top-label.frame.height), size: CGSize(width: bubbleWidth, height: bubbleHeight)))
        popView.layer.addSublayer(outgoingMessageLayer)
        popView.backgroundColor = .clear
        
        popView.addSubview(label)
        label.textColor = UIColor.init(white: 1, alpha: 0.9)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leadingAnchor.constraint(equalTo: popView.leadingAnchor, constant: 20).isActive = true
        label.topAnchor.constraint(equalTo: popView.topAnchor, constant: 14).isActive = true
        label.bottomAnchor.constraint(equalTo: popView.bottomAnchor, constant: -22).isActive = true
        
        let dismissButton = UIButton()
        dismissButton.frame.size = CGSize(width: 24, height: 24)
        dismissButton.setImage(UIImage(named: "icAppbarCloseW"), for: .normal)
        dismissButton.imageView?.contentMode = .scaleAspectFill
        dismissButton.imageRect(forContentRect: CGRect(x: 0, y: 0, width: 10, height: 10))
        dismissButton.imageEdgeInsets = UIEdgeInsets(top: 7, left: 0, bottom: 7, right: 0)
        
        dismissButton.addTarget(self, action: #selector(dismissTooltip(_:)), for: .touchUpInside)
        
        popView.addSubview(dismissButton)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 10).isActive = true
        dismissButton.trailingAnchor.constraint(equalTo: popView.trailingAnchor, constant: -10).isActive = true
        dismissButton.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
        
        self.addSubview(popView)
    }
    
    @objc func dismissTooltip(_ popView: UIView) {
        popView.superview!.removeFromSuperview()
    }
}

// Toast
extension UIView {
    
    static func makeToast(_ message: String) -> UIView {
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 14)
        
        let toastView = UIView()
        toastView.translatesAutoresizingMaskIntoConstraints = false
        
        toastView.backgroundColor = UIColor(white: 38.0 / 255.0, alpha: 0.9)
        toastView.layer.cornerRadius = 8
        
        toastView.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 12).isActive = true
        label.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -12).isActive = true
        label.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 20).isActive = true
        label.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -20).isActive = true
        
        return toastView
        
    }
    
    static func makeVoteToast(count: Int) -> UIView {
        let toastView = UIView()
        toastView.backgroundColor = UIColor(white: 38.0 / 255.0, alpha: 0.9)
        toastView.layer.cornerRadius = 8
        toastView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        
        toastView.addSubview(label)
        label.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 16).isActive = true
        label.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -16).isActive = true
        label.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 16).isActive = true
        label.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -16).isActive = true
        
        let mutAttr = NSMutableAttributedString(string: "\(count)/10", attributes: [.font: UIFont(name: "NanumSquareB", size: 14)!, .foregroundColor: UIColor.white])
        mutAttr.append(NSAttributedString(string: "PRepView.Toast.MyVotes".localized, attributes: [.font: UIFont(name: "AppleSDGothicNeo-Regular", size: 14)!, .foregroundColor: UIColor.white]))
        
        label.attributedText = mutAttr
        label.adjustsFontSizeToFitWidth = true
        
        return toastView
    }
    
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
