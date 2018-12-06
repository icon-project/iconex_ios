//
//  ICXSendViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import BigInt
import ICONKit

class ICXSendViewController: BaseViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var topCloseButton: UIButton!
    @IBOutlet weak var topTitle: UILabel!
    
    @IBOutlet weak var balanceTitle: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var exchangedBalanceLabel: UILabel!
    
    @IBOutlet weak var sendContainer: UIView!
    @IBOutlet weak var sendTitle: UILabel!
    @IBOutlet weak var sendInputBox: IXInputBox!
    @IBOutlet weak var add1: UIButton!
    @IBOutlet weak var add2: UIButton!
    @IBOutlet weak var add3: UIButton!
    @IBOutlet weak var add4: UIButton!
    
    @IBOutlet weak var addressContainer: UIView!
    @IBOutlet weak var selectAddressButton: UIButton!
    @IBOutlet weak var scanButton: UIButton!
    
    @IBOutlet weak var toTitle: UILabel!
    @IBOutlet weak var addressInputBox: IXInputBox!
    
    @IBOutlet weak var stepStack: UIStackView!
    @IBOutlet weak var stepLimitTitle: UILabel!
    @IBOutlet weak var stepLimitInfo: UIButton!
    @IBOutlet weak var limitInputBox: IXInputBox!
    
    @IBOutlet weak var stepPriceTitle: UILabel!
    @IBOutlet weak var stepPriceInfo: UIButton!
    @IBOutlet weak var stepPriceLabel: UILabel!
    @IBOutlet weak var stepExchangedLabel: UILabel!
    
    @IBOutlet weak var dataContainer: UIView!
    @IBOutlet weak var dataTitle: UILabel!
    @IBOutlet weak var dataInfo: UIButton!
    @IBOutlet weak var dataInputControl: UIButton!
    
    
    @IBOutlet weak var feeTitle: UILabel!
    @IBOutlet weak var feeAmountLabel: UILabel!
    @IBOutlet weak var exchangedFeeLabel: UILabel!
    @IBOutlet weak var feeInfo: UIButton!
    
    @IBOutlet weak var remainTitle: UILabel!
    @IBOutlet weak var remainBalance: UILabel!
    @IBOutlet weak var exchangedRemainLabel: UILabel!
    
    @IBOutlet weak var sendButton: UIButton!
    
    var walletInfo: WalletInfo?
    var token: TokenInfo?
    var totalBalance: BigUInt?
    var privateKey: String?
    var stepPrice: BigUInt?
    var inputData: String? = nil {
        willSet {
            if newValue == nil {
                dataInputControl.setTitle("Transfer.Data.Input".localized, for: .normal)
                dataInputControl.backgroundColor = UIColor.white
                dataInputControl.setTitleColor(UIColor.black, for: .normal)
            } else {
                dataInputControl.setTitle("Transfer.Data.View".localized, for: .normal)
                dataInputControl.backgroundColor = UIColor.black
                dataInputControl.setTitleColor(UIColor.white, for: .normal)
            }
        }
    }
    
    var costs: Response.StepCosts?
    var minLimit: BigUInt?
    var maxLimit: BigUInt?
    
    var selectedDataType: EncodeType = .utf8
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.global(qos: .utility).async {
            if let cost = WManager.getStepCosts() {
                self.costs = cost
                self.minLimit = BigUInt(cost.defaultValue.prefix0xRemoved(), radix: 16)
            }
            
            if let maxLimit = WManager.getMaxStepLimit() {
                self.maxLimit = maxLimit
            }
            
            DispatchQueue.main.async {
                self.calculateStepPrice()
                self.validateLimit(false)
            }
        }
        
        self.getStepPrice()
        
        guard let walletInfo = self.walletInfo else {
            return
        }
        guard let wallet = WManager.loadWalletBy(info: walletInfo) else { return }
        topTitle.text = wallet.alias!
        
        if let token = self.token {
            self.dataContainer.isHidden = true
            if let balances = WManager.tokenBalanceList[token.dependedAddress.add0xPrefix()], let balance = balances[token.contractAddress] {
                let printBalance = Tools.bigToString(value: balance, decimal: wallet.decimal, wallet.decimal, false)
                balanceLabel.text = printBalance
                
                let type = token.symbol
                if let exchanged = Tools.balanceToExchange(balance, from: type, to: "usd", belowDecimal: 2, decimal: token.decimal) {
                    exchangedBalanceLabel.text = exchanged.currencySeparated() + " USD"
                } else {
                    exchangedBalanceLabel.text = "- USD"
                }
                totalBalance = balance
                
                guard let _ = self.stepPrice, let stepLimit = self.limitInputBox.textField.text, stepLimit != "" else {
                    remainBalance.text = printBalance
                    if let exc = Tools.balanceToExchange(balance, from: token.symbol, to: "usd", belowDecimal: 2, decimal: token.decimal) {
                        exchangedRemainLabel.text = exc.currencySeparated() + " USD"
                    } else {
                        exchangedRemainLabel.text = "- USD"
                    }
                    return
                }
            }
        } else {
            self.dataContainer.isHidden = false
            if let balance = WManager.walletBalanceList[wallet.address!] {
                let printBalance = Tools.bigToString(value: balance, decimal: wallet.decimal, wallet.decimal, false)
                balanceLabel.text = printBalance
                
                let type = self.walletInfo!.type.rawValue
                let exchanged = Tools.balanceToExchange(balance, from: type, to: "usd", belowDecimal: 2, decimal: wallet.decimal)
                exchangedBalanceLabel.text = exchanged == nil ? "0.0 USD" : exchanged!.currencySeparated() + " USD"
                totalBalance = balance
                
                guard let _ = self.stepPrice, let stepLimit = self.limitInputBox.textField.text, stepLimit != "" else {
                    remainBalance.text = printBalance
                    if let exc = Tools.balanceToExchange(balance, from: type, to: "usd", belowDecimal: 2, decimal: wallet.decimal) {
                        exchangedRemainLabel.text = exc.currencySeparated() + " USD"
                    } else {
                        exchangedRemainLabel.text = "- USD"
                    }
                    return
                }
            }
        }
        
        self.validateLimit()
    }
    
    func initialize() {
        topCloseButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
        
        scrollView.rx.didEndDragging.observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] _ in
            self.view.endEditing(true)
        }).disposed(by: disposeBag)
        
        sendInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.sendInputBox.setState(.focus)
        }).disposed(by: disposeBag)
        sendInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.sendButton.isEnabled = self.validation()
        }).disposed(by: disposeBag)
        sendInputBox.textField.rx.controlEvent(UIControlEvents.editingChanged).subscribe(onNext: { [unowned self] in
            guard let sendValue = self.sendInputBox.textField.text, let send = Tools.stringToBigUInt(inputText: sendValue) else {
                return
            }
            
            var exchanged: String? = nil
            
            if let token = self.token {
                exchanged = Tools.balanceToExchange(send, from: token.symbol.lowercased(), to: "usd", belowDecimal: 2, decimal: token.decimal)
            } else {
                exchanged = Tools.balanceToExchange(send, from: "icx", to: "usd", belowDecimal: 2, decimal: 18)
            }
            
            if let exx = exchanged {
                self.sendInputBox.setState(.exchange, exx.currencySeparated() + " USD")
            } else {
                self.sendInputBox.setState(.exchange, "- USD")
            }
            
        }).disposed(by: disposeBag)
        
        add1.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let formerValue = Tools.stringToBigUInt(inputText: self.sendInputBox.textField.text!) else {
                    return
                }
                guard let walletInfo = self.walletInfo, let wallet = WManager.loadWalletBy(info: walletInfo) else { return }
                var decimal = 0
                if let token = self.token {
                    decimal = token.defaultDecimal
                } else {
                    decimal = wallet.decimal
                }
                let result = formerValue + BigUInt(10).power(decimal + 1)
                Log.Debug(result)
                let stringValue = Tools.bigToString(value: result, decimal: decimal, decimal)
                self.sendInputBox.textField.text = stringValue
                self.sendInputBox.textField.becomeFirstResponder()
                self.validateBalance()
            }).disposed(by: disposeBag)
        
        add2.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let formerValue = Tools.stringToBigUInt(inputText: self.sendInputBox.textField.text!) else {
                    return
                }
                guard let walletInfo = self.walletInfo, let wallet = WManager.loadWalletBy(info: walletInfo) else { return }
                var decimal = 0
                if let token = self.token {
                    decimal = token.defaultDecimal
                } else {
                    decimal = wallet.decimal
                }
                let result = formerValue + BigUInt(10).power(decimal + 2)
                Log.Debug(result)
                let stringValue = Tools.bigToString(value: result, decimal: decimal, decimal, true)
                self.sendInputBox.textField.text = stringValue
                self.sendInputBox.textField.becomeFirstResponder()
                self.validateBalance()
            }).disposed(by: disposeBag)
        
        add3.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let formerValue = Tools.stringToBigUInt(inputText: self.sendInputBox.textField.text!) else {
                    return
                }
                guard let walletInfo = self.walletInfo, let wallet = WManager.loadWalletBy(info: walletInfo) else { return }
                var decimal = 0
                if let token = self.token {
                    decimal = token.defaultDecimal
                } else {
                    decimal = wallet.decimal
                }
                let result = formerValue + BigUInt(10).power(decimal + 3)
                Log.Debug(result)
                let stringValue = Tools.bigToString(value: result, decimal: decimal, decimal, true)
                self.sendInputBox.textField.text = stringValue
                self.sendInputBox.textField.becomeFirstResponder()
                self.validateBalance()
            }).disposed(by: disposeBag)
        
        add4.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let totalBalance = self.totalBalance else { return }
                guard let walletInfo = self.walletInfo else { return }
                guard let wallet = WManager.loadWalletBy(info: walletInfo) else { return }
                guard let stepPrice = self.stepPrice else { return }

                if let token = self.token {
                    guard let balance = WManager.tokenBalanceList[token.dependedAddress.add0xPrefix()]?[token.contractAddress] else { return }
                    self.sendInputBox.textField.text = Tools.bigToString(value: balance, decimal: token.decimal, token.decimal, true)
                } else {
                    guard let _ = WManager.walletBalanceList[wallet.address!] else { return }
                    var tmpStepLimit = BigUInt(0)
                    if let stepLimit = self.limitInputBox.textField.text, let limit = BigUInt(stepLimit) {
                        tmpStepLimit = limit
                    }
                    let feeValue = (stepPrice * tmpStepLimit)
                    Log.Debug("feeValue - \(feeValue)")
                    if feeValue > totalBalance {
                        self.view.endEditing(true)
                        self.validateBalance(true)
                        return
                    }
                    
                    let sendValue = totalBalance - feeValue
                    
                    self.sendInputBox.textField.text = Tools.bigToString(value: sendValue, decimal: wallet.decimal, wallet.decimal, true)
                    
                }
                self.sendInputBox.textField.becomeFirstResponder()
                self.validateBalance()
                self.validateLimit()
            }).disposed(by: disposeBag)
        
        addressInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.addressInputBox.setState(.focus)
        }).disposed(by: disposeBag)
        addressInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            if self.validateAddress() {
                self.sendButton.isEnabled = self.validation()
            }
        }).disposed(by: disposeBag)
        
        selectAddressButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            let addressManage = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "AddressManageView") as! AddressManageViewController
            addressManage.walletInfo = self.walletInfo
            addressManage.selectHandler = { (address) in
                self.addressInputBox.textField.text = address
                self.sendButton.isEnabled = self.validation()
                addressManage.dismiss(animated: true, completion: {
                    
                })
            }
            
            self.present(addressManage, animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        scanButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                let reader = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "QRReaderView") as! QRReaderViewController
                reader.mode = .address(.send)
                reader.type = .icx
                reader.handler = { code in
                    self.addressInputBox.textField.text = code
                    self.addressInputBox.textField.becomeFirstResponder()
                    self.validateAddress()
                }
                
                reader.show(self)
            }).disposed(by: disposeBag)
        
        stepLimitInfo.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            let attr1 = NSAttributedString(string: "Transfer.Step.LimitInfo.First".localized, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15, weight: .bold)])
            let attr2 = NSAttributedString(string: "Transfer.Step.LimitInfo.Second".localized)
            let attr = NSMutableAttributedString(attributedString: attr1)
            attr.append(attr2)
            Alert.Basic(attributed: attr).show(self)
        }).disposed(by: disposeBag)
        
        limitInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.limitInputBox.setState(.focus)
        }).disposed(by: disposeBag)
        limitInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            if self.validateLimit() {
                self.sendButton.isEnabled = self.validation()
            }
        }).disposed(by: disposeBag)
        
        stepPriceInfo.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            let attr1 = NSAttributedString(string: "Transfer.Step.PriceInfo.First".localized + "\n", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15, weight: .bold)])
            let attr2 = NSAttributedString(string: "Transfer.Step.PriceInfo.Second".localized)
            let attr3 = NSAttributedString(string: "Transfer.Step.PriceInfo.Third".localized)
            let superscript = NSMutableAttributedString(string: "Transfer.Step.PriceInfo.Superscript".localized)
            superscript.setAttributes([NSAttributedStringKey.baselineOffset: 10, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 7)], range: NSRange(location: 2, length: 3))
            
            let attr = NSMutableAttributedString(attributedString: attr1)
            attr.append(attr2)
            attr.append(superscript)
            attr.append(attr3)
            Alert.Basic(attributed: attr).show(self)
        }).disposed(by: disposeBag)
        
        dataInfo.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: {[ unowned self] in
            Alert.Basic(message: "Transfer.Data.Info".localized).show(self)
        }).disposed(by: disposeBag)
        
        dataInputControl.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            if let savedData = self.inputData {
                let dataInput = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ICXDataInputView") as! ICXDataInputViewController
                dataInput.type = self.selectedDataType
                dataInput.savedData = savedData
                dataInput.walletAmount = self.totalBalance
                dataInput.stepPrice = self.stepPrice
                let value = self.sendInputBox.textField.text!
                if let sendValue = Tools.stringToBigUInt(inputText: value) {
                    dataInput.sendAmount = sendValue
                }
                dataInput.costs = self.costs
                dataInput.handler = { [unowned self] data in
                    self.inputData = data
                    self.calculateStepPrice()
                }
                self.present(dataInput, animated: true, completion: nil)
            } else {
                let selectData = UIStoryboard(name: "ActionControls", bundle: nil).instantiateViewController(withIdentifier: "DataInputSourceView") as! DataInputSourceViewController
                selectData.handler = { [unowned self] selected in
                    self.selectedDataType = selected
                    let dataInput = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ICXDataInputView") as! ICXDataInputViewController
                    dataInput.type = selected
                    dataInput.savedData = nil
                    dataInput.walletAmount = self.totalBalance
                    dataInput.stepPrice = self.stepPrice
                    let value = self.sendInputBox.textField.text!
                    if let sendValue = Tools.stringToBigUInt(inputText: value) {
                        dataInput.sendAmount = sendValue
                    }
                    dataInput.costs = self.costs
                    dataInput.handler = { [unowned self] data in
                        self.inputData = data
                        self.calculateStepPrice()
                    }
                    self.present(dataInput, animated: true, completion: nil)
                }
                
                selectData.present(from: self)
            }
        }).disposed(by: disposeBag)
        
        feeInfo.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            Alert.Basic(message: "Transfer.EstimatedStep".localized).show(self)
        }).disposed(by: disposeBag)
        
        keyboardHeight().observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] (height: CGFloat) in
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
        
        sendButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            
            let value = self.sendInputBox.textField.text!
            let bigValue = Tools.stringToBigUInt(inputText: value)!
            let icxValue = Tools.bigToString(value: bigValue, decimal: 18, 18, false)
            
            let to = self.addressInputBox.textField.text!
            
            let confirm = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "SendConfirmView") as! SendConfirmViewController
            if let token = self.token {
                confirm.type = token.symbol
            } else {
                confirm.type = self.walletInfo!.type.rawValue
            }
            confirm.feeType = self.walletInfo!.type.rawValue
            confirm.value = icxValue
            confirm.address = to
            
            guard let stepPrice = self.stepPrice, let stepLimit = self.limitInputBox.textField.text, let limit = BigUInt(stepLimit) else { return }
            guard let prvKey = self.privateKey, let walletInfo = self.walletInfo else { return }
            let estimatedStep = limit * stepPrice
            
            confirm.fee = Tools.bigToString(value: estimatedStep, decimal: 18, 18, false)
            confirm.handler = {
                
                if let token = self.token {
                    let result = WManager.sendIRCToken(privateKey: prvKey, from: walletInfo.address, to: to, contractAddress: token.contractAddress, value: bigValue, stepLimit: limit)

                    switch result {
                    case .success(let txHash):
                        Log.Debug("txHash: \(txHash)")

                        confirm.dismiss(animated: true, completion: {
                            Tools.toast(message: "Transfer.RequestComplete".localized)
                            self.navigationController?.popViewController(animated: true)
                        })

                    case .failure(let error):
                        Log.Debug("Error - \(error)")
                        if let loadingView = confirm.confirmButton.viewWithTag(999) {
                            loadingView.removeFromSuperview()
                        }
                        var message = ""
                        switch error {
                        case .httpError(let msg):
                            if let http = msg {
                                message = "\n" + http
                            }
                            
                        default:
                            break
                        }
                        
                        confirm.confirmButton.isEnabled = true
                        confirm.confirmButton.setTitle("Transfer.Transfer".localized, for: .normal)
                        Tools.toast(message: "Error.CommonError".localized + message)
                    }
                } else {
                    var data: String? = nil
                    if let message = self.inputData {
                        if self.selectedDataType == .utf8 {
                            if let tData = message.data(using: .utf8) {
                                data = "0x" + tData.toHexString()
                            }
                        } else {
                            data = message
                        }
                    }

                    let result = WManager.sendICX(privateKey: prvKey, from: self.walletInfo!.address, to: to, value: bigValue, stepLimit: limit, message: data)

                    switch result {
                    case .success(let txHash):
                        Log.Debug("txHash: \(txHash)")

                        confirm.dismiss(animated: true, completion: {
                            Tools.toast(message: "Transfer.RequestComplete".localized)
                            self.navigationController?.popViewController(animated: true)
                        })

                    case .failure(let error):
                        Log.Debug("Error - \(error)")
                        if let loadingView = confirm.confirmButton.viewWithTag(999) {
                            loadingView.removeFromSuperview()
                        }
                        confirm.confirmButton.isEnabled = true
                        confirm.confirmButton.setTitle("Transfer.Transfer".localized, for: .normal)
                        Tools.toast(message: "Error.CommonError".localized)
                    }
                }
            }
            self.present(confirm, animated: true, completion: nil)
            
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        let symbol: String = {
            if let token = self.token {
                return token.symbol
            } else {
                return "ICX"
            }
        }()
        balanceTitle.text = "Transfer.Balance".localized + " (\(symbol))"
        
        sendTitle.text = "Transfer.TransferAmount".localized + " (\(symbol))"
        
        sendInputBox.setState(.normal)
        sendInputBox.setType(.numeric)
        sendInputBox.textField.placeholder = "Transfer.EnterAmount".localized
        sendInputBox.textField.keyboardType = .decimalPad
        
        add1.setTitle("+10", for: .normal)
        add1.corner(4)
        add2.setTitle("+100", for: .normal)
        add2.corner(4)
        add3.setTitle("+1000", for: .normal)
        add3.corner(4)
        add4.setTitle("Transfer.Max".localized, for: .normal)
        add4.corner(4)
        
        toTitle.text = "Transfer.RecvAddress".localized
        addressInputBox.setState(.normal)
        addressInputBox.setType(.address)
        addressInputBox.textField.placeholder = "Transfer.EnterAddress".localized
        addressInputBox.textField.keyboardType = .asciiCapable
        
        selectAddressButton.setTitle("Transfer.SelectAddress".localized, for: .normal)
        selectAddressButton.cornered()
        scanButton.setTitle("Transfer.QR".localized, for: .normal)
        scanButton.cornered()
        
        stepLimitTitle.text = "Transfer.Step.Limit".localized
        limitInputBox.setType(.numeric)
        limitInputBox.setState(.normal, "")
        limitInputBox.textField.placeholder = "Placeholder.StepLimit".localized
        stepPriceTitle.text = "Transfer.Step.Price".localized
        dataTitle.text = "Transfer.Data.Title".localized
        dataInputControl.cornered()
        dataInputControl.layer.border(1, UIColor.black)
        
        stepPriceLabel.text = "-"
        stepExchangedLabel.text = "- USD"
        
        inputData = nil
        
        feeTitle.text = "Transfer.TxFee".localized + " (ICX)"
        feeAmountLabel.text = "-"
        exchangedFeeLabel.text = "- USD"
        
        remainTitle.text = "Transfer.AfterBalance".localized + " (\(symbol))"
        
        sendButton.setTitle("Transfer.Transfer".localized, for: .normal)
        sendButton.styleDark()
        sendButton.isEnabled = false
        sendButton.rounded()
    }
    
    @discardableResult
    func validateBalance(_ showError: Bool = true) -> Bool {
        guard let totalBalance = self.totalBalance else { return false }
        guard let sendText = self.sendInputBox.textField.text, sendText != "", let inputValue = Tools.stringToBigUInt(inputText: sendText), let stepPrice = self.stepPrice else {
            if showError { self.sendInputBox.setState(.error, "Error.Transfer.AmountEmpty".localized) }
            return false
        }
        
        var tmpStepLimit = BigUInt(0)
        if let stepLimit = self.limitInputBox.textField.text, let limit = BigUInt(stepLimit) {
            tmpStepLimit = limit
        }
        
        if let token = self.token {
            guard let balance = WManager.tokenBalanceList[token.dependedAddress.add0xPrefix().lowercased()]?[token.contractAddress.lowercased()], let minimum = self.calculateStepPrice() else { return false }
            guard inputValue <= balance else {
                if showError { self.sendInputBox.setState(.error, "Error.Transfer.AboveMax".localized) }
                return false
            }
            
            if minimum > totalBalance {
                if showError { self.sendInputBox.setState(.error, "Error.Transfer.InsufficientFee.ICX".localized) }
                return false
            }
        } else {
            guard inputValue <= totalBalance else {
                if showError { self.sendInputBox.setState(.error, "Error.Transfer.AboveMax".localized) }
                return false
            }
            
            if inputValue + (stepPrice * tmpStepLimit) > totalBalance {
                if showError { self.sendInputBox.setState(.error, "Error.Transfer.InsufficientFee.ICX".localized) }
                return false
            }
            
            let remainValue = totalBalance - (inputValue + (stepPrice * tmpStepLimit))
            
            let wallet = WManager.loadWalletBy(info: self.walletInfo!)
            self.remainBalance.text = Tools.bigToString(value: remainValue, decimal: wallet!.decimal, wallet!.decimal, false)
            if let exchanged = Tools.balanceToExchange(remainValue, from: wallet!.type.rawValue.lowercased(), to: "usd", belowDecimal: 2, decimal: wallet!.decimal) {
                self.exchangedRemainLabel.text = exchanged.currencySeparated() + " USD"
            } else {
                self.exchangedRemainLabel.text = "- USD"
            }
        }
        
        if showError {
            guard let sendValue = self.sendInputBox.textField.text, let send = Tools.stringToBigUInt(inputText: sendValue) else {
                return false
            }
            
            var exchanged: String? = nil
            
            if let token = self.token {
                exchanged = Tools.balanceToExchange(send, from: token.symbol.lowercased(), to: "usd", belowDecimal: 2, decimal: token.decimal)
            } else {
                exchanged = Tools.balanceToExchange(send, from: "icx", to: "usd", belowDecimal: 2, decimal: 18)
            }
            
            if let exx = exchanged {
                self.sendInputBox.setState(.exchange, exx.currencySeparated() + " USD")
            } else {
                self.sendInputBox.setState(.exchange, "- USD")
            }
        }
        
        return true
    }
    
    @discardableResult
    func validateAddress(_ showError: Bool = true) -> Bool {
        guard let toAddress = self.addressInputBox.textField.text else {
            if showError { self.addressInputBox.setState(.error, "Error.InputAddress".localized) }
            return false
        }
        
        guard toAddress != "" else { return false }
        
        guard Validator.validateICXAddress(address: toAddress) || Validator.validateIRCAddress(address: toAddress) else {
            if showError { self.addressInputBox.setState(.error, "Error.Address.ICX.Invalid".localized) }
            return false
        }
        
        guard let wallet = WManager.loadWalletBy(info: self.walletInfo!), toAddress != wallet.address! else {
            if showError { self.addressInputBox.setState(.error, "Error.Transfer.SameAddress".localized) }
            return false
        }
        if showError { self.addressInputBox.setState(.normal, nil) }
        return true
    }
    
    @discardableResult
    func validateLimit(_ showError: Bool = true) -> Bool {
        var symbol = "icx"
        if let token = self.token {
            symbol = token.symbol
        }
        
        var totalBalance: BigUInt
        if let token = self.token {
            guard let balance = WManager.tokenBalanceList[token.dependedAddress]?[token.contractAddress] else { return false }
            totalBalance = balance
        } else {
            totalBalance = self.totalBalance!
        }
        guard let limitString = self.limitInputBox.textField.text , limitString != "", let limit = BigUInt(limitString) else {
            if showError { self.limitInputBox.setState(.error, "Error.Transfer.EmptyLimit".localized)}
            let limit = BigUInt(0)
            self.feeAmountLabel.text = Tools.bigToString(value: limit, decimal: 18, 18, false)
            self.exchangedFeeLabel.text = Tools.balanceToExchange(limit, from: "icx", to: "usd", belowDecimal: 2, decimal: 18)! + " USD"
            self.remainBalance.text = Tools.bigToString(value: totalBalance, decimal: 18, 18, false)
            if let exchangedRemain = Tools.balanceToExchange(totalBalance, from: symbol, to: "usd", belowDecimal: 2, decimal: 18) {
                self.exchangedRemainLabel.text = exchangedRemain + " USD"
            } else {
                self.exchangedRemainLabel.text = "- USD"
            }
            return false
        }
        
        var minLimit: Int = 0
        if let min = self.minLimit {
            minLimit = Int(min)
        }
        var maxLimit = 0
        if let max = self.maxLimit {
            maxLimit = Int(max)
        }
        
        if limit < minLimit {
            let message = String(format: "Error.Transfer.Limit.MoreThen".localized, Tools.bigToString(value: BigUInt(minLimit), decimal: 0, 0, true).currencySeparated())
            if showError { self.limitInputBox.setState(.error, message)}
            return false
        }
        
        if limit > maxLimit {
            let message = String(format: "Error.Transfer.Limit.LessThen".localized, Tools.bigToString(value: BigUInt(maxLimit), decimal: 0, 0, true).currencySeparated())
            if showError { self.limitInputBox.setState(.error, message)}
            return false
        }
        
        if showError { self.limitInputBox.setState(.normal, nil) }
        
        if let stepPrice = self.stepPrice {
            let estimated = limit * stepPrice
            self.feeAmountLabel.text = Tools.bigToString(value: estimated, decimal: 18, 18, false)
            self.exchangedFeeLabel.text = Tools.balanceToExchange(estimated, from: "icx", to: "usd", belowDecimal: 2, decimal: 18)! + " USD"
            Log.Debug("stepPrice - \(stepPrice), limit - \(limit), totalBalance - \(totalBalance), estimated - \(estimated)")
            
            if let sendText = self.sendInputBox.textField.text, sendText != "", let inputValue = Tools.stringToBigUInt(inputText: sendText) {
                if (self.token != nil ? inputValue : estimated + inputValue) > totalBalance {
                    if showError { self.sendInputBox.setState(.error, "Error.Transfer.AboveMax".localized) }
                    return false
                }
                let remain = self.token != nil ? totalBalance - inputValue : totalBalance - (estimated + inputValue)
                Log.Debug("remain 2 - \(remain)")
                self.remainBalance.text = Tools.bigToString(value: remain, decimal: 18, 18, false)
                if let exchanged = Tools.balanceToExchange(remain, from: symbol, to: "usd", belowDecimal: 2, decimal: 18) {
                    self.exchangedRemainLabel.text = exchanged + " USD"
                } else {
                    self.exchangedRemainLabel.text = "- USD"
                }
            }
        }
        
        return true
    }
    
    @discardableResult
    func validation() -> Bool {
        return self.validateBalance() && self.validateAddress() && self.validateLimit()
    }
    
    func getStepPrice() {
        DispatchQueue.global().async {
            if let stepPrice = WManager.getStepPrice() {
                DispatchQueue.main.async {
                    let powered = stepPrice * BigUInt(10).power(9)
                    let priceGloop = Tools.bigToString(value: powered, decimal: 18, 18, true)
                    let priceICX = Tools.bigToString(value: stepPrice, decimal: 18, 18, true)
                    
                    self.stepPriceLabel.text = priceICX + " ICX" + " (" + priceGloop + " Gloop)"
                    if let exchangedPrice = Tools.balanceToExchange(stepPrice, from: "icx", to: "usd", belowDecimal: 2, decimal: 18) {
                        self.stepExchangedLabel.text = exchangedPrice + " USD"
                    } else {
                        self.stepExchangedLabel.text = "- USD"
                    }
                    self.stepPrice = stepPrice
                    
                }
            }
        }
    }
    
    @discardableResult
    func calculateStepPrice() -> BigUInt? {
        guard let costs = self.costs else { return nil }
        
        guard let stepDefault = BigUInt(costs.defaultValue.prefix0xRemoved(), radix: 16) else { return nil } //, let contractCall = BigUInt(costs.contractCall.prefix0xRemoved(), radix: 16), let input = BigUInt(costs.input.prefix0xRemoved(), radix: 16) else { return nil }
        
        if self.token != nil {
            let stepLimit = 2 * stepDefault
            
            self.limitInputBox.textField.text = Tools.bigToString(value: stepLimit, decimal: 0, 0, false)
            return stepLimit
        } else {
            if let data = self.inputData {
                guard let input = BigUInt(costs.input.prefix0xRemoved(), radix: 16) else { return nil }
                let stepLimit = stepDefault + (input * BigUInt(data.bytes.count))
                
                self.limitInputBox.textField.text = Tools.bigToString(value: stepLimit, decimal: 0, 0, false)
                return stepLimit
            } else {
                guard let minimum = self.minLimit else { return nil }
                self.limitInputBox.textField.text = String(minimum)
                return minimum
            }
        }
    }
}
