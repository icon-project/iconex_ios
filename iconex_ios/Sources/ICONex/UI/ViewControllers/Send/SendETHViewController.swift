//
//  SendETHViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 02/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import BigInt

class SendETHViewController: BaseViewController {
    @IBOutlet weak var navBar: IXNavigationView!
    
    @IBOutlet weak var balanceTitleLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var exchangeLabel: UILabel!
    
    @IBOutlet weak var amountInputBox: IXInputBox!
    
    @IBOutlet weak var plus10Button: UIButton!
    @IBOutlet weak var plus100Button: UIButton!
    @IBOutlet weak var plus1000Button: UIButton!
    @IBOutlet weak var maxButton: UIButton!
    
    @IBOutlet weak var addressInputBox: IXInputBox!
    
    @IBOutlet weak var addressButton: UIButton!
    @IBOutlet weak var scanButton: UIButton!
    
    @IBOutlet weak var gasLimitInputBox: IXInputBox!
    
    @IBOutlet weak var gasPriceSlider: UIView!
    
    @IBOutlet weak var gasPriceTitleLabel: UILabel!
    
    @IBOutlet weak var gweiLabel: UILabel!
    @IBOutlet weak var gweiTitleLabel: UILabel!
    
    @IBOutlet weak var slowLabel: UILabel!
    @IBOutlet weak var fastLabel: UILabel!
    
    @IBOutlet weak var sliderContainer: UIView!
    @IBOutlet weak var minView: UIView!
    @IBOutlet weak var maxView: UIView!
    
    @IBOutlet weak var minWidth: NSLayoutConstraint!
    
    
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var dataInputBox: IXInputBox!
    @IBOutlet weak var inputDataButton: UIButton!
    @IBOutlet weak var viewDataButton: UIButton!
    
    @IBOutlet weak var footerBox: UIView!
    @IBOutlet weak var estimatedMaxFeeTitleLabel: UILabel!
    @IBOutlet weak var estimatedFeeLabel: UILabel!
    @IBOutlet weak var estimatedExchangedLabel: UILabel!
    
    @IBOutlet weak var sendButton: UIButton!
    
    var walletInfo: BaseWalletConvertible? = nil
    var privateKey: String? = nil
    var token: Token? = nil {
        willSet {
            // send token
            self.gasLimit = 55000
        }
    }
    
    var balance: BigUInt = 0
    var gasLimit: BigUInt = 21000
    var gasPrice: Int = 21
    
    var data: String? = nil {
        willSet {
            guard let value = newValue else { return }
            guard let wallet = self.walletInfo else { return }
            
            if !value.isEmpty {
                self.inputDataButton.isEnabled = false
                self.viewDataButton.isHidden = false
                self.dataInputBox.set(state: .readOnly)
            } else {
                self.gasLimit = 21000
                self.gasLimitInputBox.text = "21000"
                self.gasLimitInputBox.textField.sendActions(for: .valueChanged)
                
                self.inputDataButton.isEnabled = true
                self.viewDataButton.isHidden = true
            }
        }
    }
    
    var sendHandler: ((_ isSuccess: Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.global().async {
            if let token = self.token {
                self.balance = Manager.balance.getTokenBalance(address: token.parent, contract: token.contract)
                DispatchQueue.main.async {
                    self.balanceLabel.size24(text: self.balance.toString(decimal: token.decimal, 5).currencySeparated(), color: .mint1, align: .right)
                }
            } else {
                guard let wallet = self.walletInfo else { return }
                self.balance = Manager.balance.getBalance(wallet: wallet) ?? 0
                DispatchQueue.main.async {
                    self.balanceLabel.size24(text: self.balance.toString(decimal: 18, 5).currencySeparated(), color: .mint1, align: .right)
                }
            }
        }
        
        setupUI()
        setupBind()
        
        self.scrollView?.rx.didScroll
            .subscribe({ (_) in
                self.view.endEditing(true)
            }).disposed(by: disposeBag)
    }
    
    private func setupUI() {
        guard let wallet = self.walletInfo else { return }
        
        // set up slider
        self.minView.layer.cornerRadius = 4
        self.minView.clipsToBounds = true
        self.maxView.layer.cornerRadius = 4
        self.maxView.clipsToBounds = true
        
        self.minView.backgroundColor = .mint2
        self.maxView.backgroundColor = .gray77
        
        slider.minimumValue = 1.0
        slider.maximumValue = 99.0
        slider.setThumbImage(#imageLiteral(resourceName: "icControlerEnabled"), for: .normal)
        slider.setThumbImage(#imageLiteral(resourceName: "icControlerAtive"), for: .highlighted)
        
        slider.value = Float(self.gasPrice)
        
        slider.rx.value.subscribe(onNext: { (value) in
            let percent = value / 99.0
            self.minWidth.constant = (self.sliderContainer.frame.width - 2) * CGFloat(percent)
            
            let rounded = Int(value)
            self.gasPrice = rounded
            self.gweiLabel.text = "\(rounded)"
        }).disposed(by: disposeBag)
        
        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarCloseW")) {
            self.dismiss(animated: true, completion: nil)
        }
        navBar.setTitle(wallet.name)
        navBar.setRight(image: #imageLiteral(resourceName: "icInfoW")) {
            // TODO
        }
        balanceTitleLabel.size12(text: "Send.Balance.Avaliable.ETH".localized, color: .gray77, weight: .medium)
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
        
        addressButton.roundGray230()
        scanButton.roundGray230()
        addressButton.setTitle("Send.AddressBook".localized, for: .normal)
        scanButton.setTitle("Send.ScanQRCode".localized, for: .normal)
        
        gasLimitInputBox.text = String(self.gasLimit)
        
        
        dataInputBox.set(inputType: .normal)
        dataInputBox.set(state: .normal, placeholder: "Send.InputBox.Data".localized)
        viewDataButton.isHidden = true
        viewDataButton.roundGray230()
        
        footerBox.corner(8)
        footerBox.border(0.5, .gray230)
        footerBox.backgroundColor = .gray252
        
        estimatedMaxFeeTitleLabel.size12(text: "Send.EstimatedMaxStep".localized, color: .gray77, weight: .light)
        
        sendButton.lightMintRounded()
        sendButton.setTitle("Send.SendButton".localized, for: .normal)
        sendButton.isEnabled = false
        
        if let token = self.token {
            balance = Manager.balance.getTokenBalance(address: token.parent, contract: token.contract)
            balanceLabel.size24(text: balance.toString(decimal: token.decimal, 5).currencySeparated(), color: .mint1, align: .right)
            
            let price = Tool.calculatePrice(decimal: token.decimal, currency: "\(token.symbol.lowercased())usd", balance: balance)
            exchangeLabel .size12(text: price, color: .gray179, align: .right)
        } else {
            balance = Manager.balance.getBalance(wallet: wallet) ?? 0
            balanceLabel.size24(text: balance.toString(decimal: 18, 5).currencySeparated() , color: .mint1, align: .right)
            
            let price = Tool.calculatePrice(currency: "ethusd", balance: balance)
            exchangeLabel.size12(text: price, color: .gray179, align: .right)
        }
    }
    
    private func setupBind() {
        guard let wallet = self.walletInfo else { return }
        
        plus10Button.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.amountInputBox.textField.becomeFirstResponder()
                
                if let token = self.token {
                    let power = BigUInt(10) * BigUInt(10).power(token.decimal)
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
                    self.amountInputBox.text = calculated.toString(decimal: 18, 18, false)
                }
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
                    self.amountInputBox.text = calculated.toString(decimal: 18, 18, false)
                }
            }.disposed(by: disposeBag)
        
        maxButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.amountInputBox.textField.becomeFirstResponder()
                
                if let token = self.token {
                    self.amountInputBox.text = self.balance.toString(decimal: token.decimal, token.decimal, false)
                } else {
                    let maxBalance = self.balance - self.gasLimit
                    self.amountInputBox.text = maxBalance.toString(decimal: 18, 18, false)
                }
            }.disposed(by: disposeBag)
        
        inputDataButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.view.endEditing(true)
                
                let inputDataVC = self.storyboard?.instantiateViewController(withIdentifier: "InputData") as! InputDataViewController
                inputDataVC.type = .hex
                inputDataVC.completeHandler = { data, _ in
                    self.data = data
                    self.dataInputBox.text = data
                    self.dataInputBox.textField.sendActions(for: .valueChanged)
                }
                
                self.presentPanModal(inputDataVC)
                
            }.disposed(by: disposeBag)
        
        viewDataButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                guard let dataValue = self.data else { return }
                
                self.view.endEditing(true)
                
                let inputDataVC = self.storyboard?.instantiateViewController(withIdentifier: "InputData") as! InputDataViewController
                inputDataVC.type = .hex
                inputDataVC.data = dataValue
                inputDataVC.completeHandler = { data, _ in
                    self.data = data
                    self.dataInputBox.text = data
                    self.dataInputBox.textField.sendActions(for: .valueChanged)
                }
                
                self.presentPanModal(inputDataVC)
        }.disposed(by: disposeBag)
        
        amountInputBox.set { [unowned self] (value) -> String? in
            guard !value.isEmpty else { return nil }
            
            if let token = self.token {
                let amount = Tool.stringToBigUInt(inputText: value, decimal: token.decimal, fixed: true) ?? 0
                
                if amount > self.balance + self.gasLimit {
                    return "Send.InputBox.Amount.Error".localized
                }
                return nil
                
            } else {
                let amount = Tool.stringToBigUInt(inputText: value, decimal: 18, fixed: true) ?? 0
                
                if amount > self.balance + self.gasLimit {
                    return "Send.InputBox.Amount.Error".localized
                }
                return nil
            }
            
        }
        
        // address
        addressInputBox.set { (address) -> String? in
            guard !address.isEmpty else { return nil }
            
            if Validator.validateETHAddress(address: address) {
                return nil
            } else {
                return "Send.InputBox.Address.Error.ETH".localized
            }
        }
        
        addressButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.view.endEditing(true)
                
                let addressBook = self.storyboard?.instantiateViewController(withIdentifier: "AddressBook") as! AddressBookViewController
                addressBook.myAddress = wallet.address
                addressBook.isICX = false
                
                if let token = self.token {
                    addressBook.token = token
                }
                
                addressBook.selectedHandler = { address in
                    self.addressInputBox.text = address
                    self.addressInputBox.textField.sendActions(for: .valueChanged)
                }
                
                self.presentPanModal(addressBook)
                
            }.disposed(by: disposeBag)
        
        scanButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.view.endEditing(true)
                
                let qrCodeReader = UIStoryboard(name: "Camera", bundle: nil).instantiateInitialViewController() as! QRReaderViewController
                
                qrCodeReader.set(mode: .eth, handler: { (address) in
                    self.addressInputBox.text = address
                    self.addressInputBox.textField.sendActions(for: .valueChanged)
                    
                    if address == wallet.address {
                        self.addressInputBox.setError(message: "Send.InputBox.Address.Error.SameAddress".localized)
                    }
                })
                
                self.present(qrCodeReader, animated: true, completion: nil)
                
            }.disposed(by: disposeBag)
        
        Observable.combineLatest(self.amountInputBox.textField.rx.text.orEmpty, self.addressInputBox.textField.rx.text.orEmpty, self.dataInputBox.textField.rx.text.orEmpty)
            .subscribe(onNext: { (amount, address, data) in

                guard !amount.isEmpty && !address.isEmpty else { return }
                
                if data.isEmpty {
                    self.gasLimit = 21000
                    self.gasLimitInputBox.text = "21000"
                    
                } else {
                    let value = Tool.stringToBigUInt(inputText: amount, decimal: 18, fixed: true) ?? 0
                    guard let wallet = self.walletInfo else { return }
                    
                    DispatchQueue.global().async {
                        self.gasLimit = Ethereum.requestETHEstimatedGas(value: value, data: data.prefix0xRemoved().hexToData() ?? Data(), from: wallet.address, to: address) ?? 0
                        
                        DispatchQueue.main.async {
                            self.gasLimitInputBox.textField.text = "\(self.gasLimit)"
                            
                            self.estimatedFeeLabel.size14(text: self.gasLimit.toString(decimal: 9, 9), color: .gray77, align: .right)
                        }
                    }
                }
            }).disposed(by: disposeBag)
        
        // send
        Observable.combineLatest(self.amountInputBox.textField.rx.text.orEmpty, self.addressInputBox.textField.rx.text.orEmpty)
            .flatMapLatest { [unowned self] (value, address) -> Observable<Bool> in
                guard !value.isEmpty && !address.isEmpty else { return Observable.just(false) }
                
                guard address != wallet.address else { return Observable.just(false) }
                
                // address
                guard Validator.validateETHAddress(address: address) else {
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
                
                if amount > self.balance + self.gasLimit {
                    return Observable.just(false)
                }
                
                return Observable.just(true)
            }.bind(to: self.sendButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        sendButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                guard let pk = self.privateKey else { return }
                
                let amount = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: 18, fixed: true) ?? 0
                let toAddress = self.addressInputBox.text
                let gasPrice = self.gasPrice
                let gasLimit = self.gasLimit
                let data = self.data?.prefix0xRemoved().hexToData() ?? Data()
                let estimatedGas = BigUInt(self.gasPrice) * self.gasLimit
                
                if self.balance < estimatedGas {
                    Alert.basic(title: "Send.Error.InsufficientFee.ETH".localized, leftButtonTitle: "Common.Confirm".localized).show()
                    return
                }
                
                let sendInfo: SendInfo = {
                    let ethTx = EthereumTransaction(privateKey: pk, gasPrice: BigUInt(self.gasPrice), gasLimit: gasLimit, from: wallet.address, to: toAddress, value: amount, data: data)
                    
                    if let token = self.token {
                        let usd = Tool.calculatePrice(decimal: token.decimal, currency: "\(token.symbol.lowercased())usd", balance: estimatedGas)
                        return SendInfo(ethTransaction: ethTx, ethPrivateKey: pk, stepLimitPrice: String(gasPrice), estimatedFee: "\(estimatedGas)", estimatedUSD: usd)
                        
                    } else {
                        let usd = Tool.calculatePrice(currency: "ethusd", balance: estimatedGas)
                        return SendInfo(ethTransaction: ethTx, ethPrivateKey: pk, stepLimitPrice: String(gasPrice), estimatedFee: "\(estimatedGas)", estimatedUSD: usd)
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
}
