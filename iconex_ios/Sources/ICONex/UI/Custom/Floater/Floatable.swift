//
//  Floatable.swift
//  iconex_ios
//
//  Created by a1ahn on 27/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

enum FloaterType {
    case wallet
    case vote
    case search
}

protocol Floatable {
    var floater: Floater { get }
}

class Floater {
    let type: FloaterType
    let contentView: UIView
    let button: UIButton
    
    init(type: FloaterType) {
        self.type = type
        
        let frameView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        frameView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        frameView.layer.cornerRadius = 25
        frameView.backgroundColor = .clear
        frameView.layer.shadowColor = UIColor.black.cgColor
        frameView.layer.shadowOpacity = 0.15
        frameView.layer.shadowRadius = 5
        frameView.layer.shadowOffset = CGSize(width: 0, height: 7)
        
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        frameView.addSubview(button)
        
        var image: UIImage
        switch type {
        case .vote:
            image = #imageLiteral(resourceName: "icVoteMenu")
            button.backgroundColor = UIColor(65, 65, 65)
            
        case .wallet:
            image = #imageLiteral(resourceName: "icDetailMenu")
            button.backgroundColor = UIColor(65, 65, 65)
            
        case .search:
            image = #imageLiteral(resourceName: "icAppbarSearch")
            button.backgroundColor = UIColor(255, 255, 255, 0.9)
        }
        
        button.setImage(image, for: .normal)
        button.corner(25)
        
        contentView = frameView
        self.button = button
        contentView.alpha = 0.0
        
        switch type {
        case .vote:
            break
            
        case .wallet:
            break
            
        default:
            break
        }
    }
    
    func pop(_ controller: UIViewController? = nil) {
        let floatMenu = UIStoryboard(name: "FloatButton", bundle: nil).instantiateInitialViewController() as! FloatViewController
        bzz()
        floatMenu.type = self.type
        floatMenu.pop(actionTarget: controller)
    }
}
extension Floatable where Self: BaseViewController {
    func attach() {
        self.view.addSubview(floater.contentView)
        floater.contentView.frame = CGRect(x: view.frame.width - (25 + 50), y: view.frame.height - (45 + 50 + self.view.safeAreaInsets.bottom), width: 50, height: 50)
        floater.contentView.transform = CGAffineTransform().scaledBy(x: 0.1, y: 0.1)
        
        Log("Attach - \(floater.contentView)")
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.floater.contentView.alpha = 1.0
            self.floater.contentView.transform = .identity
            Log("Attached - \(self.floater.contentView)")
        }, completion: { _ in
            
        })
    }
    
    func detach() {
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.floater.contentView.alpha = 0.0
            self.floater.contentView.transform = CGAffineTransform().scaledBy(x: 0.1, y: 0.1)
        }, completion: { _ in
            self.floater.contentView.removeFromSuperview()
            self.floater.contentView.transform = .identity
        })
    }

}
