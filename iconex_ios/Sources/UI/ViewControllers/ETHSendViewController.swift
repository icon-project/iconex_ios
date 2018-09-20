//
//  ETHSendViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import BigInt
import web3swift

class ETHSendViewController: UIViewController {
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var balanceTitle: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var balanceExchangeLabel: UILabel!
    @IBOutlet weak var sendTitle: UILabel!
    @IBOutlet weak var sendInputBox: IXInputBox!
    @IBOutlet weak var add1: UIButton!
    @IBOutlet weak var add2: UIButton!
    @IBOutlet weak var add3: UIButton!
    @IBOutlet weak var add4: UIButton!
    @IBOutlet weak var toTitle: UILabel!
    @IBOutlet weak var addressInputBox: IXInputBox!
    @IBOutlet weak var selectAddressButton: UIButton!
    @IBOutlet weak var qrButton: UIButton!
    @IBOutlet weak var gasLimitTitle: UILabel!
    @IBOutlet weak var limitInfo: UIButton!
    @IBOutlet weak var gasLimitInputBox: IXInputBox!
    @IBOutlet weak var gasTitle: UILabel!
    @IBOutlet weak var gasInfo: UIButton!
    @IBOutlet weak var gasValueLabel: UILabel!
    @IBOutlet weak var slow: UILabel!
    @IBOutlet weak var fast: UILabel!
    @IBOutlet weak var gasSlider: IXSlider!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var dataTitle: UILabel!
    @IBOutlet weak var dataInfo: UIButton!
    @IBOutlet weak var dataTitleButton: UIButton!
    @IBOutlet weak var dataInputBox: IXInputBox!
    @IBOutlet weak var dataContainerHeight: NSLayoutConstraint!
    
    @IBOutlet weak var feeTitle: UILabel!
    @IBOutlet weak var feeInfo: UIButton!
    @IBOutlet weak var feeAmountLabel: UILabel!
    @IBOutlet weak var exchangedFeeLabel: UILabel!
    
    @IBOutlet weak var remainTitle: UILabel!
    @IBOutlet weak var remainBalance: UILabel!
    @IBOutlet weak var exchangedRemainLabel: UILabel!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sendButton: UIButton!
    
    var walletInfo: WalletInfo?
    var token: TokenInfo?
    var totalBalance: BigUInt!
    var privateKey: String?
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeUI()
        initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let walletInfo = self.walletInfo else {
            return
        }
        guard let wallet = WManager.loadWalletBy(info: walletInfo) else { return }
        navTitle.text = wallet.alias!
        
        if let token = self.token {
            if let balances = WManager.tokenBalanceList[token.dependedAddress], let balance = balances[token.contractAddress] {
                Log.Debug("token balance \(balance)")
                let printBalance = Tools.bigToString(value: balance, decimal: token.decimal, token.decimal, false)
                balanceLabel.text = printBalance
                let type = token.parentType.lowercased()
                let exchanged = Tools.balanceToExchange(balance, from: type, to: "usd", decimal: token.decimal)
                balanceExchangeLabel.text = exchanged == nil ? "0.0 USD" : exchanged!.currencySeparated() + " USD"
                totalBalance = balance
                remainBalance.text = printBalance
                self.exchangedRemainLabel.text = exchanged == nil ? "0.0 USD" : exchanged!.currencySeparated() + " USD"
            }
        } else {
        
            if let balance = WManager.walletBalanceList[walletInfo.address] {
                let printBalance = Tools.bigToString(value: balance, decimal: wallet.decimal, wallet.decimal, false)
                balanceLabel.text = printBalance
                
                let type = self.walletInfo!.type.rawValue
                let exchanged = Tools.balanceToExchange(balance, from: type, to: "usd")
                balanceExchangeLabel.text = exchanged == nil ? "0.0 USD" : exchanged!.currencySeparated() + " USD"
                totalBalance = balance
                remainBalance.text = printBalance
                self.exchangedRemainLabel.text = exchanged == nil ? "0.0 USD" : exchanged!.currencySeparated() + " USD"
            }
        }
    }
    
    func initialize() {
        
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }).disposed(by: disposeBag)
        
        scrollView.rx.didEndDragging.observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] _ in
            self.view.endEditing(false)
        }).disposed(by: disposeBag)
        
        selectAddressButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            let addressManage = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "AddressManageView") as! AddressManageViewController
            addressManage.walletInfo = self.walletInfo
            addressManage.selectHandler = { (address) in
                self.addressInputBox.textField.text = address
                let _ = self.validateAddress()
                addressManage.dismiss(animated: true, completion: {
                    self.addressInputBox.textField.becomeFirstResponder()
                })
            }
            
            self.present(addressManage, animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        sendInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.sendInputBox.setState(.focus)
        }).disposed(by: disposeBag)
        sendInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.validateBalance()
            self.calculateGas()
        }).disposed(by: disposeBag)
        sendInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: {
            
        }).disposed(by: disposeBag)
        sendInputBox.textField.rx.controlEvent(UIControlEvents.editingChanged).subscribe(onNext: { [unowned self] in
            guard let sendValue = self.sendInputBox.textField.text, let send = Tools.stringToBigUInt(inputText: sendValue), let exchanged = Tools.balanceToExchange(send, from: "icx", to: "usd", belowDecimal: 2, decimal: 18) else {
                return
            }
            self.sendInputBox.setState(.exchange, exchanged.currencySeparated() + " USD")
        }).disposed(by: disposeBag)
        
        addressInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.addressInputBox.setState(.focus)
        }).disposed(by: disposeBag)
        addressInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.validateAddress()
            self.calculateGas()
        }).disposed(by: disposeBag)
        addressInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            self.gasLimitInputBox.textField.becomeFirstResponder()
        }).disposed(by: disposeBag)
        
        gasLimitInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.gasLimitInputBox.setState(.focus)
        }).disposed(by: disposeBag)
        gasLimitInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.validateEstimateGas()
        }).disposed(by: disposeBag)
        gasLimitInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: {
            
        }).disposed(by: disposeBag)
        
        dataInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.dataInputBox.setState(.focus)
        }).disposed(by: disposeBag)
        dataInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.validateData()
        }).disposed(by: disposeBag)
        dataInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: {
            
        }).disposed(by: disposeBag)
        
        let observeBalance = sendInputBox.textField.rx.text
            .map { _ in
                return self.validateBalance(false)
        }
        
        let observeAddress = addressInputBox.textField.rx.text
            .map { _ in
                return self.validateAddress(false)
        }
        
        let observeGasLimit = gasLimitInputBox.textField.rx.text
            .map { _ in
                return self.validateEstimateGas(false)
        }
        
        let observeData = dataInputBox.textField.rx.text
            .map { _ in
                return self.validateData(false)
        }
        
        Observable.combineLatest([observeBalance, observeAddress, observeGasLimit, observeData]) { iterator -> Bool in
            return iterator.reduce(true, { $0 && $1 })
            }.bind(to: sendButton.rx.isEnabled).disposed(by: disposeBag)
        
        qrButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                let reader = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "QRReaderView") as! QRReaderViewController
                reader.mode = .address
                reader.type = .eth
                reader.handler = { code in
                    self.addressInputBox.textField.text = code
                    self.addressInputBox.textField.becomeFirstResponder()
                    let _ = self.validateAddress()
                }
                
                reader.show(self)
            }).disposed(by: disposeBag)
        
        add1.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let formerValue = Tools.stringToBigUInt(inputText: self.sendInputBox.textField.text!) else {
                    return
                }
                let wallet = WManager.loadWalletBy(info: self.walletInfo!)!
                var decimal = 0
                if let token = self.token {
                    decimal = token.defaultDecimal
                } else {
                    decimal = wallet.decimal
                }
                let result = formerValue + BigUInt(10).power(decimal + 1)
                Log.Debug(result)
                let stringValue = Tools.bigToString(value: result, decimal: decimal, decimal, true, false)
                self.sendInputBox.textField.text = stringValue
                self.sendInputBox.textField.becomeFirstResponder()
                let _ = self.validateBalance()
                self.calculateGas()
            }).disposed(by: disposeBag)
        
        add2.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let formerValue = Tools.stringToBigUInt(inputText: self.sendInputBox.textField.text!) else {
                    return
                }
                var decimal = 0
                let wallet = WManager.loadWalletBy(info: self.walletInfo!)!
                if let token = self.token {
                    decimal = token.defaultDecimal
                } else {
                    decimal = wallet.decimal
                }
                let result = formerValue + BigUInt(10).power(decimal + 2)
                let stringValue = Tools.bigToString(value: result, decimal: decimal, decimal, true, false)
                self.sendInputBox.textField.text = stringValue
                self.sendInputBox.textField.becomeFirstResponder()
                let _ = self.validateBalance()
                self.calculateGas()
            }).disposed(by: disposeBag)
        
        add3.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let formerValue = Tools.stringToBigUInt(inputText: self.sendInputBox.textField.text!) else {
                    return
                }
                var decimal = 0
                let wallet = WManager.loadWalletBy(info: self.walletInfo!)!
                if let token = self.token {
                    decimal = token.defaultDecimal
                } else {
                    decimal = wallet.decimal
                }
                let result = formerValue + BigUInt(10).power(decimal + 3)
                let stringValue = Tools.bigToString(value: result, decimal: decimal, decimal, true, false)
                self.sendInputBox.textField.text = stringValue
                self.sendInputBox.textField.becomeFirstResponder()
                let _ = self.validateBalance()
                self.calculateGas()
            }).disposed(by: disposeBag)
        
        add4.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let estimate = self.estimateGas() else { return }
                
                if let token = self.token {
                    guard let balance = WManager.tokenBalanceList[token.dependedAddress]![token.contractAddress] else { return }
                    self.sendInputBox.textField.text = Tools.bigToString(value: balance, decimal: token.decimal, token.decimal, true, false)
                } else {
                    let wallet = WManager.loadWalletBy(info: self.walletInfo!)!
                    guard let formerValue = wallet.balance else { return }
                    if formerValue < estimate {
                        self.view.endEditing(true)
                        self.validateBalance(true)
                        return
                    }
                    let result = (formerValue - estimate)
                    let stringValue = Tools.bigToString(value: result, decimal: wallet.decimal, wallet.decimal, true, false)
                    self.sendInputBox.textField.text = stringValue
                }
                self.sendInputBox.textField.becomeFirstResponder()
                let _ = self.validateBalance()
                self.calculateGas()
            }).disposed(by: disposeBag)
        
        limitInfo.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            Alert.Basic(message: "Transfer.Gas.Desc_1".localized).show(self)
        }).disposed(by: disposeBag)
        gasLimitInputBox.textField.rx.controlEvent(UIControlEvents.editingChanged)
            .subscribe(onNext: { [unowned self] in
                self.calculateGas()
                let _ = self.validateBalance()
            }).disposed(by: disposeBag)
        gasInfo.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            Alert.Basic(message: "Transfer.Gas.Desc_2".localized).show(self)
        }).disposed(by: disposeBag)
        
        minusButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                self.gasSlider.value -= 1
                self.gasValueLabel.text = "\(Int(self.gasSlider.value))" + " Gwei"
                self.calculateGas()
            }).disposed(by: disposeBag)
        
        plusButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                self.gasSlider.value += 1
                self.gasValueLabel.text = "\(Int(self.gasSlider.value))" + " Gwei"
                self.calculateGas()
            }).disposed(by: disposeBag)
        
        dataInfo.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            Alert.Basic(message: "Transfer.Gas.Desc_4".localized).show(self)
        }).disposed(by: disposeBag)
        dataTitleButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                let height = self.dataTitleButton.frame.height + (self.dataTitleButton.frame.origin.y * 2)
                if self.dataContainerHeight.constant == height {
                    self.dataContainerHeight.constant = 136
                    UIView.animate(withDuration: 0.25, animations: {
                        self.view.layoutIfNeeded()
                    })
                } else {
                    self.dataContainerHeight.constant = height
                    UIView.animate(withDuration: 0.25, animations: {
                        self.view.layoutIfNeeded()
                    })
                }
            }).disposed(by: disposeBag)
        
        gasSlider.rx.value.subscribe(onNext: { [unowned self] (value) in
            self.gasValueLabel.text = "\(Int(value))" + " Gwei"
            self.calculateGas()
        }).disposed(by: disposeBag)
        
        feeInfo.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            Alert.Basic(message: "Transfer.Gas.Desc_3".localized).show(self)
        }).disposed(by: disposeBag)
        
        keyboardHeight().observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] (height) in
            self.bottomConstraint.constant = height == 0 ? height + 72 : height
        }).disposed(by: disposeBag)
        
        sendButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                self.sendTransaction()
            }).disposed(by: disposeBag)
        
    }
    
    func initializeUI() {
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
        addressInputBox.textField.returnKeyType = .next
        
        selectAddressButton.setTitle("Transfer.SelectAddress".localized, for: .normal)
        selectAddressButton.corner(4)
        qrButton.setTitle("Transfer.QR".localized, for: .normal)
        qrButton.corner(4)
        
        gasLimitTitle.text = "Transfer.GasLimit".localized
        gasLimitInputBox.textField.placeholder = "Transfer.EnterGasLimit".localized
        gasLimitInputBox.setState(.normal, nil)
        gasLimitInputBox.setType(.integer)
        
        gasTitle.text = "Transfer.GasPrice".localized
        slow.text = "Transfer.Slow".localized
        fast.text = "Transfer.Fast".localized
        gasSlider.minimumValue = 1
        gasSlider.maximumValue = 99
        
        if let minimumImage = UIImage(color: UIColor.lightTheme.background.normal, width: 1, height: 10) {
            gasSlider.setMinimumTrackImage(minimumImage, for: .normal)
        }
        if let maximumImage = UIImage(color: UIColor.lightTheme.background.disabled, width: 1, height: 10) {
            gasSlider.setMaximumTrackImage(maximumImage, for: .normal)
        }
        if let thumbImage = UIImage(backgroundColor: UIColor.white, size: CGSize(width: 32, height: 32), borderColor: UIColor.lightTheme.background.normal, borderWidth: 2) {
            gasSlider.setThumbImage(thumbImage, for: .normal)
        }
        
        minusButton.styleDark()
        minusButton.cornered()
        plusButton.styleDark()
        plusButton.cornered()
        
        dataTitle.text = "Transfer.Data".localized
        dataInputBox.setType(.normal)
        dataInputBox.setState(.normal, nil)
        
        if let token = self.token {
            balanceTitle.text = "Transfer.Balance".localized + " (" + token.symbol.uppercased() + ")"
            sendTitle.text = "Transfer.TransferAmount".localized + " (" + token.symbol.uppercased() + ")"
            remainTitle.text = "Transfer.EstimatedBalance".localized + " (" + token.symbol.uppercased() + ")"
        } else {
            balanceTitle.text = "Transfer.Balance".localized + " (ETH)"
            sendTitle.text = "Transfer.TransferAmount".localized + " (ETH)"
            remainTitle.text = "Transfer.EstimatedBalance".localized + " (ETH)"
        }
        
        feeTitle.text = "Transfer.EstimatedFee".localized + " (ETH)"
        
        feeAmountLabel.text = ""
        
        
        sendButton.setTitle("Transfer.Transfer".localized, for: .normal)
        sendButton.styleDark()
        sendButton.isEnabled = false
        sendButton.rounded()
        
        dataContainerHeight.constant = self.dataTitleButton.frame.height + (self.dataTitleButton.frame.origin.y * 2)
        
        if let _ = self.token {
            gasLimitInputBox.textField.text = "55000"
            gasValueLabel.text = "21 Gwei"
            gasSlider.value = 21
        } else {
            gasLimitInputBox.textField.text = "21000"
            gasValueLabel.text = "21 Gwei"
            gasSlider.value = 21
        }
        
    }
    
    @discardableResult
    func validateBalance(_ showError: Bool = true) -> Bool {
        guard let sendText = self.sendInputBox.textField.text , let feeValue = estimateGas(), sendText != "" else {
            if showError {
                self.sendInputBox.setState(.error, "Error.Transfer.AmountEmpty".localized)
            }
            return false
        }
        
        if let token = self.token {
            guard let inputValue = Tools.stringToBigUInt(inputText: sendText, decimal: token.decimal) else {
                if showError { self.sendInputBox.setState(.error, "Error.Transfer.AmountEmpty".localized) }
                return false
            }
            
            guard inputValue <= self.totalBalance else {
                if showError { self.sendInputBox.setState(.error, "Error.Transfer.AboveMax".localized) }
                return false
            }
            if showError {
                guard let sendValue = self.sendInputBox.textField.text, let send = Tools.stringToBigUInt(inputText: sendValue), let exchanged = Tools.balanceToExchange(send, from: "icx", to: "usd", belowDecimal: 2, decimal: 18) else {
                    return false
                }
                self.sendInputBox.setState(.exchange, exchanged.currencySeparated() + " USD")
            }
            return true
        } else {
            let ethValue = Tools.stringToBigUInt(inputText: sendText)!
            
            let wallet = WManager.loadWalletBy(info: self.walletInfo!)
            
            guard ethValue <= self.totalBalance else {
                if showError { self.sendInputBox.setState(.error, "Error.Transfer.AboveMax".localized) }
                return false
            }
            
            if ethValue + feeValue > self.totalBalance {
                let message = "Error.Transfer.InsufficientFee.ETH".localized
                
                if showError { self.sendInputBox.setState(.error, message.localized) }
                return false
            } else if ethValue == BigUInt(0) {
                if showError { self.sendInputBox.setState(.error, "Error.Transfer.AmountEmpty".localized) }
                return false
            }
            
            let remain = self.totalBalance - (ethValue + feeValue)
            self.remainBalance.text = Tools.bigToString(value: remain, decimal: wallet!.decimal, wallet!.decimal, true)
            if let excRemain = Tools.balanceToExchange(remain, from: "eth", to: "usd") {
                self.exchangedRemainLabel.text = excRemain.currencySeparated() + " USD"
            }
            if showError {
                guard let sendValue = self.sendInputBox.textField.text, let send = Tools.stringToBigUInt(inputText: sendValue), let exchanged = Tools.balanceToExchange(send, from: "icx", to: "usd", belowDecimal: 2, decimal: 18) else {
                    return false
                }
                self.sendInputBox.setState(.exchange, exchanged.currencySeparated() + " USD")
            }
            return true
        }
    }
    
    @discardableResult
    func validateAddress(_ showError: Bool = true) -> Bool {
        guard let toAddress = self.addressInputBox.textField.text, toAddress != "" else {
            if showError { self.addressInputBox.setState(.error, "Error.InputAddress".localized) }
            return false
        }
        guard Validator.validateETHAddress(address: toAddress) else {
            if showError { self.addressInputBox.setState(.error, "Error.Address".localized) }
            return false
        }
        
        guard let wallet = WManager.loadWalletBy(info: self.walletInfo!), toAddress != wallet.address! else {
            if showError { self.addressInputBox.setState(.error, "Error.Transfer.SameAddress".localized) }
            return false
        }
        
        if showError { self.addressInputBox.setState(.normal, "") }
        return true
    }
    
    @discardableResult
    func validateEstimateGas(_ showError: Bool = true) -> Bool {
        guard let feeValue = estimateGas() else {
            if showError { self.gasLimitInputBox.setState(.error, "Error.Transfer.InsufficientFee.ETH".localized) }
            return false
        }
        guard let inputGas = self.gasLimitInputBox.textField.text, inputGas != "" else {
            if showError { self.gasLimitInputBox.setState(.error, "Error.Transfer.InputGasLimit".localized) }
            return false
        }
        
        let wallet = WManager.loadWalletBy(info: self.walletInfo!)!
        guard let balance = wallet.balance, balance != BigUInt(0) else {
            if showError { self.gasLimitInputBox.setState(.error, "Error.Transfer.InsufficientFee.ETH".localized) }
            return false
        }
        if let _ = self.token {
            guard feeValue < balance else {
                if showError { self.gasLimitInputBox.setState(.error, "Error.Transfer.InsufficientFee.ETH".localized) }
                return false
            }
        } else {
            
        }
        
        if showError { self.gasLimitInputBox.setState(.normal, nil) }
        return true
    }
    
    @discardableResult
    func validateData(_ showError: Bool = true) -> Bool {
        guard let dataText = dataInputBox.textField.text, dataText != "" else {
            dataInputBox.setState(.normal, "")
            return true
        }
        
        let set = CharacterSet(charactersIn: "0123456789ABCDEF").inverted
        
        guard dataText.prefix0xRemoved().uppercased().rangeOfCharacter(from: set) == nil else {
            if showError { dataInputBox.setState(.error, "Error.InputData".localized) }
            
            return false
        }
        if showError { dataInputBox.setState(.normal, "") }
        
        return true
    }
    
    func validation() {
        validateBalance()
        validateAddress()
        validateData()
        validateEstimateGas()
        calculateGas()
    }
    
    func gasPrice() -> BigUInt? {
        guard let gasValue = Web3.Utils.parseToBigUInt("\(Int(self.gasSlider.value))", units: .Gwei) else { return nil }
        
        return gasValue
    }
    
    func gasLimit() -> BigUInt? {
        guard let gasLimitValue = BigUInt(self.gasLimitInputBox.textField.text!) else { return nil }
        
        return gasLimitValue
    }
    
    func estimateGas() -> BigUInt? {
        guard let gasValue = gasPrice() else { return nil }
        guard let gasLimitValue = gasLimit() else { return nil }
        
        let estimate = gasValue * gasLimitValue
        
        return estimate
    }
    
    func calculateGas() {
        guard let gwei = estimateGas() else {
            return
        }
        let wallet = WManager.loadWalletBy(info: self.walletInfo!)!
        self.feeAmountLabel.text = Tools.bigToString(value: gwei, decimal: wallet.decimal, wallet.decimal, true)
        if let exchangeFee = Tools.balanceToExchange(gwei, from: "eth", to: "usd") {
            self.exchangedFeeLabel.text = exchangeFee.currencySeparated() + " USD"
        } else {
            self.exchangedFeeLabel.text = "-"
        }
    }
    
    func sendTransaction() {
        
        guard let gas = gasPrice() else { return }
        guard let limit = gasLimit() else { return }
        
        guard let value = Tools.stringToBigUInt(inputText: sendInputBox.textField.text!) else { return }
        let estimateGas = Tools.bigToString(value: gas * limit, decimal: 18, 18, true)
        guard let toAddress = addressInputBox.textField.text else {
            return
        }
        
        let confirm = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "SendConfirmView") as! SendConfirmViewController
        if let token = self.token {
            confirm.type = token.symbol
        } else {
            confirm.type = self.walletInfo!.type.rawValue
        }
        confirm.feeType = "ETH"
        
        let ethValue = Tools.stringToBigUInt(inputText: sendInputBox.textField.text!)!
        
        confirm.value = Tools.bigToString(value: ethValue, decimal: 18, 18, false, true)
        confirm.address = self.addressInputBox.textField.text!
        confirm.fee = estimateGas
        confirm.handler = { [unowned self] in
            
            if let token = self.token {
                Ethereum.requestTokenSendTransaction(privateKey: self.privateKey!, from: self.walletInfo!.address, to: toAddress, tokenInfo: token, limit: limit, price: gas, value: value, completion: { isCompleted in
                    
                    if isCompleted {
                        confirm.dismiss(animated: true, completion: {
                            Tools.toast(message: "Transfer.RequestComplete".localized)
                            self.navigationController?.popViewController(animated: true)
                        })
                    } else {
                        if let loadingView = confirm.confirmButton.viewWithTag(999) {
                            loadingView.removeFromSuperview()
                        }
                        confirm.confirmButton.isEnabled = true
                        confirm.confirmButton.setTitle("Transfer.Transfer".localized, for: .normal)
                        Tools.toast(message: "Error.CommonError".localized)
                    }
                })
            } else {
                var data = Data()
                let dataString = self.dataInputBox.textField.text!
                if let converted = dataString.hexToData() {
                    data = converted
                }
                
                Ethereum.requestSendTransaction(privateKey: self.privateKey!, gasPrice: gas, gasLimit: limit, from: self.walletInfo!.address, to: toAddress, value: value, data: data, completion: { (isSuccess, reason) in
                    
                    if isSuccess {
                        confirm.dismiss(animated: true, completion: {
                            Tools.toast(message: "Transfer.RequestComplete".localized)
                            self.navigationController?.popViewController(animated: true)
                        })
                    } else {
                        if let loadingView = confirm.confirmButton.viewWithTag(999) {
                            loadingView.removeFromSuperview()
                        }
                        confirm.confirmButton.isEnabled = true
                        confirm.confirmButton.setTitle("Transfer.Transfer".localized, for: .normal)
                        if reason == -1 {
                            confirm.dismiss(animated: true, completion: {
                                Alert.Basic(message: "Error.Transfer.InsufficientFee.ETH".localized).show(self)
                            })
                            
                        } else {
                            Tools.toast(message: "Error.CommonError".localized)
                        }
                    }
                    
                })
            }
        }
        self.present(confirm, animated: true, completion: nil)
        
        
    }
}

class IXSlider: UISlider {
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let custom = CGRect(origin: bounds.origin, size: CGSize(width: bounds.width, height: 10))
        super.trackRect(forBounds: custom)
        return custom
    }
}
