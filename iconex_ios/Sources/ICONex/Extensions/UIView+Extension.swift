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
    func showToolTip(sizeY: CGFloat) {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont(name: "AppleSDGothicNeo-Light", size: 12)
        label.textColor = .white
        label.text = "이미 투표가 반영된 P-Rep은 삭제가 불가능합니다.\nVoting Power를 0으로 설정 후, Vote 버튼을 클릭해주세요."
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
        
        let popView = UIView(frame: CGRect(origin: CGPoint(x: 16, y: sizeY+mySafeAreaInsets.top-label.frame.height), size: CGSize(width: bubbleWidth, height: bubbleHeight)))
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
        
        dismissButton.rx.tap.asControlEvent()
            .subscribe { _ in
                popView.removeFromSuperview()
        }
        
        popView.addSubview(dismissButton)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 10).isActive = true
        dismissButton.trailingAnchor.constraint(equalTo: popView.trailingAnchor, constant: -10).isActive = true
        dismissButton.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
        
        self.addSubview(popView)
    }
}

// Toast
extension UIView {
    // normalm toast
    func showToast(message: String) {
        let toastView = makeToast(message)
        
        showToastView(toastView)
        hideToastView(toastView)
    }
    
    // vote toast
    func showVoteToast(count: Int) {
        let toastView = makeVoteToast(count: count)
        
        showToastView(toastView)
        hideToastView(toastView)
    }
    
    func makeToast(_ message: String) -> UIView {
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 14)
        
        let toastView = UIView(frame: CGRect(x: 20, y: self.frame.height-mySafeAreaInsets.bottom-40-46, width: self.frame.width-40, height: 40))
        
        toastView.backgroundColor = UIColor(white: 38.0 / 255.0, alpha: 0.9)
        toastView.layer.cornerRadius = 8
        
        toastView.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 12).isActive = true
        label.centerXAnchor.constraint(equalTo: toastView.centerXAnchor).isActive = true
        
        return toastView
        
    }
    
    func makeVoteToast(count: Int) -> UIView {
        let toastView = UIView(frame: CGRect(x: 20, y: self.frame.height-mySafeAreaInsets.bottom-40-46, width: self.frame.width-40, height: 40))
        toastView.backgroundColor = UIColor(white: 38.0 / 255.0, alpha: 0.9)
        toastView.layer.cornerRadius = 8
        
        let label1 = UILabel()
        label1.text = "\(count)"
        label1.textColor = .white
        label1.font = UIFont(name: "NanumSquareOTF", size: 14)
        label1.sizeToFit()
        
        let label2 = UILabel()
        label2.text = " / "
        label2.textColor = UIColor.init(white: 1, alpha: 0.5)
        label2.font = UIFont(name: "NanumSquareOTF", size: 14)
        label2.sizeToFit()
        
        let label3 = UILabel()
        label3.text = "10"
        label3.textColor = UIColor.init(white: 1, alpha: 0.5)
        label3.font = UIFont(name: "NanumSquareOTF", size: 14)
        label3.sizeToFit()
        
        let label4 = UILabel()
        label4.text = "My Votes에 추가 완료"
        label4.textColor = .white
        label4.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 14)
        label4.sizeToFit()
        
        let containerView = UIView()
        
        containerView.addSubview(label1)
        label1.translatesAutoresizingMaskIntoConstraints = false
        label1.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        
        containerView.addSubview(label2)
        label2.translatesAutoresizingMaskIntoConstraints = false
        label2.leadingAnchor.constraint(equalTo: label1.trailingAnchor).isActive = true
        
        containerView.addSubview(label3)
        label3.translatesAutoresizingMaskIntoConstraints = false
        label3.leadingAnchor.constraint(equalTo: label2.trailingAnchor).isActive = true
        
        containerView.addSubview(label4)
        label4.translatesAutoresizingMaskIntoConstraints = false
        label4.leadingAnchor.constraint(equalTo: label3.trailingAnchor, constant: 18).isActive = true
        label4.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        
        toastView.addSubview(containerView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 12).isActive = true
        containerView.centerXAnchor.constraint(equalTo: toastView.centerXAnchor).isActive = true
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
        if #available(iOS 11.0, *) {
            return self.safeAreaInsets
        } else {
            return .zero
        }
    }
}
