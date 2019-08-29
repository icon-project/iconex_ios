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
    var selectedWallet: ICXWallet? { get }
    var floater: Floater { get }
}

class Floater {
    let type: FloaterType
    let contentView: UIView
    let button: UIButton
    
    var isAttached: Bool {
        return attached
    }
    private var attached: Bool = false
    
    private var targetAction: UIViewController?
    
    var delegate: Floatable!
    
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
    
    func addFloater(view: UIView) {
        guard !isAttached else {
            return
        }
        view.addSubview(contentView)
        attached = true
        contentView.frame = CGRect(x: view.frame.width - (25 + 50), y: view.frame.height - (45 + 50 + view.safeAreaInsets.bottom), width: 50, height: 50)
        contentView.transform = CGAffineTransform().scaledBy(x: 0.1, y: 0.1)
        
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.contentView.alpha = 1.0
            self.contentView.transform = .identity
            Log("Attached - \(self.contentView)")
        }, completion: { _ in
            
        })
    }
    
    func removeFloater() {
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.contentView.alpha = 0.0
            self.contentView.transform = CGAffineTransform().scaledBy(x: 0.1, y: 0.1)
        }, completion: { finished in
            if finished {
                self.contentView.removeFromSuperview()
                self.contentView.transform = .identity
                self.attached = false
            }
        })
    }
    
    func showMenu(_ controller: UIViewController? = nil) {
        targetAction = controller
        let floatMenu = UIStoryboard(name: "FloatButton", bundle: nil).instantiateInitialViewController() as! FloatViewController
        
        switch type {
        case .vote:
            floatMenu.headerAction = {
                let vote = UIStoryboard(name: "Vote", bundle: nil).instantiateInitialViewController() as! VoteMainViewController
                vote.isPreps = true
                vote.wallet = self.delegate.selectedWallet
                self.targetAction?.navigationController?.pushViewController(vote, animated: true)
//                self.targetAction?.show(vote, sender: self)
            }
            floatMenu.itemAction1 = {
                let stake = UIStoryboard(name: "Stake", bundle: nil).instantiateInitialViewController() as! StakeViewController
                stake.wallet = self.delegate.selectedWallet
                self.targetAction?.show(stake, sender: self)
            }
            floatMenu.itemAction2 = {
                let vote = UIStoryboard(name: "Vote", bundle: nil).instantiateInitialViewController() as! VoteMainViewController
                vote.isPreps = false
                vote.wallet = self.delegate.selectedWallet
                self.targetAction?.show(vote, sender: self)
            }
            floatMenu.itemAction3 = {
                let iscore = UIStoryboard(name: "IScore", bundle: nil).instantiateInitialViewController() as! IScoreDetailViewController
                iscore.wallet = self.delegate.selectedWallet
                self.targetAction?.show(iscore, sender: self)
            }
            
        case .wallet:
            break
            
        default:
            break
        }
        
        
        bzz()
        floatMenu.type = self.type
        floatMenu.pop()
    }
}
extension Floatable where Self: BaseViewController {
    func attach() {
        floater.addFloater(view: self.view)
    }
    
    func detach() {
        floater.removeFloater()
    }

}
