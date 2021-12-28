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
    
    func show(positionY: CGFloat, message: String, parent: UIView, source: UIView) {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont(name: "AppleSDGothicNeo-Light", size: 12)
        label.textColor = .white
        label.text = message
        label.setLinespace(spacing: 3.5)
        label.sizeToFit()
        
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0, y: 4))
        bezierPath.addLine(to: CGPoint(x:8, y: 0))
        bezierPath.addLine(to: CGPoint(x: 8, y: 8))
        bezierPath.close()
        
        let triangle = CAShapeLayer()
        triangle.path = bezierPath.cgPath
        triangle.frame = CGRect(x: 0, y: 0, width: 8, height: 8)
        triangle.fillColor = UIColor(38, 38, 38, 0.9).cgColor
        
        let triView = UIView()
        triView.backgroundColor = .clear
        triView.translatesAutoresizingMaskIntoConstraints = false
        triView.layer.addSublayer(triangle)
        
        let container = UIView()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let popView = UIView()
        popView.translatesAutoresizingMaskIntoConstraints = false
        popView.backgroundColor = UIColor(38, 38, 38, 0.9)
        popView.corner(8)
        popView.addSubview(label)
        label.textColor = UIColor.init(white: 1, alpha: 0.9)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leadingAnchor.constraint(equalTo: popView.leadingAnchor, constant: 20).isActive = true
        label.topAnchor.constraint(equalTo: popView.topAnchor, constant: 14).isActive = true
        label.bottomAnchor.constraint(equalTo: popView.bottomAnchor, constant: -14).isActive = true
        
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
        
        container.addSubview(triView)
        triView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: -8).isActive = true
        triView.widthAnchor.constraint(equalToConstant: 8).isActive = true
        triView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        triView.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
        
        container.addSubview(popView)
        popView.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        popView.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        popView.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        popView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        
        self.list.append(container)
        parent.addSubview(container)
        container.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 52).isActive = true
        container.trailingAnchor.constraint(lessThanOrEqualTo: parent.trailingAnchor, constant: -16).isActive = true
        container.centerYAnchor.constraint(equalTo: source.centerYAnchor).isActive = true
        container.topAnchor.constraint(greaterThanOrEqualTo: parent.topAnchor, constant: 0).isActive = true
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
