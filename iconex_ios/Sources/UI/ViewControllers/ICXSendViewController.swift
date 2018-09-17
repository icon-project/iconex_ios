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

class ICXSendViewController: UIViewController {

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
    var totalBalance: BigUInt!
    var privateKey: String?
    var stepPrice: BigUInt?
    var inputData: String? {
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
    
    var inputValue: BigUInt?
    var minLimit: BigUInt?
    var maxLimit: BigUInt?
    
    var selectedDataType: Int = 0
    var dataSource: String?
    
    let disposeBag = DisposeBag()
    
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
            let costs = WManager.service.getStepCosts()
            
            switch costs {
            case .success(let costResult):
                if let cost = costResult.result {
                    let minValue = cost.defaultValue.prefix0xRemoved()
                    let min = BigUInt(minValue, radix: 16)
                    self.minLimit = min
                    let inputValue = cost.input.prefix0xRemoved()
                    self.inputValue = BigUInt(inputValue, radix: 16)
                    
                    DispatchQueue.main.async {
                        guard let minimum = min else { return }
                        self.limitInputBox.textField.text = String(minimum)
                    }
                }
                
            default:
                break
            }
            
            
            
            let minResult = WManager.service.getMinStepLimit()
            
            switch minResult {
            case .success(let minValue):
                self.minLimit = minValue
                
            default:
                break
            }
            
            let maxResult = WManager.service.getMaxStepLimit()
            
            switch maxResult {
            case .success(let maxValue):
                self.maxLimit = maxValue
                
            default:
                break
            }
        }
        
        self.getStepPrice()
        
        guard let walletInfo = self.walletInfo else {
            return
        }
        guard let wallet = WManager.loadWalletBy(info: walletInfo) else { return }
        
        topTitle.text = wallet.alias!
        
        if let balance = WManager.walletBalanceList[wallet.address!] {
            let printBalance = Tools.bigToString(value: balance, decimal: wallet.decimal, wallet.decimal, false)
            balanceLabel.text = printBalance
            
            let type = self.walletInfo!.type.rawValue
            let exchanged = Tools.balanceToExchange(balance, from: type, to: "usd")
            exchangedBalanceLabel.text = exchanged == nil ? "0.0 USD" : exchanged!.currencySeparated() + " USD"
            totalBalance = balance
            
            guard let stepPrice = self.stepPrice, let stepLimit = self.limitInputBox.textField.text, stepLimit != "" else {
                remainBalance.text = printBalance
                return
            }
            guard let limit = BigUInt(stepLimit) else { return }
            let remain = self.totalBalance - (stepPrice * limit)
            self.remainBalance.text = Tools.bigToString(value: remain, decimal: 18, 18, false)
            self.exchangedRemainLabel.text = Tools.balanceToExchange(remain, from: "icx", to: "usd", belowDecimal: 2, decimal: 18)
        }
    }
    
    func initialize() {
        topCloseButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
        
        scrollView.rx.didEndDragging.observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] _ in
            self.view.endEditing(false)
        }).disposed(by: disposeBag)
        
        sendInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.sendInputBox.setState(.focus)
        }).disposed(by: disposeBag)
        sendInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.validateBalance()
        }).disposed(by: disposeBag)
        sendInputBox.textField.rx.controlEvent(UIControlEvents.editingChanged).subscribe(onNext: { [unowned self] in
            guard let sendValue = self.sendInputBox.textField.text, let send = Tools.stringToBigUInt(inputText: sendValue), let exchanged = Tools.balanceToExchange(send, from: "icx", to: "usd", belowDecimal: 2, decimal: 18) else {
                return
            }
            self.sendInputBox.setState(.exchange, exchanged.currencySeparated() + " USD")
        }).disposed(by: disposeBag)
        
        add1.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let formerValue = Tools.stringToBigUInt(inputText: self.sendInputBox.textField.text!) else {
                    return
                }
                guard let walletInfo = self.walletInfo else { return }
                let result = formerValue + BigUInt(10).power(19)
                Log.Debug(result)
                guard let wallet = WManager.loadWalletBy(info: walletInfo) else { return }
                let stringValue = Tools.bigToString(value: result, decimal: wallet.decimal, wallet.decimal, true, false)
                self.sendInputBox.textField.text = stringValue
                self.sendInputBox.textField.becomeFirstResponder()
                self.validateBalance()
            }).disposed(by: disposeBag)
        
        add2.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let formerValue = Tools.stringToBigUInt(inputText: self.sendInputBox.textField.text!) else {
                    return
                }
                guard let walletInfo = self.walletInfo else { return }
                let result = formerValue + BigUInt(10).power(20)
                guard let wallet = WManager.loadWalletBy(info: walletInfo) else { return }
                let stringValue = Tools.bigToString(value: result, decimal: wallet.decimal, wallet.decimal, true, false)
                self.sendInputBox.textField.text = stringValue
                self.sendInputBox.textField.becomeFirstResponder()
                self.validateBalance()
            }).disposed(by: disposeBag)
        
        add3.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let formerValue = Tools.stringToBigUInt(inputText: self.sendInputBox.textField.text!) else {
                    return
                }
                guard let walletInfo = self.walletInfo else { return }
                let result = formerValue + BigUInt(10).power(21)
                guard let wallet = WManager.loadWalletBy(info: walletInfo) else { return }
                let stringValue = Tools.bigToString(value: result, decimal: wallet.decimal, wallet.decimal, true, false)
                self.sendInputBox.textField.text = stringValue
                self.sendInputBox.textField.becomeFirstResponder()
                self.validateBalance()
            }).disposed(by: disposeBag)
        
        add4.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let walletInfo = self.walletInfo else { return }
                guard let wallet = WManager.loadWalletBy(info: walletInfo) else { return }
                guard let stepPrice = self.stepPrice else { return }
                
                var tmpStepLimit = BigUInt(0)
                if let stepLimit = self.limitInputBox.textField.text, let limit = BigUInt(stepLimit) {
                    tmpStepLimit = limit
                }
                
                let sendValue = self.totalBalance - (stepPrice * tmpStepLimit)
                
                self.sendInputBox.textField.text = Tools.bigToString(value: sendValue, decimal: wallet.decimal, wallet.decimal, true, false)
                self.sendInputBox.textField.becomeFirstResponder()
                self.validateBalance()
            }).disposed(by: disposeBag)
        
        addressInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.addressInputBox.setState(.focus)
        }).disposed(by: disposeBag)
        addressInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            let validate = self.validation()
            self.sendButton.isEnabled = validate
        }).disposed(by: disposeBag)
        addressInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            let validate = self.validation()
            self.sendButton.isEnabled = validate
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
                reader.mode = .address
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
            self.validateLimit()
        }).disposed(by: disposeBag)
        limitInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            self.validation()
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
            let selectData = UIStoryboard(name: "ActionControls", bundle: nil).instantiateViewController(withIdentifier: "DataInputSourceView") as! DataInputSourceViewController
            selectData.handler = { [unowned self] selected in
                self.selectedDataType = selected
                let dataInput = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ICXDataInputView") as! ICXDataInputViewController
                dataInput.type = selected
                dataInput.handler = { [unowned self] data in
                    Log.Debug("Input data: \(data)")
                    self.dataSource = data
                }
                self.present(dataInput, animated: true, completion: nil)
            }
            selectData.present(from: self)
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
            let icxValue = Tools.bigToString(value: bigValue, decimal: 18, 18, false, true)
            
            let to = self.addressInputBox.textField.text!
            
            let confirm = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "SendConfirmView") as! SendConfirmViewController
            confirm.type = self.walletInfo!.type.rawValue
            confirm.feeType = self.walletInfo!.type.rawValue
            confirm.value = icxValue
            confirm.address = self.addressInputBox.textField.text!
            
            guard let stepPrice = self.stepPrice, let stepLimit = self.limitInputBox.textField.text, let limit = BigUInt(stepLimit) else { return }
            
            let estimatedStep = limit * stepPrice
            
            confirm.fee = Tools.bigToString(value: estimatedStep, decimal: 18, 18, false, false)
            confirm.handler = {
                
                let withdraw = Tools.convertedHexString(value: value)!
                
                let limit = "0x" + String(limit, radix: 16)
                let result = WManager.service.sendTransaction(privateKey: self.privateKey!, from: self.walletInfo!.address, to: to, value: withdraw, stepLimit: limit)
                
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
            self.present(confirm, animated: true, completion: nil)
            
        }).disposed(by: disposeBag)
        
        let observeBalance = sendInputBox.textField.rx.text
            .map { _ in
                return self.validateBalance(false)
        }
        
        let observeAddress = addressInputBox.textField.rx.text
            .map { _ in
                return self.validateAddress(false)
        }

        let observeLimit = limitInputBox.textField.rx.text
            .map { _ in
                return self.validateLimit(false)
        }
        
        Observable.combineLatest([observeBalance, observeAddress, observeLimit]) { iterator -> Bool in
            return iterator.reduce(true, { $0 && $1 })
        }.bind(to: sendButton.rx.isEnabled).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        balanceTitle.text = "Transfer.Balance".localized + " (ICX)"
        
        sendTitle.text = "Transfer.TransferAmount".localized + " (ICX)"
        
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
        
        remainTitle.text = "Transfer.AfterBalance".localized + " (ICX)"
        
        sendButton.setTitle("Transfer.Transfer".localized, for: .normal)
        sendButton.styleDark()
        sendButton.isEnabled = false
        sendButton.rounded()
    }
    
    @discardableResult
    func validateBalance(_ showError: Bool = true) -> Bool {
        guard let sendText = self.sendInputBox.textField.text, let icxValue = Tools.stringToBigUInt(inputText: sendText), icxValue != BigUInt(0), let stepPrice = self.stepPrice else {
            if showError { self.sendInputBox.setState(.error, "Error.Transfer.AmountEmpty".localized) }
            return false
        }
        
        var tmpStepLimit = BigUInt(0)
        if let stepLimit = self.limitInputBox.textField.text, let limit = BigUInt(stepLimit) {
            tmpStepLimit = limit
        }
        
        if icxValue + (stepPrice * tmpStepLimit) > self.totalBalance {
            if showError { self.sendInputBox.setState(.error, "Error.Transfer.AboveMax".localized) }
            return false
        }
        
        let sendValue = self.totalBalance - (icxValue + (stepPrice * tmpStepLimit))
        
        let wallet = WManager.loadWalletBy(info: self.walletInfo!)
        self.remainBalance.text = Tools.bigToString(value: sendValue, decimal: wallet!.decimal, wallet!.decimal, false).currencySeparated() + " ICX"
        if let exchanged = Tools.balanceToExchange(sendValue, from: wallet!.type.rawValue.lowercased(), to: "usd", belowDecimal: 2, decimal: wallet!.decimal) {
            self.exchangedRemainLabel.text = exchanged.currencySeparated() + " USD"
        }
        
        if showError {
            guard let sendValue = self.sendInputBox.textField.text, let send = Tools.stringToBigUInt(inputText: sendValue), let exchanged = Tools.balanceToExchange(send, from: "icx", to: "usd", belowDecimal: 2, decimal: 18) else {
                return false
            }
            self.sendInputBox.setState(.exchange, exchanged.currencySeparated() + " USD")
        }
        
        return true
    }
    
    @discardableResult
    func validateAddress(_ showError: Bool = true) -> Bool {
        guard let toAddress = self.addressInputBox.textField.text, toAddress != "" else {
            if showError { self.addressInputBox.setState(.error, "Error.InputAddress".localized) }
            return false
        }
        
        guard Validator.validateICXAddress(address: toAddress) else {
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
        guard let limit = self.limitInputBox.textField.text , limit != "" else {
            if showError { self.limitInputBox.setState(.error, "Error.Transfer.EmptyLimit".localized)}
            return false
        }
        
        let hexLimit = Int(limit, radix: 16)!
        var minLimit: Int = 0
        if let min = self.minLimit {
            minLimit = Int(min)
        }
        var maxLimit = 0
        if let max = self.maxLimit {
            maxLimit = Int(max)
        }
        
        if hexLimit < minLimit {
            let message = "임시: \(minLimit) 보다 높은 스텝 한도를 입력해주세요."
            if showError { self.limitInputBox.setState(.error, message)}
            return false
        }
        
        if hexLimit > maxLimit {
            let message = "임시: \(maxLimit) 보다 나은 스텝 한도를 입력해주세요."
            if showError { self.limitInputBox.setState(.error, message)}
            return false
        }
        
        if showError { self.limitInputBox.setState(.normal, nil) }
        
        if let stepLimit = self.limitInputBox.textField.text, stepLimit != "", let stepPrice = self.stepPrice {
            guard let limit = BigUInt(stepLimit) else { return false }
            let estimated = limit * stepPrice
            self.feeAmountLabel.text = Tools.bigToString(value: estimated, decimal: 18, 18, false, true)
            self.exchangedFeeLabel.text = Tools.balanceToExchange(estimated, from: "icx", to: "usd", belowDecimal: 18, decimal: 18)
            
            let remain = self.totalBalance - (stepPrice * limit)
            self.remainBalance.text = Tools.bigToString(value: remain, decimal: 18, 18, false)
            self.exchangedRemainLabel.text = Tools.balanceToExchange(remain, from: "icx", to: "usd", belowDecimal: 2, decimal: 18)
        }
        
        return true
    }
    
    @discardableResult
    func validation() -> Bool {
        return self.validateBalance() && self.validateAddress() && self.validateLimit()
    }
    
    func getStepPrice() {
        DispatchQueue.global().async {
            let result = WManager.service.getStepPrice()
            
            DispatchQueue.main.async {
                switch result {
                case .success(let stepPrice):
                    Log.Debug("step price = \(stepPrice)")
                    let powered = stepPrice * BigUInt(10).power(9)
                    let priceGloop = Tools.bigToString(value: powered, decimal: 18, 18, true, true)
                    let priceICX = Tools.bigToString(value: stepPrice, decimal: 18, 18, true, true)
                    
                    self.stepPriceLabel.text = priceICX + " ICX" + " (" + priceGloop + " Gloop)"
                    
                    if let exchangedPrice = Tools.balanceToExchange(stepPrice, from: "icx", to: "usd", belowDecimal: 2, decimal: 18) {
                        self.stepExchangedLabel.text = exchangedPrice + "USD"
                    }
                    self.stepPrice = stepPrice
                    
                case .failure(let error):
                    Log.Debug("Error - \(error)")
                }
            }
        }
    }
}
