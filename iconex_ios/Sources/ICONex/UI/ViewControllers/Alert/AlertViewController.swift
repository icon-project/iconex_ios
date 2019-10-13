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
    
    @IBOutlet weak var confirmSpinner: UIActivityIndicatorView!
    
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
    var voteInfo: VoteInfo?
    var prepInfo: PRepInfoResponse?
    
    var privateKey: String = ""
    
    var isSuccess: Bool = true
    var txHash: String?
    
    var cancelHandler: (() -> Void)?
    var confirmHandler: (() -> Void)?
    var returnHandler: ((_ privateKey: String) -> Void)?
    var successHandler: ((_ isSuccess: Bool, _ txHash: String?) -> Void)?
    
    @IBOutlet weak var centerY: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.init(white: 1, alpha: 0)
        
        popView.layer.cornerRadius = 18
        popView.alpha = 0
//        popView.frame.origin.y += 20
        popView.transform = CGAffineTransform(translationX: 0, y: 20)
        
        leftButton.rx.tap
            .subscribe({ [unowned self] (_) in
                self.view.endEditing(true)
                
                self.closer(self.cancelHandler)
            }).disposed(by: disposeBag)
        
        rightButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.view.endEditing(true)
                
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
                    
                    self.rightButton.setTitleColor(.clear, for: .normal)
                    
                    self.confirmSpinner.isHidden = false
                    self.confirmSpinner.startAnimating()
                    
                    DispatchQueue.global().async {
                        // ICX
                        if let tx = sendInfo.transaction, let pk = sendInfo.privateKey {
                            do {
                                let request = try Manager.icon.sendTransaction(transaction: tx, privateKey: pk)
                                
                                switch request {
                                case .success(let txHash):
                                    self.isSuccess = true
                                    self.txHash = txHash
                                    
                                case .failure(let err):
                                    self.isSuccess = false
                                    self.txHash = err.localizedDescription
                                }
                            } catch {
                                self.isSuccess = false
                            }
                        }
                        
                        // ETH
                        if let ethTx = sendInfo.ethTransaction, let pk = sendInfo.ethPrivateKey {
                            let sendETH = Ethereum.requestSendTransaction(privateKey: pk, gasPrice: ethTx.gasPrice, gasLimit: ethTx.gasLimit, from: ethTx.from, to: ethTx.to, value: ethTx.value, data: ethTx.data)
                            
                            self.isSuccess = sendETH.isSuccess
                            
                        }
                        
                        DispatchQueue.main.async {
                            self.confirmSpinner.stopAnimating()
                            self.closer(self.successHandler)
                        }
                    
                    }
                    
                case .vote:
                    guard let info = self.voteInfo else { return }
                    
                    self.rightButton.setTitleColor(.clear, for: .normal)
                    
                    self.confirmSpinner.isHidden = false
                    self.confirmSpinner.startAnimating()
                    
                    DispatchQueue.global().async {
                    let delegationCall = Manager.icon.setDelegation(from: info.wallet, delegations: info.delegationList)
                        do {
                            let response = try Manager.icon.sendTransaction(transaction: delegationCall, privateKey: info.privateKey)
                            
                            switch response {
                            case .success(let txHash):
                                Log(txHash, .debug)
                                self.isSuccess = true
                                self.txHash = txHash
                                
                            case .failure(let error):
                                Log(error.localizedDescription, .error)
                                self.isSuccess = false
                                self.txHash = error.localizedDescription
                            }
                        } catch {
                            self.isSuccess = false
                            self.txHash = "Common.Error".localized
                        }
                        
                        DispatchQueue.main.async {
                            self.confirmSpinner.stopAnimating()
                            self.closer(self.successHandler)
                        }
                    }
                    
                case .txHash:
                    guard let txHash = self.txHashData?.txHash else { return }
                    UIPasteboard.general.string = txHash
                    self.closer(self.confirmHandler)
                    
                default:
                    self.closer(self.confirmHandler)
                }
                
            }).disposed(by: disposeBag)
        
        setupAlertView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Log("PREPARING OPEN!!!")
        open()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Log("DID APPEAR!!!")
        switch self.type {
        case .password, .walletName:
            let sub = self.contentView.subviews.first as! PasswordAlertView
            sub.inputBoxView.textField.becomeFirstResponder()
            
        case .addAddress:
            let sub = self.contentView.subviews.first as! AddressAlertView
            sub.addressNameInputBox.textField.becomeFirstResponder()
            
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
            
            passwordView.inputBoxView.set { [unowned self] (inputValue) -> String? in
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
                .subscribe(onNext: { [unowned self] (value) in
                    self.rightButton.isEnabled = value.count > 0
                }).disposed(by: disposeBag)
            
            passwordView.inputBoxView.forgotPasswordButton.rx.tap.asControlEvent()
                .subscribe({ [unowned self] (_) in
                    self.view.endEditing(true)
                    
                    UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
                        self.popView.alpha = 0.0
                    }, completion: { _ in
                        self.dismiss(animated: false, completion: {
                            Alert.basic(title: "Alert.ForgotPasscode.Title".localized, subtitle: "Alert.ForgotPasscode.SubTitle".localized, isOnlyOneButton: false, rightButtonTitle: "Side.Load".localized, confirmAction: {
                                
                                let loadWallet = UIStoryboard(name: "LoadWallet".localized, bundle: nil).instantiateInitialViewController() as! LoadWalletViewController
                                
                                loadWallet.pop()
                            }).show()
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
                .scan("") { [unowned self] (previous, new) -> String in
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
            print("sendinfo \(self.sendInfo)")
            sendView.info = self.sendInfo
            
            addSubviewWithConstraint(sendView)
            
        case .vote:
            headerLabel.size18(text: "Alert.Vote.Header".localized, color: .gray77, weight: .medium, align: .center)
            setButtonUI(isOne: false)
            
            let voteView = VoteAlertView()
            voteView.voteInfo = self.voteInfo
            
            addSubviewWithConstraint(voteView)
            
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
            
            addressView.addressInputBox.set { [unowned self] (inputValue) -> String? in
                guard !inputValue.isEmpty else {
                    return nil
                }
                if self.isICX {
                    if !(Validator.validateICXAddress(address: inputValue) || Validator.validateIRCAddress(address: inputValue)) {
                        return "Error.Address.Invalid".localized
                    } 
                    
                } else {
                    if !Validator.validateETHAddress(address: inputValue) {
                        return "Error.Address.Invalid".localized
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
            
            addressView.qrcodeScanButton.rx.tap.asControlEvent()
                .subscribe { [unowned self] (_) in
                    self.view.endEditing(true)
                    
                    let qrCodeReader = UIStoryboard(name: "Camera", bundle: nil).instantiateInitialViewController() as! QRReaderViewController
                    qrCodeReader.modalPresentationStyle = .fullScreen
                    let readerMode: QRReaderMode = {
                        return self.isICX ? .icx : .eth
                    }()
                    
                    qrCodeReader.set(mode: readerMode, handler: { (address) in
                        addressView.addressInputBox.text = address
                        addressView.addressInputBox.set(state: .normal)
                        addressView.addressInputBox.textField.sendActions(for: .valueChanged)
                    })
                    
                    app.topViewController()?.present(qrCodeReader, animated: true, completion: nil)
                    
            }.disposed(by: disposeBag)
            
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
            
        case .prepDetail:
            headerLabel.size18(text: "Alert.PrepDetail.Header".localized, color: .gray77, weight: .medium, align: .center)
            
            setButtonUI(isOne: true)
            leftButton.setTitle("Common.Close".localized, for: .normal)
            
            let prepDetailView = PRepDetailAlertView()
            prepDetailView.prepInfo = self.prepInfo
            
            addSubviewWithConstraint(prepDetailView)
        }
        
        switch self.type {
        case .addAddress, .walletName, .password:
            
            keyboardHeight().observeOn(MainScheduler.instance)
                .subscribe(onNext: { [unowned self] (height: CGFloat) in
                    var keyboardHeight: CGFloat
                    if height == 0 {
                        keyboardHeight = height
                    } else {
                        keyboardHeight = height - (self.view.safeAreaInsets.bottom)
                    }
                    
                    self.bottom.constant = keyboardHeight
                    UIView.animate(withDuration: 0.25) {
                            self.view.layoutIfNeeded()
                    }
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
        UIView.animateKeyframes(withDuration: 0.4, delay: 0.0, options: [.calculationModeCubic], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.2, animations: {
                self.view.backgroundColor = UIColor.init(white: 0, alpha: 0.4)
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.2, animations: {
                self.popView.transform = .identity
                self.popView.alpha = 1
            })
            
        }, completion: nil)
    }
    
    private func close() {
        animateClose { [unowned self] in
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    private func closer(_ closeAction: (() -> Void)? = nil) {
        animateClose { [unowned self] in
            self.dismiss(animated: false, completion: {
                if let closeAct = closeAction {
                    closeAct()
                }
            })
        }
    }
    
    private func closer(_ closeAction: ((_ pk: String) -> Void)? = nil) {
        animateClose { [unowned self] in
            self.dismiss(animated: false, completion: {
                if let closeAct = closeAction {
                    closeAct(self.privateKey)
                }
            })
        }
    }
    
    private func closer(_ closeAction: ((_ isSuccess: Bool, _ txHash: String?) -> Void)? = nil) {
        animateClose { [unowned self] in
            self.dismiss(animated: false, completion: {
                if let closeAct = closeAction {
                    closeAct(self.isSuccess, self.txHash)
                }
            })
        }
    }
    
    private func animateClose(_ completion: (() -> Void)? = nil) {
        UIView.animateKeyframes(withDuration: 0.4, delay: 0.0, options: [], animations: { [weak self] in
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.2, animations: {
                self?.popView.transform = CGAffineTransform(translationX: 0, y: 20)
                self?.popView.alpha = 0
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.2, animations: {
                self?.view.alpha = 0.0
            })
        }, completion: { _ in
            completion?()
        })
    }
    
    func show() {
        Log("Now show!!!!!!!!!!")
        Tool.topViewController()?.present(self, animated: false, completion: nil)
        Log("Showed!!!!!!!!!!!!!!!")
    }
}
