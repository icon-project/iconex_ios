//
//  ConnectViewController.swift
//  iconex_ios
//
//  Created by Seungyeon Lee on 2019/09/08.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import BigInt
import ICONKit

class ConnectViewController: BaseViewController {
    var didProceed: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
//        Tools.rotateAnimation(inView: refresh01)
//        Tools.rotateReverseAnimation(inView: refresh02)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Conn.needTranslate {
            do {
                try Conn.translate()
                proceed()
            } catch let e as ConnectError {
                Log("ConnectError - \(e)", .debug)
                if e.code == ConnectError.activateDeveloper.code {
                    Conn.redirect = nil
                    let app = UIApplication.shared.delegate as! AppDelegate
                    app.toMain()
                    Tool.toast(message: e.errorDescription!)
                } else {
                    Conn.sendError(error: e)
                }
            } catch {
                Log("error - \(error)", .debug)
                Conn.sendError(error: .invalidRequest)
            }
        }
    }
    
    func proceed() {
        if !didProceed{
            if prepare() {
                action()
            }
        }
    }
    
    func prepare() -> Bool {
        if Conn.action == "bind" {
            guard Manager.wallet.walletList.count > 0 else {
                Conn.sendError(error: .walletEmpty)
                return false
            }
            
            return true
        }
        
        if Conn.action == "JSON-RPC" {
            guard let from = Conn.received?.payload?.params.from else {
                Conn.sendError(error: .notFound(.from))
                return false
            }
            
            guard let to = Conn.received?.payload?.params.to else {
                Conn.sendError(error: .notFound(.to))
                return false
            }
            
            guard Manager.wallet.walletBy(address: from, type: "icx") != nil else {
                Conn.sendError(error: .invalidParameter(.address))
                return false
            }
            
            var requestedValue: BigUInt = 0
            
            if let value = Conn.received?.payload?.params.value {
                guard let converted = BigUInt(value.prefix0xRemoved(), radix: 16) else {
                    Conn.sendError(error: ConnectError.invalidParameter(.value))
                    return false
                }
                requestedValue = converted
            }
            
            if Conn.tokenDecimal != nil {
                guard let data = Conn.received?.payload?.params.data else { return false }
                
                switch data {
                case .call(let call):
                    guard let value = call.params?["_value"] as? String else {
                        Conn.sendError(error: .notFound(.value))
                        return false
                    }
                    guard let bigValue = BigUInt(value.prefix0xRemoved(), radix: 16) else {
                        Conn.sendError(error: .invalidParameter(.value))
                        return false
                    }
                    requestedValue = bigValue
                default: return false
                }
                
                let balance = Manager.balance.getTokenBalance(address: from, contract: to)
                if balance == 0 || balance < requestedValue {
                    Conn.sendError(error: .insufficient(.balance))
                    return false
                }
            } else {
                guard let wallet = Manager.wallet.walletList.filter({ $0.address == from }).first else {
                    Conn.sendError(error: ConnectError.walletEmpty)
                    return false
                }
                
                guard let balance: BigUInt = wallet.balance else {
                    Conn.sendError(error: ConnectError.insufficient(.balance))
                    return false
                }
                
                if balance < requestedValue {
                    Conn.sendError(error: ConnectError.insufficient(.balance))
                    return false
                }
            }
        }
        
        didProceed = true
        return true
    }
    
    func action() {
        let storyboard = UIStoryboard(name: "Connect", bundle: nil)
        guard let action = Conn.action else {
            return
        }
        if (Conn.auth && Tool.isPasscode()) || !Tool.isPasscode() {
            switch action {
            case "bind":
                let bind = storyboard.instantiateViewController(withIdentifier: "BindView") as! BindViewController
//                self.present(bind, animated: true, completion: nil)
                self.presentPanModal(bind)
                
            case "JSON-RPC":
                guard let from = Conn.received?.payload?.params.from else { return }
                guard let info = Manager.wallet.walletList.filter({ $0.address == from }).first else {
                    Conn.sendError(error: ConnectError.notFound(.wallet(from)))
                    return
                }
                let sign = storyboard.instantiateViewController(withIdentifier: "BindPasswordView") as! BindPasswordViewController
                sign.selectedWallet = info as? ICXWallet
                self.presentPanModal(sign)
                
            default:
                Conn.sendError(error: ConnectError.notFound(.method))
                return
            }
        }
    }
}
