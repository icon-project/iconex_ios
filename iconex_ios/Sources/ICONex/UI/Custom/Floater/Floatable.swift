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
import ICONKit
import BigInt

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
    
    var token: Token? = nil
    
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
        contentView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.contentView.alpha = 1.0
            self.contentView.transform = .identity
        }, completion: { _ in
            
        })
    }
    
    func removeFloater() {
        guard isAttached else { return }
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.contentView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            self.contentView.alpha = 0.0
        }, completion: { finished in
            if finished {
                self.contentView.removeFromSuperview()
                self.contentView.transform = .identity
                self.attached = false
            }
        })
    }
    
    func showMenu(wallet: ICXWallet, token: Token? = nil, _ controller: UIViewController? = nil) {
        targetAction = controller
        let floatMenu = UIStoryboard(name: "FloatButton", bundle: nil).instantiateInitialViewController() as! FloatViewController
        
        switch type {
        case .vote:
            floatMenu.headerAction = {
                let prep = UIStoryboard(name: "Vote", bundle: nil).instantiateViewController(withIdentifier: "PRepListView") as! PRepListViewController
                prep.wallet = self.delegate.selectedWallet
                self.targetAction?.navigationController?.pushViewController(prep, animated: true)
            }
            floatMenu.itemAction1 = {
//                guard let balance = wallet.balance, balance >= BigUInt(5).convert(unit: ICONKit.Unit.icx) else {
//                    Alert.basic(title: "Floater.Alert.Stake".localized, leftButtonTitle: "Common.Confirm".localized).show()
//                    return }
                
                Alert.password(wallet: wallet, returnAction: { pk in
                    let stake = UIStoryboard(name: "Stake", bundle: nil).instantiateInitialViewController() as! StakeViewController
                    stake.wallet = self.delegate.selectedWallet
                    stake.key = PrivateKey(hex: Data(hex: pk))
                    self.targetAction?.show(stake, sender: self)
                }).show()
            }
            floatMenu.itemAction2 = {
                guard let votingPower = Manager.iiss.votingPower(icx: wallet), votingPower > 0 else {
                    Alert.basic(title: "Floater.Alert.Vote".localized, leftButtonTitle: "Common.Confirm".localized).show()
                    return
                }
                
                Alert.password(wallet: wallet, returnAction: { pk in
                    let vote = UIStoryboard(name: "Vote", bundle: nil).instantiateInitialViewController() as! VoteMainViewController
                    vote.isPreps = false
                    vote.wallet = self.delegate.selectedWallet
                    vote.key = PrivateKey(hex: Data(hex: pk))
                    self.targetAction?.show(vote, sender: self)
                }).show()
            }
            
            floatMenu.itemAction3 = {
                Alert.password(wallet: wallet, returnAction: { pk in
                    let iscore = UIStoryboard(name: "IScore", bundle: nil).instantiateInitialViewController() as! IScoreDetailViewController
                    iscore.wallet = self.delegate.selectedWallet
                    iscore.key = PrivateKey(hex: Data(hex: pk))
                    self.targetAction?.show(iscore, sender: self)
                }).show()
            }
            
        case .wallet:
            floatMenu.itemAction1 = {
                
            }
            
            floatMenu.itemAction2 = {
                Alert.password(wallet: wallet, returnAction: { privateKey in
                    let send = UIStoryboard(name: "Send", bundle: nil).instantiateViewController(withIdentifier: "SendICX") as! SendICXViewController
                    send.walletInfo = wallet
                    send.token = token
                    send.privateKey = PrivateKey(hex: Data(hex: privateKey))
                    
                    send.sendHandler = { isSuccess in
                        app.topViewController()?.view.showToast(message: isSuccess ? "Send.Success".localized : "Error.CommonError".localized)
                    }
                    
                    app.topViewController()?.present(send, animated: true, completion: nil)
                }).show()
            }
            
        default:
            break
        }
        
        
        bzz()
        floatMenu.type = self.type
        floatMenu.pop()
    }
    
    func showMenu(ethWallet: ETHWallet, _ controller: UIViewController? = nil) {
        targetAction = controller
        let floatMenu = UIStoryboard(name: "FloatButton", bundle: nil).instantiateInitialViewController() as! FloatViewController
        
        floatMenu.itemAction1 = {
            
        }
        
        floatMenu.itemAction2 = {
            
            Alert.password(wallet: ethWallet, returnAction: { privateKey in
                let send = UIStoryboard(name: "Send", bundle: nil).instantiateViewController(withIdentifier: "SendETH") as! SendETHViewController
                send.walletInfo = ethWallet
                send.privateKey = privateKey
                
                send.handler = { isSuccess in
                    app.topViewController()?.view.showToast(message: isSuccess ? "Send.Success".localized : "Error.CommonError".localized)
                }
                
                app.topViewController()?.present(send, animated: true, completion: nil)
            }).show()
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
