//
//  SendICXViewController.swift
//  iconex_ios
//
//  Created by Seungyeon Lee on 2019/08/31.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import BigInt
import ICONKit

protocol sendDelegate {
    var data: String { get set }
}

class SendICXViewController: BaseViewController {
    @IBOutlet weak var navBar: IXNavigationView!
    
    @IBOutlet weak var balanceTitleLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var amountInputBox: IXInputBox!
    
    @IBOutlet weak var plus10Button: UIButton!
    @IBOutlet weak var plus100Button: UIButton!
    @IBOutlet weak var plus1000Button: UIButton!
    @IBOutlet weak var maxButton: UIButton!
    
    @IBOutlet weak var addressInputBox: IXInputBox!
    
    @IBOutlet weak var addressBookButton: UIButton!
    @IBOutlet weak var qrCodeButton: UIButton!
    
    @IBOutlet weak var dataInputBox: IXInputBox!
    @IBOutlet weak var dataButton: UIButton!
    @IBOutlet weak var viewDataButton: UIButton!
    
    @IBOutlet weak var footerBox: UIView!
    @IBOutlet weak var stepLimitTitleLabel: UILabel!
    @IBOutlet weak var stepLimitLabel: UILabel!
    
    @IBOutlet weak var estimateFeeTitleLabel: UILabel!
    @IBOutlet weak var estimateFeeLabel: UILabel!
    @IBOutlet weak var feePriceLabel: UILabel!
    
    @IBOutlet weak var sendButton: UIButton!
    
    var walletInfo: BaseWalletConvertible? = nil
    var token: Token? = nil
    
    var balance: BigUInt = 0
    var stepLimit: BigUInt = 100000
    
    var privateKey: PrivateKey?
    
    var delegate: sendDelegate? = nil
    
    var data: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBind()
        setKeyboardListener()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.endEditing(true)
    }
    
    private func setupUI() {
        guard let wallet = self.walletInfo else { return }
        
        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarCloseW")) {
            self.dismiss(animated: true, completion: nil)
        }
        navBar.setTitle(wallet.name)
        navBar.setRight(image: #imageLiteral(resourceName: "icInfoW")) {
            // TODO
        }
        
        balanceTitleLabel.size12(text: "Send.Balane.Avaliable".localized, color: .gray77, weight: .medium)
        amountInputBox.set(inputType: .decimal)
        amountInputBox.set(state: .normal, placeholder: "Send.InputBox.Amount".localized)
        
        plus10Button.roundGray230()
        plus100Button.roundGray230()
        plus1000Button.roundGray230()
        maxButton.roundGray230()
        
        plus10Button.setTitle("+10", for: .normal)
        plus100Button.setTitle("+100", for: .normal)
        plus1000Button.setTitle("+1000", for: .normal)
        maxButton.setTitle("Send.Amount.Max".localized, for: .normal)
        
        addressInputBox.set(inputType: .normal)
        addressInputBox.set(state: .normal, placeholder: "Send.InputBox.Address".localized)
        
        addressBookButton.roundGray230()
        qrCodeButton.roundGray230()
        addressBookButton.setTitle("Send.AddressBook".localized, for: .normal)
        qrCodeButton.setTitle("Send.ScanQRCode".localized, for: .normal)
        
        dataInputBox.set(inputType: .normal)
        dataInputBox.set(state: .normal, placeholder: "Send.InputBox.Data".localized)
        viewDataButton.isHidden = true
        viewDataButton.roundGray230()
        
        footerBox.corner(8)
        footerBox.border(0.5, .gray230)
        footerBox.backgroundColor = .gray252
        
        stepLimitTitleLabel.size12(text: "Send.Step".localized, color: .gray77, weight: .light)
        estimateFeeTitleLabel.size12(text: "Send.EstimatedMaxStep".localized, color: .gray77, weight: .light)
        
        sendButton.lightMintRounded()
        sendButton.setTitle("Send.SendButton".localized, for: .normal)
        sendButton.isEnabled = false
        
        if let token = self.token {
            balance = Manager.balance.getTokenBalance(address: token.parent, contract: token.contract)
            balanceLabel.size24(text: balance.toString(decimal: token.decimal, 5).currencySeparated(), color: .mint1, align: .right)
            
            let price = Tool.calculatePrice(decimal: token.decimal, currency: "\(token.symbol.lowercased())usd", balance: balance)
            priceLabel.size12(text: price, color: .gray179, align: .right)
        } else {
            balance = Manager.balance.getBalance(wallet: wallet) ?? 0
            balanceLabel.size24(text: balance.toString(decimal: 18, 5).currencySeparated() , color: .mint1, align: .right)
            
            let price = Tool.calculatePrice(currency: "icxusd", balance: balance)
            priceLabel.size12(text: price, color: .gray179, align: .right)
        }
    }
    
    private func setupBind() {
        guard let wallet = self.walletInfo else { return }
        
        plus10Button.rx.tap.asControlEvent()
            .subscribe { (_) in
                if let token = self.token {
                    let power = BigUInt(10).power(token.decimal)
                    let currentValue = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: token.decimal, fixed: true) ?? 0
                    
                    let calculated = currentValue + power
                    self.amountInputBox.text = calculated.toString(decimal: token.decimal, token.decimal, false)
                } else {
                    let power = BigUInt(10).convert()
                    let currentValue = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: 18, fixed: true) ?? 0
                    
                    let calculated = currentValue + power
                    self.amountInputBox.text = calculated.toString(decimal: 18, 18, false)
                }
                
        }.disposed(by: disposeBag)
        
        plus100Button.rx.tap.asControlEvent()
            .subscribe { (_) in
                if let token = self.token {
                    let power = BigUInt(100).power(token.decimal)
                    let currentValue = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: token.decimal, fixed: true) ?? 0
                    
                    let calculated = currentValue + power
                    self.amountInputBox.text = calculated.toString(decimal: token.decimal, token.decimal, false)
                } else {
                    let power = BigUInt(100).convert()
                    let currentValue = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: 18, fixed: true) ?? 0
                    
                    let calculated = currentValue + power
                    self.amountInputBox.text = calculated.toString(decimal: 18, 18, false)
                }
            }.disposed(by: disposeBag)
        
        plus1000Button.rx.tap.asControlEvent()
            .subscribe { (_) in
                if let token = self.token {
                    let power = BigUInt(1000).power(token.decimal)
                    let currentValue = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: token.decimal, fixed: true) ?? 0
                    
                    let calculated = currentValue + power
                    self.amountInputBox.text = calculated.toString(decimal: token.decimal, token.decimal, false)
                } else {
                    let power = BigUInt(1000).convert()
                    let currentValue = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: 18, fixed: true) ?? 0
                    
                    let calculated = currentValue + power
                    self.amountInputBox.text = calculated.toString(decimal: 18, 18, false)
                }
            }.disposed(by: disposeBag)
        
        maxButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                if let token = self.token {
                    self.amountInputBox.text = self.balance.toString(decimal: token.decimal, token.decimal, false)
                } else {
                    let maxBalance = self.balance - self.stepLimit
                    self.amountInputBox.text = maxBalance.toString(decimal: 18, 18, false)
                }
            }.disposed(by: disposeBag)
        
        dataButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let dataVC = self.storyboard?.instantiateViewController(withIdentifier: "DataType") as! DataTypeViewController
                dataVC.modalTransitionStyle = .crossDissolve
                dataVC.modalPresentationStyle = .overFullScreen
                
                self.present(dataVC, animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
        amountInputBox.set { [unowned self] (value) -> String? in
            guard !value.isEmpty else { return nil }
            
            if let token = self.token {
                let amount = Tool.stringToBigUInt(inputText: value, decimal: token.decimal, fixed: true) ?? 0
                
                if amount > self.balance + self.stepLimit {
                    return "Send.InputBox.Amount.Error".localized
                }
                return nil
                
            } else {
                let amount = Tool.stringToBigUInt(inputText: value, decimal: 18, fixed: true) ?? 0
                
                if amount > self.balance + self.stepLimit {
                    return "Send.InputBox.Amount.Error".localized
                }
                
                return nil
            }
            
        }
        
        // address
        addressInputBox.set { (address) -> String? in
            guard !address.isEmpty else { return nil }
            
            if Validator.validateICXAddress(address: address) || Validator.validateIRCAddress(address: address) {
                return nil
            } else {
                return "Send.InputBox.Address.Error".localized
            }
        }
        
        // ADDRESS BOOK
        addressBookButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let addressBook = self.storyboard?.instantiateViewController(withIdentifier: "AddressBook") as! AddressBookViewController
                addressBook.myAddress = wallet.address
                
                if let token = self.token {
                    addressBook.token = token
                }
                
                addressBook.selectedHandler = { address in
                    self.addressInputBox.text = address
                }
                
                self.presentPanModal(addressBook)
                
        }.disposed(by: disposeBag)
        
        
        // QR CODE
        qrCodeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let qrCodeReader = UIStoryboard(name: "Camera", bundle: nil).instantiateInitialViewController() as! QRReaderViewController
                
                qrCodeReader.set(mode: .icx, handler: { (address) in
                    self.addressInputBox.text = address
                })
                
                self.present(qrCodeReader, animated: true, completion: nil)
                
        }.disposed(by: disposeBag)
        
        
        // send
        Observable.combineLatest(self.amountInputBox.textField.rx.text.orEmpty, self.addressInputBox.textField.rx.text.orEmpty)
            .flatMapLatest { [unowned self] (value, address) -> Observable<Bool> in
                guard !value.isEmpty || !address.isEmpty else { return Observable.just(false) }
                
                // address
                guard Validator.validateICXAddress(address: address) || Validator.validateIRCAddress(address: address) else {
                    return Observable.just(false)
                }
                
                // amount
                let amount: BigUInt = {
                    if let token = self.token {
                        return Tool.stringToBigUInt(inputText: value, decimal: token.decimal, fixed: true) ?? 0
                    } else {
                        return Tool.stringToBigUInt(inputText: value, decimal: 18, fixed: true) ?? 0
                    }
                }()
                
                if amount > self.balance + self.stepLimit {
                    return Observable.just(false)
                }
                
                return Observable.just(true)
        }.bind(to: self.sendButton.rx.isEnabled)
        .disposed(by: disposeBag)
        
        sendButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                guard let pk = self.privateKey else { return }
                
                let sendInfo: SendInfo = {
                    if let token = self.token {
                        let amount = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: token.decimal, fixed: true) ?? 0
                        let toAddress = self.addressInputBox.text
                        
                        let callTx = CallTransaction()
                            .from(wallet.address)
                            .to(token.contract)
                            .stepLimit(self.stepLimit)
                            .nid(Config.host.nid)
                            .method("transfer")
                            .params(["_to": toAddress, "_value": amount.toHexString()])
                        
                        return SendInfo(transaction: callTx, privateKey: pk, estimatedFee: "ESTIMATED FEE", estimatedUSD: self.priceLabel.text ?? "-")
                    } else {
                        let amount = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: 18, fixed: true) ?? 0
                        let toAddress = self.addressInputBox.text
                        
                        let tx = Transaction()
                            .from(wallet.address)
                            .to(toAddress)
                            .value(amount)
                            .stepLimit(self.stepLimit)
                            .nid(Config.host.nid)
                        
                        return SendInfo(transaction: tx, privateKey: pk, estimatedFee: "ESTIMATED FEE", estimatedUSD: self.priceLabel.text ?? "-")
                    }
                }()
                
                Alert.send(sendInfo: sendInfo, confirmAction: { isSuccess in
                    self.view.showToast(message: isSuccess ? "Send.Success".localized : "Error.CommonError".localized)
                }).show()
                
        }.disposed(by: disposeBag)
    }
}
