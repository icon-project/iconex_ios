//
//  ConnectSendViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 14/11/2018.
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import ICONKit
import BigInt
import Toast_Swift

class ConnectSendViewController: BaseViewController {
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var developer: UIView!
    @IBOutlet weak var amountTitle: UILabel!
    @IBOutlet weak var amount: UILabel!
    @IBOutlet weak var exchangeAmount: UILabel!
    @IBOutlet weak var toTitle: UILabel!
    @IBOutlet weak var to: UILabel!
    @IBOutlet weak var stepLimit: UILabel!
    @IBOutlet weak var stepLimitInputBox: IXInputBox!
    @IBOutlet weak var stepPriceTitle: UILabel!
    @IBOutlet weak var stepPriceLabel: UILabel!
    @IBOutlet weak var stepPriceGloop: UILabel!
    @IBOutlet weak var exchangeStepPrice: UILabel!
    @IBOutlet weak var estimatedFeeTitle: UILabel!
    @IBOutlet weak var estimatedFee: UILabel!
    @IBOutlet weak var exchangeEstimatedFee: UILabel!
    @IBOutlet weak var remainTitle: UILabel!
    @IBOutlet weak var remain: UILabel!
    @IBOutlet weak var exchangeRemain: UILabel!
    @IBOutlet weak var data: UIView!
    @IBOutlet weak var viewLabel: UILabel!
    @IBOutlet weak var viewData: UIButton!
    @IBOutlet weak var viewImage: UIImageView!
    @IBOutlet weak var dataView: UIView!
    @IBOutlet weak var dataViewHeight: NSLayoutConstraint!
    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    
    private var costs: Response.StepCosts?
    private var maxLimit: BigUInt?
    private var stepPrice: BigUInt?
    
    var privateKey: PrivateKey?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeUI()
        initialize()
    }
    
    func initialize() {
        closeButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: {
            Alert.Confirm(message: "Alert.Connect.Send.Cancel".localized, handler: {
                Conn.sendError(error: ConnectError.userCancel)
            }).show(self)
        }).disposed(by: disposeBag)
        
        stepLimitInputBox.textField.rx.controlEvent(UIControl.Event.editingDidBegin).subscribe(onNext: {
            self.stepLimitInputBox.setState(.focus)
        }).disposed(by: disposeBag)
        stepLimitInputBox.textField.rx.controlEvent(UIControl.Event.editingDidEnd).subscribe(onNext: {
            self.sendButton.isEnabled = self.validateLimit()
            self.stepLimitInputBox.textField.resignFirstResponder()
        }).disposed(by: disposeBag)
        stepLimitInputBox.textField.rx.controlEvent(UIControl.Event.editingDidEndOnExit).subscribe(onNext: { }).disposed(by: disposeBag)
        
        scrollView.rx.didEndScrollingAnimation.subscribe(onNext: {
            self.view.endEditing(true)
        }).disposed(by: disposeBag)
        
        viewData.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: {
            self.viewImage.isHighlighted = !self.viewImage.isHighlighted
            self.dataView.isHidden = !self.viewImage.isHighlighted
            
            if self.viewImage.isHighlighted {
                let text = self.dataLabel.text!
                let lf = text.enumerated().filter({ $0.element == "\n" })
                let size = text.boundingRect(size: CGSize(width: self.dataLabel.frame.width, height: .greatestFiniteMagnitude), font: self.dataLabel.font)
                self.dataViewHeight.constant = size.height + 14.0 * CGFloat(lf.count)
                self.view.layoutIfNeeded()
                self.scrollView.setContentOffset(CGPoint(x: 0, y: self.scrollView.contentSize.height - self.scrollView.bounds.height + self.scrollView.contentInset.bottom), animated: true)
            } else {
                self.dataViewHeight.constant = 0
            }
        }).disposed(by: disposeBag)
        
        sendButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: {
            guard let received = Conn.received else { return }
            guard let from = received.params?["from"] as? String else { return }
            guard let to = received.params?["to"] as? String else { return }
            guard let valueString = received.params?["value"] as? String, let value = BigUInt(valueString.prefix0xRemoved(), radix: 16), let stepPrice = self.stepPrice else { return }
            guard let key = self.privateKey else { return }
            
            guard let balance = Balance.walletBalanceList[from] else { return }
            guard let limit = BigUInt(self.stepLimitInputBox.textField.text!.prefix0xRemoved()) else { return }
            
            let estimated = stepPrice * limit
            
            if value + estimated > balance {
                Tools.toast(message: "Error.Connect.Send.InsufficientFee".localized)
                return
            }
            
            let confirm = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "SendConfirmView") as! SendConfirmViewController
            confirm.feeType = "icx"
            confirm.fee = Tools.bigToString(value: estimated, decimal: 18, 18, false)
            confirm.address = to
            
            let transaction = Transaction()
            transaction
                .from(from)
                .nid(WManager.service.nid)
                .nonce("0x1")
                .stepLimit(estimated)
            
            if received.method == "sendICX" {
                transaction
                    .value(value)
                    .to(to)
                
                confirm.value = Tools.bigToString(value: value, decimal: 18, 18, false).currencySeparated()
                confirm.type = "icx"
                confirm.handler = {
                    
                    if let signed = try? SignedTransaction(transaction: transaction, privateKey: key) {
                        let result = WManager.service.sendTransaction(signedTransaction: signed).execute()
                        confirm.dismiss(animated: true, completion: {
                            if let error = result.error {
                                Log.Debug("Error - \(error)")
                                Tools.toast(message: "Error.CommonError".localized)
                            } else if let hash = result.value {
                                let complete = Alert.Basic(message: "Alert.Connect.Send.Completed".localized)
                                complete.handler = {
                                    Conn.sendICXHash(txHash: hash)
                                }
                                complete.show(self)
                            }
                        })
                        
                    } else {
                        Conn.sendError(error: ConnectError.sign)
                    }
                }
            } else if received.method == "sendToken" {
                guard let contract = received.params?["contractAddress"] as? String else { return }
                
                transaction.to(contract)
                transaction.dataType = "call"
                transaction.data = ["method": "transfer", "params": ["_to": to, "_value": "0x" + String(value, radix: 16)]]
//                .call("transfer")
//                .params(["_to": to, "_value": "0x" + String(value, radix: 16)])
                
                guard let decimals = Conn.tokenDecimal else { return }
                
                confirm.value = Tools.bigToString(value: value, decimal: decimals, decimals, false).currencySeparated()
                confirm.type = Conn.tokenSymbol!.uppercased()
                
                confirm.handler = {
                    
                    if let signed = try? SignedTransaction(transaction: transaction, privateKey: key) {
                        let result = WManager.service.sendTransaction(signedTransaction: signed).execute()
                        confirm.dismiss(animated: true, completion: {
                            if let error = result.error {
                                Log.Debug("Error - \(error)")
                                var msg = ""
                                switch error {
                                case .error(error: let error):
                                        msg = "\n" + error.localizedDescription
                                    
                                default:
                                    break
                                }
                                
                                Tools.toast(message: "Error.CommonError".localized + msg)
                            } else if let hash = result.value {
                                let complete = Alert.Basic(message: "Alert.Connect.Send.Completed".localized)
                                complete.handler = {
                                    Conn.sendTokenHash(txHash: hash)
                                }
                                complete.show(self)
                            }
                        })
                        
                    } else {
                        Conn.sendError(error: ConnectError.sign)
                    }
                }
            }
            
            
            
            confirm.show(self)
            
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        
        guard let from = Conn.received?.params?["from"] as? String, let wallet = WManager.loadWalletBy(address: from, type: .icx) as? ICXWallet else { return }
        
        navTitle.text = wallet.alias
        
        developer.isHidden = true
        amountTitle.text = "Connect.Send.Amount".localized + (Conn.tokenSymbol != nil ? " (\(Conn.tokenSymbol!))" : " (ICX)")
        amount.text = "-"
        exchangeAmount.text = "- USD"
        toTitle.text = "Connect.Send.to".localized
        to.text = Conn.received?.params?["to"] as? String
        stepLimit.text = "Connect.Send.StepLimit".localized
        stepLimitInputBox.textField.placeholder = "Placeholder.StepLimit".localized
        stepLimitInputBox.setType(.integer)
        stepLimitInputBox.setState(.normal)
        stepPriceTitle.text = "Connect.Send.StepPrice".localized
        stepPriceLabel.text = "-"
        stepPriceGloop.text = "ICX (- Gloop)"
        exchangeStepPrice.text = "- USD"
        
        estimatedFeeTitle.text = "Connect.Send.EstimatedFee".localized + " (ICX)"
        estimatedFee.text = "-"
        exchangeEstimatedFee.text = "- USD"
        remainTitle.text = "Connect.Send.EstimatedRemain".localized
        remain.text = "-"
        exchangeRemain.text = "- USD"
        viewLabel.text = "Transfer.Data.View".localized
        
        sendButton.setTitle("Transfer.Transfer".localized, for: .normal)
        sendButton.styleDark()
        sendButton.rounded()
        sendButton.isEnabled = false
        
        dataView.isHidden = true
        dataViewHeight.constant = 0
        
        guard let dataType = Conn.received?.params?["dataType"] as? String, let data = Conn.received?.params?["data"] else {
            self.data.isHidden = true
            return }
        
        self.data.isHidden = false
        
        var dic = [String: Any]()
        dic["dataType"] = dataType
        dic["data"] = data
        
        guard let dicData = try? JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted), let dataString = String(data: dicData, encoding: .utf8) else { return }
        
        dataLabel.text = dataString
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getStepPrice()
        
        DispatchQueue.global(qos: .utility).async {
            if let cost = WManager.getStepCosts() {
                self.costs = cost
            }
            
            if let maxLimit = WManager.getMaxStepLimit() {
                self.maxLimit = maxLimit
            }
            
            DispatchQueue.main.async {
                self.setting()
                self.calculateStepLimit()
                self.sendButton.isEnabled = self.validateLimit()
            }
        }
    }
    
    func setting() {
        guard let valueString = Conn.received?.params?["value"] as? String, let value = BigUInt(valueString.prefix0xRemoved(), radix: 16) else { return }
        
        if let decimal = Conn.tokenDecimal, let symbol = Conn.tokenSymbol {
            amount.text = Tools.bigToString(value: value, decimal: decimal, decimal, false).currencySeparated()
            if let exchange = Tools.balanceToExchange(value, from: symbol.lowercased(), to: "usd", belowDecimal: 2, decimal: decimal) {
                exchangeAmount.text = exchange + " USD"
            } else {
                exchangeAmount.text = "- USD"
            }
        } else {
            amount.text = Tools.bigToString(value: value, decimal: 18, 18, false).currencySeparated()
            if let exchange = Tools.balanceToExchange(value, from: "icx", to: "usd", belowDecimal: 2, decimal: 18) {
                exchangeAmount.text = exchange + " USD"
            } else {
                exchangeAmount.text = "- USD"
            }
        }
        
        guard let data = Conn.received?.params?["data"], let dataType = Conn.received?.params?["dataType"] else { return }
        let dic: [String: Any] = ["dataType": dataType, "data": data]
        guard let json = try? JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted), let jsonString = String(data: json, encoding: .utf8) else { return }
        dataLabel.text = jsonString
    }
    
    func getStepPrice() {
        DispatchQueue.global().async {
            if let stepPrice = WManager.getStepPrice() {
                DispatchQueue.main.async {
                    let powered = stepPrice * BigUInt(10).power(9)
                    let priceGloop = Tools.bigToString(value: powered, decimal: 18, 18, true).currencySeparated()
                    let priceICX = Tools.bigToString(value: stepPrice, decimal: 18, 18, true).currencySeparated()
                    
                    self.stepPriceLabel.text = priceICX
                    self.stepPriceGloop.text = " ICX" + " (" + priceGloop + " Gloop)"
                    if let exchangedPrice = Tools.balanceToExchange(stepPrice, from: "icx", to: "usd", belowDecimal: 2, decimal: 18) {
                        self.exchangeStepPrice.text = exchangedPrice + " USD"
                    } else {
                        self.exchangeStepPrice.text = "- USD"
                    }
                    self.stepPrice = stepPrice
                    
                }
            }
        }
    }
    
    @discardableResult
    func validateLimit(_ showError: Bool = true) -> Bool {
        guard let from = Conn.received?.params?["from"] as? String else { return false }
//        guard let wallet = WManager.loadWalletBy(address: from, type: .icx) else { return false }
        var symbol = "icx"
        if let tokenSymbol = Conn.tokenSymbol {
            symbol = tokenSymbol
        }
        
        var totalBalance: BigUInt
        if let contractAddress = Conn.received?.params?["contractAddress"] as? String {
            guard let balance = Balance.tokenBalanceList[from]?[contractAddress] else { return false }
            totalBalance = balance
        } else {
            guard let balance = Balance.walletBalanceList[from] else { return false }
            totalBalance = balance
        }
        guard let limitString = self.stepLimitInputBox.textField.text , limitString != "", let limit = BigUInt(limitString) else {
            if showError { self.stepLimitInputBox.setState(.error, "Error.Transfer.EmptyLimit".localized)}
            let limit = BigUInt(0)
            self.estimatedFee.text = Tools.bigToString(value: limit, decimal: 18, 18, false).currencySeparated()
            self.exchangeEstimatedFee.text = Tools.balanceToExchange(limit, from: "icx", to: "usd", belowDecimal: 2, decimal: 18)! + " USD"
            self.remain.text = Tools.bigToString(value: totalBalance, decimal: 18, 18, false).currencySeparated()
            if let exchangedRemain = Tools.balanceToExchange(totalBalance, from: symbol, to: "usd", belowDecimal: 2, decimal: 18) {
                self.exchangeRemain.text = exchangedRemain + " USD"
            } else {
                self.exchangeRemain.text = "- USD"
            }
            return false
        }
        
        var minLimit: Int = 0
        if let cost = self.costs, let min = BigUInt(cost.defaultValue.prefix0xRemoved(), radix: 16) {
            minLimit = Int(min)
        }
        var maxLimit = 0
        if let max = self.maxLimit {
            maxLimit = Int(max)
        }
        
        if limit < minLimit {
            let message = String(format: "Error.Transfer.Limit.MoreThen".localized, Tools.bigToString(value: BigUInt(minLimit), decimal: 0, 0, true).currencySeparated())
            if showError { self.stepLimitInputBox.setState(.error, message)}
            return false
        }
        
        if limit > maxLimit {
            let message = String(format: "Error.Transfer.Limit.LessThen".localized, Tools.bigToString(value: BigUInt(maxLimit), decimal: 0, 0, true).currencySeparated())
            if showError { self.stepLimitInputBox.setState(.error, message)}
            return false
        }
        
        if showError { self.stepLimitInputBox.setState(.normal, nil) }
        
        if let stepPrice = self.stepPrice {
            let estimated = limit * stepPrice
            self.estimatedFee.text = Tools.bigToString(value: estimated, decimal: 18, 18, false).currencySeparated()
            self.exchangeEstimatedFee.text = Tools.balanceToExchange(estimated, from: "icx", to: "usd", belowDecimal: 2, decimal: 18)! + " USD"
            
            if let sendText = Conn.received?.params?["value"] as? String, let inputValue = BigUInt(sendText.prefix0xRemoved(), radix: 16) {
                
                if  totalBalance >= estimated + inputValue {
                    let remain = Conn.action! == "sendToken" ? totalBalance - inputValue : totalBalance - (estimated + inputValue)
                    Log.Debug("remain 2 - \(remain)")
                    self.remain.text = Tools.bigToString(value: remain, decimal: 18, 18, false)
                    if let exchanged = Tools.balanceToExchange(remain, from: symbol, to: "usd", belowDecimal: 2, decimal: 18) {
                        self.exchangeRemain.text = exchanged + " USD"
                    } else {
                        self.exchangeRemain.text = "- USD"
                    }
                } else {
                    let remainValue = estimated + inputValue - totalBalance
                    self.remain.text = "-" + Tools.bigToString(value: remainValue, decimal: 18, 18, false)
                    self.exchangeRemain.text = "- USD"
                }
            } else {
                self.remain.text = "-"
                self.exchangeRemain.text = "- USD"
            }
        }
        
        return true
    }
    
    @discardableResult
    func calculateStepLimit() -> BigUInt? {
        guard let costs = self.costs else { return nil }
        
        guard let stepDefault = BigUInt(costs.defaultValue.prefix0xRemoved(), radix: 16) else { return nil } //, let contractCall = BigUInt(costs.contractCall.prefix0xRemoved(), radix: 16), let input = BigUInt(costs.input.prefix0xRemoved(), radix: 16) else { return nil }
        guard let action = Conn.action else { return nil }
        if action == "sendToken" {
            let stepLimit = 2 * stepDefault
            
            self.stepLimitInputBox.textField.text = Tools.bigToString(value: stepLimit, decimal: 0, 0, false)
            return stepLimit
        } else {
            if let data = Conn.received?.params?["data"] as? String {
                guard let input = BigUInt(costs.input.prefix0xRemoved(), radix: 16) else { return nil }
                let stepLimit = stepDefault + (input * BigUInt(data.bytes.count))
                
                self.stepLimitInputBox.textField.text = Tools.bigToString(value: stepLimit, decimal: 0, 0, false)
                return stepLimit
            } else {
                guard let cost = self.costs else { return nil }
                let minimum = BigUInt(cost.defaultValue.prefix0xRemoved(), radix: 16)!
                self.stepLimitInputBox.textField.text = String(minimum)
                return minimum
            }
        }
    }
}
