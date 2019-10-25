//
//  IXToolTip.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 2019/10/25.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import UIKit

class IXToolTip {
    var list: [UIView] = [UIView]()
    
    func show(positionY: CGFloat, message: String, parent: UIView) {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont(name: "AppleSDGothicNeo-Light", size: 12)
        label.textColor = .white
        label.text = message
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
        
        let popView = UIView(frame: CGRect(origin: CGPoint(x: 16, y: positionY-label.frame.height), size: CGSize(width: bubbleWidth, height: bubbleHeight)))
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
        
        if self.list.count > 0 {
            dismissLastToolTip()
        }
        
        self.list.append(popView)
        parent.addSubview(popView)
    }
    
    @objc func dismissTooltip(_ popView: UIView) {
        self.list.removeLast()
        popView.superview!.removeFromSuperview()
    }
    
    func dismissLastToolTip() {
        let lastToolTip = self.list.popLast()
        lastToolTip?.removeFromSuperview()
    }
}
