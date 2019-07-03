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
import BigInt

class BindPasswordViewController: BaseViewController {
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var walletSection: UIView!
    @IBOutlet weak var walletName: UILabel!
    @IBOutlet weak var walletAddress: UILabel!
    @IBOutlet weak var walletAmount: UILabel!
    
    @IBOutlet weak var symbolLabel: UILabel!
    
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
                Conn.sendError(error: ConnectError.userCancel)
            }).show(self)
        }).disposed(by: disposeBag)
        
        scrollView.rx.didEndDecelerating.subscribe(onNext: {
            self.view.endEditing(true)
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
            guard Conn.received != nil else { return }
            self.showSendICX()
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        navTitle.text = "Alert.Wallet.RequestPassword".localized
        
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
        
        guard let from = wallet.address else { return }
        
        if let decimal = Conn.tokenDecimal, let symbol = Conn.tokenSymbol {
            guard let contract = Conn.received?.payload?.to else { return }
            guard let balance = Balance.tokenBalanceList[from]?[contract] else { return }
            
            self.walletAmount.text = Tools.bigToString(value: balance, decimal: decimal, decimal, true).currencySeparated()
            self.symbolLabel.text = symbol
            
        } else {
            guard let balance = Balance.walletBalanceList[from] else { return }
            
            self.walletAmount.text = Tools.bigToString(value: balance, decimal: 18, 18, true).currencySeparated()
            self.symbolLabel.text = "ICX"
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
        
        privateKey = PrivateKey(hex: prvKeyData)
        
        return true
    }
    
    func showSendICX() {
        let sendView = UIStoryboard(name: "Connect", bundle: nil).instantiateViewController(withIdentifier: "ConnectSendView") as! ConnectSendViewController
        sendView.privateKey = self.privateKey
        guard let payload = Conn.received?.payload else {
            Conn.sendError(error: .invalidJSON)
            return
        }
        sendView.tx = payload
        self.present(sendView, animated: true, completion: nil)
    }
}
