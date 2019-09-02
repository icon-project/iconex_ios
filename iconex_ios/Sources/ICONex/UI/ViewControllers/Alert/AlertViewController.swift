//
//  AlertViewController.swift
//  iconex_ios
//
//  Created by sweepty on 05/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import ICONKit
import Web3swift
import RxSwift
import RxCocoa
import BigInt

class AlertViewController: BaseViewController {
    
    @IBOutlet weak var popView: UIView!
    
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var bottom: NSLayoutConstraint!
    
    var type: AlertType = .basic
    
    var isButtonOne: Bool = false
    
    var headerText: String = ""
    var titleText: String = ""
    var subTitleText: String = ""
    var leftButtonTitle: String = "Common.Cancel".localized
    var rightButtonTitle: String = "Common.Confirm".localized
    
    var walletInfo: BaseWalletConvertible? = nil {
        willSet {
            if let _ = newValue as? ICXWallet {
                self.isICX = true
            } else {
                self.isICX = false
            }
        }
    }
    
    var isICX: Bool = true
    
    var txHashData: AlertTxHashInfo?
    var stakeInfo: StakeInfo?
    var sendInfo: SendInfo?
    var iscoreInfo: IScoreClaimInfo?
    
    var privateKey: String = ""
    
    var isSuccess: Bool = true
    
    var cancelHandler: (() -> Void)?
    var confirmHandler: (() -> Void)?
    var returnHandler: ((_ privateKey: String) -> Void)?
    var successHandler: ((_ isSuccess: Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.init(white: 1, alpha: 0)
        
        popView.layer.cornerRadius = 18
        popView.alpha = 0
        popView.frame.origin.y += 20
        
        leftButton.rx.tap
            .subscribe({ (_) in
                self.closer(self.cancelHandler)
            }).disposed(by: disposeBag)
        
        rightButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                switch self.type {
                case .password:
                    let sub = self.contentView.subviews.first as! PasswordAlertView
                    
                    guard let wallet = self.walletInfo else { return }
                    let address = wallet.address
                    guard let inputValue = sub.inputBoxView.textField.text else { return }
                    
                    do {
                        if self.isICX {
                            let loadWallet = Manager.wallet.walletBy(address: address, type: "icx") as! ICXWallet
                            self.privateKey = try loadWallet.extractICXPrivateKey(password: inputValue).hexEncoded
                        } else {
                            let loadWallet = Manager.wallet.walletBy(address: address, type: "eth") as! ETHWallet
                            self.privateKey = try loadWallet.extractETHPrivateKey(password: inputValue)
                        }
                        self.closer(self.returnHandler)
                    } catch {
                        sub.inputBoxView.setError(message: "Error.Password.Wrong".localized)
                    }
                    
                case .walletName:
                    let sub = self.contentView.subviews.first as! PasswordAlertView
                    
                    guard let wallet = self.walletInfo else { return }
                    
                    let formerName = wallet.name
                    guard let newName = sub.inputBoxView.textField.text else { return }
                    
                    do {
                        try DB.changeWalletName(former: formerName, newName: newName)
                        self.closer(self.confirmHandler)
                    } catch {
                        sub.inputBoxView.setError(message: "Error.Wallet.Duplicated.Name".localized)
                    }
                    
                case .addAddress:
                    let sub = self.contentView.subviews.first as! AddressAlertView
                    guard let name = sub.addressNameInputBox.textField.text, let address = sub.addressInputBox.textField.text else { return }
                    
                    guard DB.canSaveAddressBook(name: name) else {
                        sub.addressNameInputBox.setError(message: "Error.Wallet.Duplicated.Name".localized)
                        return
                    }
                    
                    let addressChecker: Bool = self.isICX ? Validator.validateICXAddress(address: address) || Validator.validateIRCAddress(address: address) : Validator.validateETHAddress(address: address)
                    
                    guard addressChecker == true else {
                        sub.addressInputBox.setError(message: "Error.Address.Invalid".localized)
                        return
                    }
                    
                    do {
                        try DB.saveAddressBook(name: name, address: address, type: self.isICX ? "icx" : "eth")
                        self.closer(self.confirmHandler)
                    } catch let err {
                        Log(err, .error)
                    }
                    
                case .send:
                    guard let sendInfo = self.sendInfo else { return }
                    
                    // ICX
                    if let tx = sendInfo.transaction, let pk = sendInfo.privateKey {
                        do {
                            let result = try Manager.icon.sendTransaction(transaction: tx, privateKey: pk)
                            Log(result, .info)
                            
                            self.isSuccess = true
                        } catch {
                            self.isSuccess = false
                        }
                    }
                    
                    // ETH
                    if let ethTx = sendInfo.ethTransaction, let pk = sendInfo.ethPrivateKey {
                        let sendETH = Ethereum.requestSendTransaction(privateKey: pk, gasPrice: ethTx.gasPrice, gasLimit: ethTx.gasLimit, from: ethTx.from, to: ethTx.to, value: ethTx.value, data: ethTx.data)
                        
                        self.isSuccess = sendETH.isSuccess
                        
                    }
                    
                    self.closer(self.successHandler)
                    
                default:
                    self.closer(self.confirmHandler)
                }
                
            }).disposed(by: disposeBag)
        
        setupAlertView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        open()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        switch self.type {
        case .password, .walletName:
            let sub = self.contentView.subviews.first as! PasswordAlertView
            sub.inputBoxView.textField.becomeFirstResponder()
            
        case .addAddress:
            let sub = self.contentView.subviews.first as! AddressAlertView
            sub.addressInputBox.textField.becomeFirstResponder()
            
        default: break
            
        }
    }
    
    func setButtonUI(isOne: Bool) {
        leftButton.layer.cornerRadius = 18
        leftButton.clipsToBounds = true
        leftButton.setTitle(leftButtonTitle, for: .normal)
        leftButton.backgroundColor = .gray242
        
        if isOne {
            rightButton.isHidden = true
            leftButton.setTitleColor(.gray77, for: .normal)
            
            if #available(iOS 11.0, *){
                leftButton.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            } else {
                // fallback
            }
            
            
        } else {
            leftButton.setTitleColor(.gray77, for: .normal)
            leftButton.setTitleColor(.mint5, for: .disabled)
            
            rightButton.backgroundColor = .mint2
            rightButton.setTitleColor(.white, for: .normal)
            rightButton.clipsToBounds = true
            rightButton.layer.cornerRadius = 18
            rightButton.setTitle(rightButtonTitle, for: .normal)
            
            rightButton.setTitleColor(.mint5, for: .disabled)
            
            if #available(iOS 11.0, *) {
                leftButton.layer.maskedCorners = [.layerMinXMaxYCorner]
                rightButton.layer.maskedCorners = [.layerMaxXMaxYCorner]
            } else {
                // fallback
            }
        }
    }
    
    func setupAlertView() {
//        guard let wallet = self.walletInfo else { return }
        
        switch type {
        case .basic, .allText:
            setButtonUI(isOne: self.isButtonOne)
            
            let basicView = BasicAlertView()
            
            if type == .basic {
                headerLabel.isHidden = true
                basicView.lineView.isHidden = true
            } else {
                headerLabel.size18(text: headerText, color: .gray77, weight: .medium, align: .center)
            }
            
            basicView.info = AlertBasicInfo(title: self.titleText, subtitle: self.subTitleText)
            
            addSubviewWithConstraint(basicView)
            
        case .stake, .unstake, .unstakecancel:
            setButtonUI(isOne: false)
            
            let stakeView = StakeAlertView()
            stakeView.info = self.stakeInfo
            
            switch type {
            case .unstake:
                headerLabel.size18(text: "Alert.UnStake.Header".localized, color: .gray77, weight: .medium, align: .center)
                stakeView.isStake = false
                
            case .stake:
                headerLabel.size18(text: "Alert.Stake.Header".localized, color: .gray77, weight: .medium, align: .center)
                
            case .unstakecancel:
                headerLabel.size18(text: "Alert.UnStakeCancel.Header".localized, color: .gray77, weight: .medium, align: .center)
                stakeView.isCancel = true
                
            default: break
            }
            
            addSubviewWithConstraint(stakeView)
            
        case .password:
            headerLabel.size18(text: "Alert.Password.Header".localized, color: .gray77, weight: .medium, align: .center)
            setButtonUI(isOne: false)
            rightButton.isEnabled = false
            
            let passwordView = PasswordAlertView()
            passwordView.placeholder = "Alert.Password.Placeholder".localized
            passwordView.alertType = .password
            
            guard let wallet = self.walletInfo else { return }
            
            passwordView.inputBoxView.set { (inputValue) -> String? in
                guard !inputValue.isEmpty else { return nil }
                do {
                    if self.isICX {
                        let loadWallet = Manager.wallet.walletBy(address: wallet.address, type: "icx") as! ICXWallet
                        self.privateKey = try loadWallet.extractICXPrivateKey(password: inputValue).hexEncoded
                    } else {
                        let loadWallet = Manager.wallet.walletBy(address: wallet.address, type: "eth") as! ETHWallet
                        self.privateKey = try loadWallet.extractETHPrivateKey(password: inputValue)
                    }
                    return nil
                } catch {
                    return "Error.Password.Wrong".localized
                }
            }
            
            addSubviewWithConstraint(passwordView)
            
            passwordView.inputBoxView.textField.rx.text.orEmpty
                .subscribe(onNext: { (value) in
                    self.rightButton.isEnabled = value.count > 0
                }).disposed(by: disposeBag)
            
            passwordView.inputBoxView.forgotPasswordButton.rx.tap.asControlEvent()
                .subscribe({ (_) in
                    UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
                        self.popView.alpha = 0.0
                    }, completion: { _ in
                        self.dismiss(animated: false, completion: {
                            Alert.basic(title: "비밀번호를 잊으셨나요?", subtitle: "저장해 놓은 개인 키로 지갑을 다시 불러온 후,\n비밀번호를 재설정 할 수 있습니다.", isOnlyOneButton: false, rightButtonTitle: "지갑 가져오기").show()
                        })
                    })
                }).disposed(by: disposeBag)
            
        case .walletName:
            headerLabel.size18(text: "Alert.WalletName.Header".localized, color: .gray77, weight: .medium, align: .center)
            setButtonUI(isOne: false)
            rightButton.isEnabled = false
            
            let passwordView = PasswordAlertView()
            passwordView.placeholder = "Alert.WalletName.Placeholder".localized
            passwordView.alertType = .walletName
            
            guard let wallet = self.walletInfo else { return }
            
            passwordView.inputBoxView.textField.text = wallet.name
            passwordView.inputBoxView.set { (inputValue) -> String? in
                if wallet.name == inputValue {
                    return nil
                } else {
                    return DB.canSaveWallet(name: inputValue) ? nil : "Error.Wallet.Duplicated.Name".localized
                }
            }
            
            addSubviewWithConstraint(passwordView)
            
            passwordView.inputBoxView.textField.rx.text.orEmpty
                .scan("") { (previous, new) -> String in
                    if new.count > 0 {
                        self.rightButton.isEnabled = true
                        if new.utf8.count > 24 {
                            return previous ?? String(new.utf8.prefix(24))!
                        } else {
                            return new
                        }
                    } else {
                        self.rightButton.isEnabled = false
                        return new
                    }
                }
                .subscribe(passwordView.inputBoxView.textField.rx.text)
                .disposed(by: disposeBag)
            
        case .txHash:
            headerLabel.size18(text: "Alert.TxHash.Header".localized, color: .gray77, weight: .medium, align: .center)
            
            setButtonUI(isOne: false)
            leftButton.setTitle("Common.Close".localized, for: .normal)
            rightButton.setTitle("Alert.Transaction.Copy".localized, for: .normal)
            let txHashView = TxHashAlertView()
            txHashView.info = self.txHashData
            
            addSubviewWithConstraint(txHashView)
            
        case .send:
            headerLabel.size18(text: "Alert.Send.Header".localized, color: .gray77, weight: .medium, align: .center)
            setButtonUI(isOne: false)
            
            let sendView = SendAlertView()
            sendView.info = self.sendInfo
            
            addSubviewWithConstraint(sendView)
            
        case .iscore:
            headerLabel.size18(text: "Alert.Iscore.Header".localized, color: .gray77, weight: .medium, align: .center)
            setButtonUI(isOne: false)
            
            let iscoreView = IScoreAlertView()
            iscoreView.info = self.iscoreInfo
            
            addSubviewWithConstraint(iscoreView)
            
        case .addAddress:
            headerLabel.size18(text: "Alert.Address.Header".localized, color: .gray77, weight: .medium, align: .center)
            setButtonUI(isOne: false)
            rightButton.isEnabled = false
            
            let addressView = AddressAlertView()
            addressView.isICON = self.isICX
            
            addSubviewWithConstraint(addressView)
            
            addressView.addressNameInputBox.set { (inputValue) -> String? in
                guard inputValue.count != 0 else { return nil }
                if !DB.canSaveAddressBook(name: inputValue) {
                    return "Error.AddressBook.DuplicatedName".localized
                }
                return nil
            }
            
            addressView.addressInputBox.set { (inputValue) -> String? in
                guard !inputValue.isEmpty else {
                    return nil
                }
                if self.isICX {
                    if !(Validator.validateICXAddress(address: inputValue) || Validator.validateIRCAddress(address: inputValue)) {
                        return "Error.Address.Invalid".localized
                    } 
                    
                } else {
                    if !Validator.validateETHAddress(address: inputValue) {
                        return "Error.Address.ETH.Invalid".localized
                    }
                }
                if !DB.canSaveAddressBook(address: inputValue) {
                    if self.isICX {
                        return "Error.Address.ICX.Duplicated".localized
                    } else {
                        return "Error.Address.ETH.Duplicated".localized
                    }
                }
                return nil
            }
            Observable.combineLatest(addressView.addressNameInputBox.textField.rx.text.orEmpty, addressView.addressInputBox.textField.rx.text.orEmpty)
                .map { name, address in
                    
                    return name.count > 0 && address.count > 0
                }.bind(to: self.rightButton.rx.isEnabled)
                .disposed(by: disposeBag)
            
            addressView.addressNameInputBox.textField.rx.text.orEmpty
                .scan("") { (previous, new) -> String in
                    if new.count > 0 {
                        if new.utf8.count > 24 {
                            return previous ?? String(new.utf8.prefix(24))!
                        } else {
                            return new
                        }
                    } else {
                        return new
                    }
                }
                .subscribe(addressView.addressNameInputBox.textField.rx.text)
                .disposed(by: disposeBag)
        }
        
        switch self.type {
        case .addAddress, .walletName, .password:
            
            keyboardHeight().observeOn(MainScheduler.instance)
                .subscribe(onNext: { [unowned self] (height: CGFloat) in
                    var keyboardHeight: CGFloat
                    if height == 0 {
                        keyboardHeight = height
                        //                        self.view.frame.origin.y = 0
                    } else {
                        keyboardHeight = height - (self.view.safeAreaInsets.bottom)
                        //                        self.view.frame.origin.y -= (height - self.view.safeAreaInsets.bottom - 100)
                    }
                    self.popView.center = CGPoint(x: self.view.center.x, y: (self.view.frame.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom - keyboardHeight) / 2)
                }).disposed(by: disposeBag)
            
        default: break
        }
    }
    
    func addSubviewWithConstraint(_ subView: UIView) {
        contentView.addSubview(subView)
        subView.translatesAutoresizingMaskIntoConstraints = false
        
        subView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        subView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        subView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        subView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
    
    func open() {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
            self.view.backgroundColor = UIColor.init(white: 0, alpha: 0.4)
        }, completion: nil)
        
        // move
        UIView.animate(withDuration: 0.25, delay: 0.2, options: .curveEaseInOut, animations: {
            self.popView.frame.origin.y -= 20
        }, completion: nil)
        
        // opacity
        UIView.animate(withDuration: 0.24, delay: 0.2, options: .curveEaseInOut, animations: {
            self.popView.alpha = 1
        }, completion: nil)
        
    }
    
    private func close() {
        animateClose()
        
        UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseInOut, animations: {
            self.view.alpha = 0
        }, completion: { _ in
            self.dismiss(animated: false, completion: nil)
        })
    }
    
    private func closer(_ closeAction: (() -> Void)? = nil) {
        animateClose()
        
        UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseInOut, animations: {
            self.view.alpha = 0
        }, completion: { _ in
            self.dismiss(animated: false, completion: {
                if let closeAct = closeAction {
                    closeAct()
                }
            })
        })
    }
    
    private func closer(_ closeAction: ((_ pk: String) -> Void)? = nil) {
        animateClose()
        
        UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseInOut, animations: {
            self.view.alpha = 0
        }, completion: { _ in
            self.dismiss(animated: false, completion: {
                if let closeAct = closeAction {
                    closeAct(self.privateKey)
                }
            })
        })
    }
    
    private func closer(_ closeAction: ((_ isSuccess: Bool) -> Void)? = nil) {
        animateClose()
        
        UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseInOut, animations: {
            self.view.alpha = 0
        }, completion: { _ in
            self.dismiss(animated: false, completion: {
                if let closeAct = closeAction {
                    closeAct(self.isSuccess)
                }
            })
        })
    }
    
    private func animateClose() {
        // move
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.popView.frame.origin.y += 20
        }, completion: nil)
        
        // opacity
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            self.popView.alpha = 0
        }, completion: nil)
    }
    
    func show() {
        Tool.topViewController()?.present(self, animated: false, completion: nil)
    }
}
