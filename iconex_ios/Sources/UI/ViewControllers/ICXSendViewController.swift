//
//  ICXSendViewController.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import BigInt
import Alamofire

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
    @IBOutlet weak var stepUnitLabel: UILabel!
    @IBOutlet weak var stepExchangedLabel: UILabel!
    
    @IBOutlet weak var dataTitle: UILabel!
    @IBOutlet weak var dataInfo: UIButton!
    @IBOutlet weak var dataInputControl: UIButton!
    
    
    @IBOutlet weak var feeTitle: UILabel!
    @IBOutlet weak var feeAmountLabel: UILabel!
    @IBOutlet weak var exchangedFeeLabel: UILabel!
    
    @IBOutlet weak var remainTitle: UILabel!
    @IBOutlet weak var remainBalance: UILabel!
    @IBOutlet weak var exchangedRemainLabel: UILabel!
    
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var stackViewHeight: NSLayoutConstraint!
    
    var walletInfo: WalletInfo?
    var totalBalance: BigUInt!
    var privateKey: String?
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
            
            guard let sendText = self.sendInputBox.textField.text, let feeValue = Tools.stringToBigUInt(inputText: "0.01"), let icxValue = Tools.stringToBigUInt(inputText: sendText) else {
                remainBalance.text = printBalance
                return
            }
            self.remainBalance.text = Tools.bigToString(value: self.totalBalance - (icxValue + feeValue), decimal: 18, 18, false)
            self.exchangedRemainLabel.text = Tools.balanceToExchange(self.totalBalance - (icxValue + feeValue), from: "icx", to: "usd", belowDecimal: 2, decimal: 18)
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
            if self.validateBalance() {
                
            }
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
                guard let formerValue = wallet.balance else { return }
                guard let feeValue = Tools.stringToBigUInt(inputText: "0.01") else { return }
                
                self.sendInputBox.textField.text = Tools.bigToString(value: formerValue - feeValue, decimal: wallet.decimal, wallet.decimal, true, false)
                self.sendInputBox.textField.becomeFirstResponder()
                self.validateBalance()
            }).disposed(by: disposeBag)
        
        addressInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.addressInputBox.setState(.focus)
        }).disposed(by: disposeBag)
        addressInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.validateAddress()
        }).disposed(by: disposeBag)
        addressInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            self.validation()
        }).disposed(by: disposeBag)
        
        selectAddressButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            let addressManage = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "AddressManageView") as! AddressManageViewController
            addressManage.walletInfo = self.walletInfo
            addressManage.selectHandler = { (address) in
                self.addressInputBox.textField.text = address
                self.validateAddress()
                addressManage.dismiss(animated: true, completion: {
                    self.addressInputBox.textField.becomeFirstResponder()
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
        
        limitInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.limitInputBox.setState(.focus)
        }).disposed(by: disposeBag)
        limitInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.validateLimit()
        }).disposed(by: disposeBag)
        limitInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            self.validation()
        }).disposed(by: disposeBag)
        
        dataInputControl.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.inputData = self.inputData == nil ? "dd" : nil
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
            confirm.fee = "0.01"
            confirm.handler = {
                
                let withdraw = Tools.convertedHexString(value: value)!
                
                let transaction = ICON.V2.SendTransactionRequest(id: getID(), from: self.walletInfo!.address, to: to, value: withdraw, nonce: "8367273", hexPrivateKey: self.privateKey!)
                
                self.sendInputBox.textField.text = nil
                self.addressInputBox.textField.text = nil
                
                do {
                    try Transaction.saveTransaction(from: self.walletInfo!.address, to: to, txHash: transaction.txHash!, value: value, type: "icx")
                } catch {
                    Log.Debug("\(error)")
                }
                
                Alamofire.request(transaction).responseJSON(completionHandler: { [unowned self] (response) in
                    Log.Debug(response.value)
                    
                    switch response.result {
                    case .success:
                        confirm.dismiss(animated: true, completion: {
                            Tools.toast(message: "Transfer.RequestComplete".localized)
                            self.navigationController?.popViewController(animated: true)
                        })
                        break
                        
                    case .failure(let error):
                        Log.Debug("\(error)")
                        if let loadingView = confirm.cancelButton.viewWithTag(999) {
                            loadingView.removeFromSuperview()
                        }
                        confirm.cancelButton.isEnabled = true
                        confirm.confirmButton.setTitle("Transfer.Transfer".localized, for: .normal)
                        Alert.Basic(message: error.localizedDescription).show(self)
                        return
                    }
                })
                
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
/*
        let observeLimit = limitInputBox.textField.rx.text
            .map { _ in
                return self.validateLimit(false)
        }
 */
        
        Observable.combineLatest([observeBalance, observeAddress/*, observeLimit*/]) { iterator -> Bool in
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
        feeAmountLabel.text = "0.01"
        if let fee = Tools.stringToBigUInt(inputText: "0.01") {
            exchangedFeeLabel.text = (Tools.balanceToExchange(fee, from: "icx", to: "usd", belowDecimal: 2)?.currencySeparated() ?? "-") + " USD"
        }
//        feeAmountLabel.text = "-"
//        exchangedFeeLabel.text = "- USD"
        
        remainTitle.text = "Transfer.AfterBalance".localized + " (ICX)"
        
        sendButton.setTitle("Transfer.Transfer".localized, for: .normal)
        sendButton.styleDark()
        sendButton.isEnabled = false
        sendButton.rounded()
        
        stackViewHeight.constant = 0
        stepStack.isHidden = true
        
    }
    
    @discardableResult
    func validateBalance(_ showError: Bool = true) -> Bool {
        guard let sendText = self.sendInputBox.textField.text, let icxValue = Tools.stringToBigUInt(inputText: sendText), let feeValue = Tools.stringToBigUInt(inputText: "0.01"), icxValue != BigUInt(0), sendText != "" else {
            if showError { self.sendInputBox.setState(.error, "Error.Transfer.AmountEmpty".localized) }
            return false
        }
        
        if icxValue + feeValue > self.totalBalance {
            if showError { self.sendInputBox.setState(.error, "Error.Transfer.AboveMax".localized) }
            return false
        }
        
        let wallet = WManager.loadWalletBy(info: self.walletInfo!)
        self.remainBalance.text = Tools.bigToString(value: self.totalBalance - (icxValue + feeValue), decimal: wallet!.decimal, wallet!.decimal, false).currencySeparated() + " ICX"
        if let exchanged = Tools.balanceToExchange(self.totalBalance - (icxValue + feeValue), from: wallet!.type.rawValue.lowercased(), to: "usd", belowDecimal: 2, decimal: wallet!.decimal) {
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
        if showError { self.limitInputBox.setState(.normal, nil) }
        
        return true
    }
    
    func validation() {
        self.validateBalance()
        self.validateAddress()
//        self.validateLimit()
    }
    
}
