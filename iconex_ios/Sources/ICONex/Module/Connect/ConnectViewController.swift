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
        
        Tool.rotateAnimation(inView: refresh01)
        Tool.rotateReverseAnimation(inView: refresh02)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Conn.needTranslate {
            do {
                try Conn.translate()
                proceed()
            } catch let e as ConnectError {
                Log("ConnectError - \(e)")
                if e.code == ConnectError.activateDeveloper.code {
                    Conn.redirect = nil
                    let app = UIApplication.shared.delegate as! AppDelegate
                    app.toMain()
                    Tool.toast(message: e.errorDescription!)
                } else {
                    Conn.sendError(error: e)
                }
            } catch {
                Log("error - \(error)")
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
            
            guard let wallet = Manager.wallet.walletBy(address: from, type: "icx") as? ICXWallet else {
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
                
                let call = Call<BigUInt>(from: from, to: to, method: "balanceOf", params: ["_owner": from])
                let request = Manager.icon.service.call(call).execute()
                switch request {
                case .success(let balance):
                    if balance == 0 || balance < requestedValue {
                        Conn.sendError(error: .insufficient(.balance))
                        return false
                    }
                case .failure(let err):
                    Conn.sendError(error: .network(err.errorDescription!))
                    return false
                }
            } else {
                if let balance = Manager.icon.getBalance(wallet: wallet) {
                    if balance == 0 || balance < requestedValue {
                        Conn.sendError(error: ConnectError.insufficient(.balance))
                        return false
                    }
                } else {
                    Conn.sendError(error: .network("Could not connect"))
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
                let bind = storyboard.instantiateViewController(withIdentifier: "BindView")
                self.present(bind, animated: true, completion: nil)
                
            case "JSON-RPC":
                guard let from = Conn.received?.payload?.params.from else { return }
                guard let info = Manager.wallet.walletList.filter({ $0.address == from }).first else {
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
