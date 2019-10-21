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
    @IBOutlet weak var usdLabel: UILabel!
    
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
    @IBOutlet weak var showDataButton: UIButton!
    
    @IBOutlet weak var footerBox: UIView!
    @IBOutlet weak var estimatedMaxFeeTitleLabel: UILabel!
    @IBOutlet weak var estimatedFeeLabel: UILabel!
    @IBOutlet weak var estimatedExchangedLabel: UILabel!
    
    @IBOutlet weak var sendButton: UIButton!
    
    var walletInfo: BaseWalletConvertible? = nil
    var privateKey: String? = nil
    var token: Token? = nil {
        willSet {
            guard newValue != nil else { return }
            self.gasLimit = 55000
        }
    }
    
    var balance: BigUInt = 0
    var gasLimit: BigUInt = 21000
    var gasPrice: Int = 21
    var estimatedGas: BigUInt = 0
    
    var data: String? = nil {
        willSet {
            if newValue != nil {
                self.gasLimit = 55000
                self.gasLimitInputBox.text = "55000"
                self.gasLimitInputBox.textField.sendActions(for: .editingDidEndOnExit)
                
                self.inputDataButton.isEnabled = false
                self.showDataButton.isHidden = false
                self.dataInputBox.set(state: .readOnly)
                
            } else {
                self.gasLimit = 21000
                self.gasLimitInputBox.text = "21000"
                self.gasLimitInputBox.textField.sendActions(for: .editingDidEndOnExit)
                
                self.inputDataButton.isEnabled = true
                self.showDataButton.isHidden = true
            }
            
            self.estimatedGas = self.gasLimit * BigUInt(self.gasPrice)
        }
    }
    
    var sendHandler: ((_ isSuccess: Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBind()
    }
    
    private func setupUI() {
        guard let wallet = self.walletInfo else { return }
        
        // set up slider
        gasPriceSlider.corner(8)
        gasPriceSlider.border(0.5, .gray230)
        gasPriceSlider.backgroundColor = .gray252
        
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
        
        gasPriceTitleLabel.text = "Send.GasPrice".localized
        gweiTitleLabel.text = "GWei"
        slowLabel.text = "Send.GasPrice.Slow".localized
        fastLabel.text = "Send.GasPrice.Fast".localized
        
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
            let sendInfo = UIStoryboard(name: "Send", bundle: nil).instantiateViewController(withIdentifier: "SendInfo") as! SendInfoViewController
            sendInfo.type = "eth"
            self.presentPanModal(sendInfo)
        }
        if let token = self.token {
            balanceTitleLabel.size12(text: String(format: "Send.Balance.Avaliable.Token".localized, token.symbol) , color: .gray77, weight: .medium)
        } else {
            balanceTitleLabel.size12(text: "Send.Balance.Avaliable.ETH".localized, color: .gray77, weight: .medium)
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
        
        addressButton.roundGray230()
        scanButton.roundGray230()
        addressButton.setTitle("Send.AddressBook".localized, for: .normal)
        scanButton.setTitle("Send.ScanQRCode".localized, for: .normal)
        
        gasLimitInputBox.text = String(self.gasLimit)
        gasLimitInputBox.set(state: .normal, placeholder: "Send.GasLimit".localized)
        
        dataInputBox.set(inputType: .normal)
        dataInputBox.set(state: .normal, placeholder: "Send.InputBox.Data".localized)
        showDataButton.isHidden = true
        showDataButton.roundGray230()
        showDataButton.setTitle("Send.InputBox.Data.View".localized, for: .normal)
        
        footerBox.corner(8)
        footerBox.border(0.5, .gray230)
        footerBox.backgroundColor = .gray252
        
        estimatedMaxFeeTitleLabel.size12(text: "Send.EstimatedMaxStep".localized, color: .gray77, weight: .light)
        
        sendButton.lightMintRounded()
        sendButton.setTitle("Send.SendButton".localized, for: .normal)
        sendButton.isEnabled = false
        
        if let token = self.token {
            self.dataInputBox.isHidden = true
            balance = Manager.balance.getTokenBalance(address: token.parent, contract: token.contract)
            balanceLabel.size24(text: balance.toString(decimal: token.decimal, token.decimal).currencySeparated(), color: .mint1, align: .right)
            
            let price = Tool.calculatePrice(decimal: token.decimal, currency: "\(token.symbol.lowercased())usd", balance: balance)
            exchangeLabel .size12(text: price, color: .gray179, align: .right)
        } else {
            balance = Manager.balance.getBalance(wallet: wallet) ?? 0
            balanceLabel.size24(text: balance.toString(decimal: 18, 18).currencySeparated() , color: .mint1, align: .right)
            
            let price = Tool.calculatePrice(currency: "ethusd", balance: balance)
            exchangeLabel.size12(text: price, color: .gray179, align: .right)
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
                    self.amountInputBox.text = calculated.toString(decimal: token.decimal, token.decimal)
                } else {
                    let power = BigUInt(10).convert()
                    let currentValue = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: 18, fixed: true) ?? 0
                    
                    let calculated = currentValue + power
                    self.amountInputBox.text = calculated.toString(decimal: 18, 18)
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
                    self.amountInputBox.text = calculated.toString(decimal: token.decimal, token.decimal)
                } else {
                    let power = BigUInt(100).convert()
                    let currentValue = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: 18, fixed: true) ?? 0
                    
                    let calculated = currentValue + power
                    self.amountInputBox.text = calculated.toString(decimal: 18, 18)
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
                    self.amountInputBox.text = calculated.toString(decimal: token.decimal, token.decimal)
                } else {
                    let power = BigUInt(1000).convert()
                    let currentValue = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: 18, fixed: true) ?? 0
                    
                    let calculated = currentValue + power
                    self.amountInputBox.text = calculated.toString(decimal: 18, 18)
                }
                self.amountInputBox.textField.sendActions(for: .editingDidEndOnExit)
                
            }.disposed(by: disposeBag)
        
        maxButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.amountInputBox.textField.becomeFirstResponder()
                
                if let token = self.token {
                    self.amountInputBox.text = self.balance.toString(decimal: token.decimal, token.decimal, true)
                } else {
                    let gwei = self.gasLimit * BigUInt(10).power(9)
                    let gas = gwei * BigUInt(self.gasPrice)
                    
                    guard self.balance > gas else {
                        self.amountInputBox.text = "0"
                        return
                    }
                    
                    let maxBalance = self.balance - gas
                    self.amountInputBox.text = maxBalance.toString(decimal: 18, 18, true)
                }
                self.amountInputBox.textField.sendActions(for: .editingDidEndOnExit)
                
            }.disposed(by: disposeBag)
        
        inputDataButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.view.endEditing(true)
                
                let inputDataVC = self.storyboard?.instantiateViewController(withIdentifier: "InputData") as! InputDataViewController
                inputDataVC.type = .hex
                inputDataVC.completeHandler = { data, _ in
                    self.data = data
                    self.dataInputBox.text = data ?? ""
                    self.dataInputBox.textField.sendActions(for: .editingDidEndOnExit)
                }
                
                self.presentPanModal(inputDataVC)
                
            }.disposed(by: disposeBag)
        
        showDataButton.rx.tap
            .subscribe { (_) in
                guard let dataValue = self.data else { return }
                
                self.view.endEditing(true)
                
                let inputDataVC = self.storyboard?.instantiateViewController(withIdentifier: "InputData") as! InputDataViewController
                inputDataVC.type = .hex
                inputDataVC.data = dataValue
                inputDataVC.isViewMode = true
                inputDataVC.completeHandler = { data, _ in
                    self.data = data
                    self.dataInputBox.text = data ?? ""
                    self.dataInputBox.textField.sendActions(for: .editingDidEndOnExit)
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
                    return "ethusd"
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
                    self.addressInputBox.text = address.add0xPrefix()
                    self.addressInputBox.textField.sendActions(for: .editingDidEndOnExit)
                }
                
                self.presentPanModal(addressBook)
                
            }.disposed(by: disposeBag)
        
        scanButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.view.endEditing(true)
                
                let qrCodeReader = UIStoryboard(name: "Camera", bundle: nil).instantiateInitialViewController() as! QRReaderViewController
                qrCodeReader.modalPresentationStyle = .fullScreen
                qrCodeReader.set(mode: .eth, handler: { address, amount in
                    self.addressInputBox.text = address
                    self.addressInputBox.textField.sendActions(for: .editingDidEndOnExit)
                    if let a = amount?.hexToBigUInt()?.toString(decimal: 18, 18, true) {
                        self.amountInputBox.text = a
                        self.amountInputBox.textField.sendActions(for: .editingDidEndOnExit)
                    }
                })
                
                self.present(qrCodeReader, animated: true, completion: nil)
                
            }.disposed(by: disposeBag)
        
        gasLimitInputBox.set(inputType: .integer)
        gasLimitInputBox.set { (gasLimit) -> String? in
            guard !gasLimit.isEmpty else { return "Send.GasLimit.Error".localized }
            guard let gas = BigUInt(gasLimit) else {
                return "Send.GasLimit.Error".localized
            }
            
            if gas < 21000 {
                return "Send.GasLimit.Error".localized
            } else {
                self.gasLimit = gas
                return nil
            }
        }
        
        // 데이터 필드를 눌렀는데 이게 왜 불리지
        Observable.combineLatest(gasLimitInputBox.textField.rx.text.orEmpty, slider.rx.value).flatMapLatest { (limit, price) -> Observable<String> in
            let gasLimit = BigUInt(limit) ?? 0
            let gasPrice = BigUInt(price)
            
            let gas = gasLimit * gasPrice
            let wei = gas * BigUInt(10).power(9)
            
            let result = wei.toString(decimal: 18, 18, true).currencySeparated()
            
            let price = Tool.calculatePrice(currency: "ethusd", balance: wei)
            self.estimatedExchangedLabel.text = price
            
            return Observable.just(result)
        }.bind(to: self.estimatedFeeLabel.rx.text)
        .disposed(by: disposeBag)
        
        Observable.combineLatest(self.amountInputBox.textField.rx.text.orEmpty, self.addressInputBox.textField.rx.text.orEmpty, self.dataInputBox.textField.rx.text.orEmpty)
            .subscribe(onNext: { (amount, address, data) in

                guard !amount.isEmpty && !address.isEmpty else { return }
                
                if data.isEmpty {
                    self.gasLimit = 21000
                    self.gasLimitInputBox.text = "21000"
                    self.gasLimitInputBox.textField.sendActions(for: .editingDidEndOnExit)
                    
                } else {
                    let value = Tool.stringToBigUInt(inputText: amount, decimal: 18, fixed: true) ?? 0
                    guard let wallet = self.walletInfo else { return }
                    
                    DispatchQueue.global().async {
                        self.gasLimit = Ethereum.requestETHEstimatedGas(value: value, data: data.prefix0xRemoved().hexToData() ?? Data(), from: wallet.address, to: address) ?? 0
                        DispatchQueue.main.async {
                            self.gasLimitInputBox.textField.text = "\(self.gasLimit)"
                            self.gasLimitInputBox.textField.sendActions(for: .editingDidEndOnExit)
                        }
                    }
                }
            }).disposed(by: disposeBag)
        
        // send
        Observable.combineLatest(self.amountInputBox.textField.rx.text.orEmpty, self.addressInputBox.textField.rx.text.orEmpty, self.gasLimitInputBox.textField.rx.text.orEmpty)
            .flatMapLatest { [unowned self] (value, address, gasLimit) -> Observable<Bool> in
                guard !value.isEmpty && !address.isEmpty else { return Observable.just(false) }
                
                guard address != wallet.address else { return Observable.just(false) }
                
                guard let gasLimitBigValue = BigUInt(gasLimit), gasLimitBigValue >= 21000 else { return Observable.just(false) }
                
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
                
                if amount > self.balance {
                    return Observable.just(false)
                }
                
                return Observable.just(true)
            }.bind(to: self.sendButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        sendButton.rx.tap
            .subscribe { (_) in
                guard let pk = self.privateKey else { return }
                guard let wallet = self.walletInfo else { return }
                
                let amount = Tool.stringToBigUInt(inputText: self.amountInputBox.text, decimal: 18, fixed: true) ?? 0
                let toAddress = self.addressInputBox.text.add0xPrefix()
                
                let gasPrice = self.gasPrice
                let gasLimit = self.gasLimit
                
                let data = self.data?.prefix0xRemoved().hexToData() ?? Data()

                let estimatedGas = BigUInt(self.gasPrice) * self.gasLimit
                let gas = estimatedGas.convert(unit: .gLoop)
                
                // send ETH
                if self.token == nil {
                    if amount + gas > self.balance {
                        Alert.basic(title: "Send.Error.InsufficientFee.ETH".localized, leftButtonTitle: "Common.Confirm".localized).show()
                        return
                    }
                } else { // send token
                    let ethBalance = Manager.balance.getBalance(wallet: wallet) ?? 0
                    if gas > ethBalance {
                        Alert.basic(title: "Send.Error.InsufficientFee.ETH".localized, leftButtonTitle: "Common.Confirm".localized).show()
                        return
                    }
                }
                
                let sendInfo: SendInfo = {
                    let ethTx = EthereumTransaction(privateKey: pk, gasPrice: BigUInt(self.gasPrice), gasLimit: gasLimit, from: wallet.address, to: toAddress, value: amount, data: data)
                    
                    let usd = Tool.calculatePrice(currency: "ethusd", balance: gas)
                    
                    if let token = self.token {
                        return SendInfo(ethTransaction: ethTx, ethPrivateKey: pk, stepLimitPrice: String(gasPrice), estimatedFee: gas.toString(decimal: 18, 18, true), estimatedUSD: usd, token: token)
                        
                    } else {
                        return SendInfo(ethTransaction: ethTx, ethPrivateKey: pk, stepLimitPrice: String(gasPrice), estimatedFee: gas.toString(decimal: 18, 18, true), estimatedUSD: usd)
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
