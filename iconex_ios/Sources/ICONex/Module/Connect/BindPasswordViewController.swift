//
//  BindPasswordViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 13/11/2018.
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import ICONKit

class BindPasswordViewController: BaseViewController {
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var walletSection: UIView!
    @IBOutlet weak var walletName: UILabel!
    @IBOutlet weak var walletAddress: UILabel!
    @IBOutlet weak var walletAmount: UILabel!
    
    
    @IBOutlet weak var hashSection: UIView!
    @IBOutlet weak var txHash: UILabel!
    
    @IBOutlet weak var dataSection: UIView!
    @IBOutlet weak var dataButton: UIButton!
    
    @IBOutlet weak var inputSection: UIView!
    @IBOutlet weak var passwordInputBox: IXInputBox!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var confirmButton: UIButton!
    
    var selectedWallet: WalletInfo?
    
    private var privateKey: PrivateKey?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }
    
    func initialize() {
        keyboardHeight().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] (height: CGFloat) in
                if height == 0 {
                    self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                } else {
                    var keyboardHeight: CGFloat = height
                    if #available(iOS 11.0, *) {
                        keyboardHeight = keyboardHeight - self.view.safeAreaInsets.bottom
                    }
                    self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
                }
            }).disposed(by: disposeBag)
        
        closeButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: {
            Alert.Confirm(message: "Alert.Connect.Password.Cancel".localized, handler: {
//                self.dismiss(animated: true, completion: nil)
                Conn.sendError(error: ConnectError.userCancel)
            }).show(self)
        }).disposed(by: disposeBag)
        
        scrollView.rx.didEndDecelerating.subscribe(onNext: {
            self.view.endEditing(true)
        }).disposed(by: disposeBag)
        
        dataButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: {
            guard let received = Conn.received else { return }
            guard let params = received.params, let jsonData = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted), let json = String(data: jsonData, encoding: .utf8) else { return }
            let alert = Alert.Basic(message: json)
            alert.setAlignment(.left)
            alert.show(self)
        }).disposed(by: disposeBag)
        
        passwordInputBox.textField.rx.controlEvent(UIControl.Event.editingDidBegin).subscribe(onNext: {
            self.passwordInputBox.setState(.focus, "")
        }).disposed(by: disposeBag)
        passwordInputBox.textField.rx.controlEvent(UIControl.Event.editingDidEnd).subscribe(onNext: {
            self.confirmButton.isEnabled = self.validatePassword()
        }).disposed(by: disposeBag)
        passwordInputBox.textField.rx.controlEvent(UIControl.Event.editingDidEndOnExit).subscribe(onNext: {
            
        }).disposed(by: disposeBag)
        
        confirmButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: {
            guard let received = Conn.received else { return }
            let method = received.method
            if method == "sign" {
                self.requestSign()
            } else if method == "sendICX" {
                self.showSendICX()
            } else if method == "sendToken" {
                self.showSendICX()
            }
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        hashSection.isHidden = true
        navTitle.text = "Alert.Wallet.RequestPassword".localized
        
        let attr = NSAttributedString(string: "Data", attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue, NSAttributedString.Key.foregroundColor: UIColor(128, 128, 128)])
        dataButton.setAttributedTitle(attr, for: .normal)
        
        passwordInputBox.setType(.password)
        passwordInputBox.setState(.normal, "")
        passwordInputBox.textField.placeholder = "Placeholder.InputWalletPassword".localized
        
        confirmButton.setTitle("Common.Confirm".localized, for: .normal)
        confirmButton.styleDark()
        confirmButton.rounded()
        confirmButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let info = selectedWallet, let wallet = WManager.loadWalletBy(info: info) else {
            assertionFailure("Wallet info required")
            return
        }
        
        self.walletName.text = wallet.alias
        self.walletAddress.text = wallet.address
        
        if let balance = wallet.balance {
            self.walletAmount.text = Tools.bigToString(value: balance, decimal: 18, 18, true).currencySeparated()
        } else if let balance = Balance.walletBalanceList[wallet.address!] {
            self.walletAmount.text = Tools.bigToString(value: balance, decimal: 18, 18, true).currencySeparated()
        }
        
        guard let received = Conn.received else { return }
        if received.method == "sign" {
            dataSection.isHidden = false
        } else {
            dataSection.isHidden = true
        }
    }
    
    @discardableResult
    func validatePassword() -> Bool {
        guard let info = selectedWallet, let wallet = WManager.loadWalletBy(info: info) as? ICXWallet else { return false }
        guard let password = passwordInputBox.textField.text, password != "" else { return false }
        
        guard let prvKey = try? wallet.extractICXPrivateKey(password: password), let prvKeyData = prvKey.hexToData() else {
            self.privateKey = nil
            passwordInputBox.setState(.error, "Error.Password.Wrong".localized)
            return false
        }
        
        privateKey = PrivateKey(hexData: prvKeyData)
        
        return true
    }
    
    func requestSign() {
        guard let privateKey = self.privateKey else { return }
        guard let params = Conn.received?.params, let jsonData = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) else { return }
        let password = passwordInputBox.textField.text!
        
        let iconWallet = Wallet(privateKey: privateKey)
        
        do {
            let sign = try iconWallet.getSignature(password: password, data: jsonData)
            
            Conn.sendSignature(sign: sign)
        } catch (let error as ConnectError) {
            Log.Debug("ConnectError - \(error)")
            Conn.sendError(error: error)
        } catch {
            Log.Debug("Error - \(error)")
            Conn.sendError(error: ConnectError.sign)
        }
    }
    
    func showSendICX() {
        let sendView = UIStoryboard(name: "Connect", bundle: nil).instantiateViewController(withIdentifier: "ConnectSendView") as! ConnectSendViewController
        sendView.privateKey = self.privateKey
        self.present(sendView, animated: true, completion: nil)
    }
}
