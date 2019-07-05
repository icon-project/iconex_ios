//
//  ConnectViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import BigInt
import ICONKit

class ConnectViewController: BaseViewController {
    @IBOutlet weak var refresh01: UIImageView!
    @IBOutlet weak var refresh02: UIImageView!
    
    var didProceed: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        balanceListDidChanged().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            if Conn.isTranslated {
                self?.proceed()
            }
        }).disposed(by: disposeBag)
        
        
        Tools.rotateAnimation(inView: refresh01)
        Tools.rotateReverseAnimation(inView: refresh02)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Conn.needTranslate {
            do {
                try Conn.translate()
                proceed()
            } catch let e as ConnectError {
                Log.Debug("ConnectError - \(e)")
                Conn.sendError(error: e)
            } catch {
                Log.Debug("error - \(error)")
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
            guard WManager.walletInfoList.count > 0 else {
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
            
            guard WManager.loadWalletBy(address: from, type: .icx) != nil else {
                Conn.sendError(error: .notFound(.address))
                return false
            }
            
            guard let info = WManager.walletInfoList.filter({ $0.address == from }).first else { return false }
            
            var requestedValue: BigUInt = 0
            
            if let value = Conn.received?.payload?.params.value {
                guard let converted = BigUInt(value.prefix0xRemoved(), radix: 16) else {
                    Conn.sendError(error: ConnectError.invalidParameter(.value))
                    return false
                }
                requestedValue = converted
            }
            
            if Conn.tokenSymbol != nil, Conn.tokenDecimal != nil {
                if let balance = Balance.tokenBalanceList[from]?[to] {
                    if balance == 0 || balance < requestedValue {
                        Conn.sendError(error: .insufficient(.balance))
                        return false
                    }
                } else if !Balance.isBalanceLoadCompleted {
                    return false
                } else {
                    Conn.sendError(error: .network("Could not fetch balance."))
                    return false
                }
            } else {
                if let balance = Balance.walletBalanceList[info.address] {
                    if balance == 0 || balance < requestedValue {
                        Conn.sendError(error: ConnectError.insufficient(.balance))
                        return false
                    }
                } else if !Balance.isBalanceLoadCompleted {
                    return false
                } else {
                    Conn.sendError(error: ConnectError.network("Could not fetch balance."))
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
        if (Conn.auth && Tools.isPasscode()) || !Tools.isPasscode() {
            switch action {
            case "bind":
                let bind = storyboard.instantiateViewController(withIdentifier: "BindView")
                self.present(bind, animated: true, completion: nil)
                
            case "JSON-RPC":
                guard let from = Conn.received?.payload?.params.from else { return }
                guard let info = WManager.walletInfoList.filter({ $0.address == from }).first else {
                    Conn.sendError(error: ConnectError.notFound(.wallet(from)))
                    return
                }
                let sign = storyboard.instantiateViewController(withIdentifier: "BindPasswordView") as! BindPasswordViewController
                sign.selectedWallet = info
                self.present(sign, animated: true, completion: nil)
                
            default:
                Conn.sendError(error: ConnectError.notFound(.method))
                return
            }
        }
    }
}
