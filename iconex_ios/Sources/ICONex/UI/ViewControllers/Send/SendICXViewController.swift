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

protocol SendDelegate {
    var data: Data? { get set }
}

class SendICXViewController: BaseViewController {
    @IBOutlet weak var navBar: IXNavigationView!
    
    @IBOutlet weak var balanceTitleLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var amountInputBox: IXInputBox!
    @IBOutlet weak var usdLabel: UILabel!
    
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
    
    var stepPrice = Manager.icon.stepPrice ?? 0
    var privateKey: PrivateKey?
    var toAddress: String? = nil
    var toAmount: String? = nil
    
    var data: String? = nil
    
    var dataType: InputType = .utf8
    
    var sendHandler: ((_ isSuccess: Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.token != nil {
            self.stepLimit = 200000
            self.dataInputBox.isHidden = true
            self.dataButton.isHidden = true
        }
        
        setupUI()
        setupBind()
        
        if let toAddress = self.toAddress {
            self.addressInputBox.text = toAddress
            self.addressInputBox.textField.sendActions(for: .editingDidEndOnExit)
        }
        if let toAmount = self.toAmount {
            self.amountInputBox.text = toAmount
            self.amountInputBox.textField.sendActions(for: .editingDidEndOnExit)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.view.endEditing(true)
    }
    
    private func setupUI() {
        guard let wallet = self.walletInfo else { return }
        
        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarCloseW")) {
            self.dismiss(animated: true, completion: nil)
        }
        navBar.setTitle(wallet.name)
        navBar.setRight(image: #imageLiteral(resourceName: "icInfoW")) {
            let sendInfo = UIStoryboard(name: "Send", bundle: nil).instantiateViewController(withIdentifier: "SendInfo") as! SendInfoViewController
            sendInfo.type = "icx"
            self.presentPanModal(sendInfo)
        }
        
        setFooterBox()
        
        if let token = self.token {
            balanceTitleLabel.size12(text: String(format: "Send.Balance.Avaliable.Token".localized, token.symbol) , color: .gray77, weight: .medium)
        } else {
            balanceTitleLabel.size12(text: "Send.Balance.Avaliable".localized, color: .gray77, weight: .medium)
        }
        
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
        
        addressInputBox.set(inputType: .address)
        addressInputBox.set(state: .normal, placeholder: "Send.InputBox.Address".localized)
        
        addressBookButton.roundGray230()
        qrCodeButton.roundGray230()
        addressBookButton.setTitle("Send.AddressBook".localized, for: .normal)
        qrCodeButton.setTitle("Send.ScanQRCode".localized, for: .normal)
        
        dataInputBox.set(inputType: .normal)
        dataInputBox.set(state: .normal, placeholder: "Send.InputBox.Data".localized)
        viewDataButton.isHidden = true
        viewDataButton.roundGray230()
        viewDataButton.setTitle("Send.InputBox.Data.View".localized, for: .normal)
        
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
            balanceLabel.size24(text: balance.toString(decimal: token.decimal, token.decimal).currencySeparated(), color: .mint1, align: .right)
            
            let price = Tool.calculatePrice(decimal: token.decimal, currency: "\(token.symbol.lowercased())usd", balance: balance)
            priceLabel.size12(text: price, color: .gray179, align: .right)
        } else {
            balance = Manager.balance.getBalance(wallet: wallet) ?? 0
            balanceLabel.size24(text: balance.toString(decimal: 18, 18).currencySeparated() , color: .mint1, align: .right)
            
            let price = Tool.calculatePrice(currency: "icxusd", balance: balance)
            priceLabel.size12(text: price, color: .gray179, align: .right)
        }
    }
    
    private func setupBind() {
        guard let wallet = self.walletInfo else { return }
        
        self.scrollView?.keyboardDismissMode = .onDrag
        
        plus10Button.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.amountInputBox.textField.becomeFirstResponder()
                
                if let token = self.token {
                    let power = BigUInt(10) * BigUInt(10).power(token.decimal)
                    let currentValue = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: token.decimal, fixed: true) ?? 0
                    
                    let calculated = currentValue + power
                    self.amountInputBox.text = calculated.toString(decimal: token.decimal, token.decimal, true)
                } else {
                    let power = BigUInt(10).convert()
                    let currentValue = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: 18, fixed: true) ?? 0
                    
                    let calculated = currentValue + power
                    self.amountInputBox.text = calculated.toString(decimal: 18)
                }
                self.amountInputBox.textField.sendActions(for: .editingDidEndOnExit)
                
        }.disposed(by: disposeBag)
        
        plus100Button.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.amountInputBox.textField.becomeFirstResponder()
                
                if let token = self.token {
                    let power = BigUInt(100) * BigUInt(10).power(token.decimal)
                    let currentValue = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: token.decimal, fixed: true) ?? 0
                    
                    let calculated = currentValue + power
                    self.amountInputBox.text = calculated.toString(decimal: token.decimal, token.decimal, false)
                } else {
                    let power = BigUInt(100).convert()
                    let currentValue = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: 18, fixed: true) ?? 0
                    
                    let calculated = currentValue + power
                    self.amountInputBox.text = calculated.toString(decimal: 18)
                }
                self.amountInputBox.textField.sendActions(for: .editingDidEndOnExit)
                
            }.disposed(by: disposeBag)
        
        plus1000Button.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.amountInputBox.textField.becomeFirstResponder()
                
                if let token = self.token {
                    let power = BigUInt(1000) * BigUInt(10).power(token.decimal)
                    let currentValue = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: token.decimal, fixed: true) ?? 0
                    
                    let calculated = currentValue + power
                    self.amountInputBox.text = calculated.toString(decimal: token.decimal, token.decimal, false)
                } else {
                    let power = BigUInt(1000).convert()
                    let currentValue = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: 18, fixed: true) ?? 0
                    
                    let calculated = currentValue + power
                    self.amountInputBox.text = calculated.toString(decimal: 18)
                }
                self.amountInputBox.textField.sendActions(for: .editingDidEndOnExit)
                
            }.disposed(by: disposeBag)
        
        maxButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.amountInputBox.textField.becomeFirstResponder()
                
                if let token = self.token {
                    self.amountInputBox.text = self.balance.toString(decimal: token.decimal, token.decimal)
                    
                } else {
                    let fee: BigUInt = self.stepLimit * self.stepPrice
                    guard self.balance >= fee else {
                        self.amountInputBox.text = "0"
                        return
                    }
                    
                    let maxBalance = self.balance - fee
                    self.amountInputBox.text = maxBalance.toString(decimal: 18, 18)
                }
                self.amountInputBox.textField.sendActions(for: .editingDidEndOnExit)
                
            }.disposed(by: disposeBag)
        
        dataButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.view.endEditing(true)
                
                let dataVC = self.storyboard?.instantiateViewController(withIdentifier: "DataType") as! DataTypeViewController
                dataVC.modalTransitionStyle = .crossDissolve
                dataVC.modalPresentationStyle = .overFullScreen
                dataVC.handler = { data, dataType in
                    self.data = data
                    self.dataType = dataType
                    self.dataInputBox.text = data ?? ""
                    self.dataInputBox.textField.sendActions(for: .editingDidEndOnExit)
                    
                    guard data != nil else {
                        self.stepLimit = 100000
                        self.setFooterBox()
                        self.dataButton.isEnabled = true
                        self.viewDataButton.isHidden = true
                        
                        return
                    }
                    
                    self.stepLimit = self.calcaulateStepLimit()
                    self.setFooterBox()
                    self.dataButton.isEnabled = false
                    self.viewDataButton.isHidden = false
                    self.dataInputBox.set(state: .readOnly)
                }
                
                self.present(dataVC, animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
        viewDataButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.view.endEditing(true)
                
                guard let data = self.data else { return }
                
                let inputDataVC = self.storyboard?.instantiateViewController(withIdentifier: "InputData") as! InputDataViewController
                inputDataVC.isViewMode = true
                inputDataVC.data = data
                inputDataVC.type = self.dataType
                inputDataVC.completeHandler = { dataString, _ in
                    self.data = dataString
                    self.dataInputBox.text = dataString ?? ""
                    self.dataInputBox.textField.sendActions(for: .editingDidEndOnExit)
                    
                    guard dataString != nil else {
                        self.stepLimit = 100000
                        self.dataButton.isEnabled = true
                        self.viewDataButton.isHidden = true
                        
                        self.setFooterBox()
                        return
                    }
                    
                    self.stepLimit = self.calcaulateStepLimit()
                    self.setFooterBox()
                    self.dataButton.isEnabled = false
                    self.viewDataButton.isHidden = false
                    self.dataInputBox.set(state: .readOnly)
                }
                
                self.presentPanModal(inputDataVC)
                
        }.disposed(by: disposeBag)
        
        amountInputBox.set { [unowned self] (value) -> String? in
            guard !value.isEmpty else { return nil }
            
            if let token = self.token {
                let amount = Tool.stringToBigUInt(inputText: value, decimal: token.decimal, fixed: true) ?? 0
                
                if amount > self.balance {
                    self.usdLabel.isHidden = true
                    return "Send.InputBox.Amount.Error".localized
                }
                return nil
                
            } else {
                let amount = Tool.stringToBigUInt(inputText: value, decimal: 18, fixed: true) ?? 0
                
                if amount > self.balance {
                    self.usdLabel.isHidden = true
                    return "Send.InputBox.Amount.Error".localized
                }
                
                return nil
            }
            
        }
        
        amountInputBox.textField.rx.text.orEmpty.subscribe(onNext: { (value) in
            let unit: String = {
                if let token = self.token {
                    return "\(token.symbol.lowercased())usd"
                } else {
                    return "icxusd"
                }
            }()
            
            let bigValue = Tool.stringToBigUInt(inputText: value) ?? 0
            
            let result = "$ " + Tool.calculatePrice(currency: unit, balance: bigValue)
            
            self.usdLabel.rx.text.onNext(result)
            
        }).disposed(by: disposeBag)
        
        amountInputBox.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.usdLabel.isHidden = false
        }).disposed(by: disposeBag)
        
        
        // address
        addressInputBox.set { (address) -> String? in
            guard !address.isEmpty else { return nil }
            
            guard address != wallet.address else {
                return "Send.InputBox.Address.Error.SameAddress".localized
            }
            
            if Validator.validateICXAddress(address: address) || Validator.validateIRCAddress(address: address) {
                return nil
            } else {
                return "Send.InputBox.Address.Error".localized
            }
        }
        
        // ADDRESS BOOK
        addressBookButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.view.endEditing(true)
                
                let addressBook = self.storyboard?.instantiateViewController(withIdentifier: "AddressBook") as! AddressBookViewController
                addressBook.myAddress = wallet.address
                
                if let token = self.token {
                    addressBook.token = token
                }
                
                addressBook.selectedHandler = { address in
                    self.addressInputBox.text = address
                    self.addressInputBox.textField.sendActions(for: .editingDidEndOnExit)
                }
                
                self.presentPanModal(addressBook)
                
        }.disposed(by: disposeBag)
        
        
        // QR CODE
        qrCodeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.view.endEditing(true)
                
                let qrCodeReader = UIStoryboard(name: "Camera", bundle: nil).instantiateInitialViewController() as! QRReaderViewController
                qrCodeReader.modalPresentationStyle = .fullScreen
                qrCodeReader.set(mode: .icx, handler: { address, amount in
                    self.addressInputBox.text = address
                    self.addressInputBox.textField.sendActions(for: .editingDidEndOnExit)
                    if let a = amount?.hexToBigUInt()?.toString(decimal: 18, 18, true) {
                        self.amountInputBox.text = a
                        self.amountInputBox.textField.sendActions(for: .editingDidEndOnExit)
                    }
                })
                
                self.present(qrCodeReader, animated: true, completion: nil)
                
        }.disposed(by: disposeBag)
        
        
        // send
        Observable.combineLatest(self.amountInputBox.textField.rx.text.orEmpty, self.addressInputBox.textField.rx.text.orEmpty)
            .flatMapLatest { [unowned self] (value, address) -> Observable<Bool> in
                guard !value.isEmpty && !address.isEmpty else { return Observable.just(false) }
                
                guard address != wallet.address else { return Observable.just(false) }
                
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
                
                if amount > self.balance {
                    return Observable.just(false)
                }
                
                return Observable.just(true)
        }.bind(to: self.sendButton.rx.isEnabled)
        .disposed(by: disposeBag)
        
        sendButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                guard let pk = self.privateKey else { return }
                
                let estimatedStep: BigUInt = self.stepLimit * self.stepPrice
                
                let amount: BigUInt = {
                    if let token = self.token {
                        return Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: token.decimal, fixed: true) ?? 0
                    } else {
                        return Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: 18, fixed: true) ?? 0
                    }
                }()
                
                if self.token == nil {
                    if estimatedStep > self.balance {
                        Alert.basic(title: "Send.Error.InsufficientFee.ICX".localized, leftButtonTitle: "Common.Confirm".localized).show()
                        return
                    }
                } else {
                    guard let wallet = self.walletInfo else { return }
                    let icxBalance = Manager.balance.getBalance(wallet: wallet) ?? 0
                    
                    if estimatedStep > icxBalance {
                        Alert.basic(title: "Send.Error.InsufficientFee.ICX".localized, leftButtonTitle: "Common.Confirm".localized).show()
                        return
                    }
                }
                
                let toAddress = self.addressInputBox.text
                let stepLimitPrice = self.stepLimitLabel.text ?? ""
                let estimatedFee = self.estimateFeeLabel.text ?? ""
                let estimatedUSD = self.feePriceLabel.text ?? ""
                
                let sendInfo: SendInfo = {
                    if let token = self.token {
                        let callTx = CallTransaction()
                            .from(wallet.address)
                            .to(token.contract)
                            .stepLimit(self.stepLimit)
                            .nid(Config.host.nid)
                            .method("transfer")
                            .params(["_to": toAddress, "_value": amount.toHexString()])
                        
                        return SendInfo(transaction: callTx, privateKey: pk, stepLimitPrice: stepLimitPrice, estimatedFee: estimatedFee, estimatedUSD: estimatedUSD, token: token, tokenAmount: amount, tokenToAddress: toAddress)
                        
                    } else {
                        let tx: Transaction = {
                            if let dataString = self.data {
                                let messageTx = MessageTransaction()
                                    .from(wallet.address)
                                    .to(toAddress)
                                    .value(amount)
                                    .stepLimit(self.stepLimit)
                                    .nid(Config.host.nid)
                                
                                if self.dataType == .hex {
                                    let hexData = Data(hex: dataString)
                                    let encodedAsData = hexData.base64EncodedString(options: .lineLength64Characters)
                                    let dataDecoded: Data = Data(base64Encoded: encodedAsData, options: Data.Base64DecodingOptions.ignoreUnknownCharacters)!
                                    
                                    if let str = String(data: dataDecoded, encoding: .utf8) {
                                        messageTx.message(str)
                                    }
                                    
                                } else { // utf8
                                    messageTx.message(dataString)
                                }
                                
                                return messageTx
                                
                            } else {
                                let tx = Transaction()
                                    .from(wallet.address)
                                    .to(toAddress)
                                    .value(amount)
                                    .stepLimit(self.stepLimit)
                                    .nid(Config.host.nid)
                                
                                return tx
                            }
                        }()
                        
                        return SendInfo(transaction: tx, privateKey: pk, stepLimitPrice: stepLimitPrice, estimatedFee: estimatedFee, estimatedUSD: estimatedUSD)
                    }
                }()
                
                Alert.send(sendInfo: sendInfo, confirmAction: { isSuccess, txHash in
                    
                    self.dismiss(animated: true, completion: {
                        if let handler = self.sendHandler {
                            handler(isSuccess)
                        }
                    })
                    
                }).show()
                
        }.disposed(by: disposeBag)
    }
    
    private func setFooterBox() {
        let separated = String(self.stepLimit).currencySeparated()
        let priceToICX = self.stepPrice.toString(decimal: 18, 18, true)
        
        let stepLimitString = separated + " / " + priceToICX
        stepLimitLabel.size14(text: stepLimitString, color: .gray77, align: .right)
        
        let calculated = self.stepLimit * stepPrice
        let calculatedPrice = Tool.calculatePrice(decimal: 18, currency: "icxusd", balance: calculated)
        
        estimateFeeLabel.size14(text: calculated.toString(decimal: 18, 18, true), color: .gray77, align: .right)
        feePriceLabel.size12(text: calculatedPrice, color: .gray179, align: .right)
    }
}

extension SendICXViewController {
    func calcaulateStepLimit() -> BigUInt {
        guard let defaultStepCost = Manager.icon.stepCost?.defaultValue, let defaultStepLimit = defaultStepCost.hexToBigUInt() else { return 0 }
        var result: BigUInt = 0
        var counter: BigUInt = 0
        
        guard let dataString = self.data else { return result }
        guard let inputCostString = Manager.icon.stepCost?.input, let inputCost = inputCostString.hexToBigUInt() else { return result }
        
        if self.dataType == .hex {
            counter = BigUInt(dataString.bytes.count + 2)
        } else {
            guard let hexString = dataString.hexEncodedString() else { return result }
            counter = BigUInt(hexString.bytes.count + 2)
        }
        
        let dumped = inputCost * counter
        
        result += defaultStepLimit + dumped
        
        return result
    }
}


