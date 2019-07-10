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
    @IBOutlet weak var developerTitle: UILabel!
    @IBOutlet weak var networkLabel: UILabel!
    @IBOutlet weak var chooseNetworkButton: UIButton!
    
    @IBOutlet weak var amountTitle: UILabel!
    @IBOutlet weak var amount: UILabel!
    @IBOutlet weak var exchangeAmount: UILabel!
    @IBOutlet weak var toTitle: UILabel!
    @IBOutlet weak var to: UILabel!
    @IBOutlet weak var stepLimitTitle: UILabel!
    @IBOutlet weak var stepLimitInfoButton: UIButton!
    @IBOutlet weak var stepLimitInputBox: IXInputBox!
    @IBOutlet weak var stepPriceTitle: UILabel!
    @IBOutlet weak var stepPriceInfoButton: UIButton!
    @IBOutlet weak var stepPriceLabel: UILabel!
    @IBOutlet weak var stepPriceGloop: UILabel!
    @IBOutlet weak var exchangeStepPrice: UILabel!
    @IBOutlet weak var estimatedFeeTitle: UILabel!
    @IBOutlet weak var estimatedFeeInfoButton: UIButton!
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
    private var value: BigUInt = 0
    private let symbol: String = {
        if let token = Conn.tokenSymbol {
            return token
        } else {
            return "ICX"
        }
    }()
    private let decimal: Int = {
        if let tokenDecimal = Conn.tokenDecimal {
            return tokenDecimal
        } else {
            return 18
        }
    }()
    
    var privateKey: PrivateKey?
    
    var connTx: ConnectTransaction?
    
    private var transaction: Transaction?
    
    private var balance: BigUInt?
    
    private var provider: ICONService = WManager.service
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.balance = refreshBalance()
        initializeUI()
        initialize()
        setting()
    }
    
    func generateTransaction() {
        guard let txInfo = connTx else {
            Conn.sendError(error: ConnectError.invalidJSON)
            return
        }
        
        let tx = Transaction()
        tx.from = txInfo.from
        tx.to = txInfo.to
        tx.value = txInfo.value?.hexToBigUInt()
        tx.nid = txInfo.nid
        tx.nonce = txInfo.nonce
        
        if let timestamp = txInfo.timestamp {
            tx.timestamp = timestamp
        }
        
        tx.dataType = txInfo.dataType
        if let data = txInfo.data {
            switch data {
            case .message(let message):
                tx.data = message
                
            case .call(let call):
                var dataDic = [String: Any]()
                dataDic["method"] = call.method
                
                if let params = call.params {
                    dataDic["params"] = params
                }
                tx.data = dataDic
            }
        }
        
        transaction = tx
        
        guard let createdTx = transaction, let estimatedStepCost = stepLimitInputBox.textField.text, let step = BigUInt(estimatedStepCost) else {
            stepLimitInputBox.setState(.error, "Error.Transfer.EmptyLimit".localized)
            return
        }
        
        createdTx.stepLimit(step)
    }

    func initialize() {
        scrollView.rx.didEndDragging.observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] _ in
            self.view.endEditing(true)
        }).disposed(by: disposeBag)
        
        closeButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            Alert.Confirm(message: "Alert.Connect.Send.Cancel".localized, handler: {
                Conn.sendError(error: ConnectError.userCancel)
            }).show(self)
        }).disposed(by: disposeBag)
        
        // developermode choose network button
        chooseNetworkButton.rx.controlEvent(.touchUpInside).subscribe(onNext: {
            Alert.DeveloperNetworkProvider(source: self, completion: {
                self.refresh()
                self.sendButton.isEnabled = self.validateLimit()
            })
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
        
        stepLimitInfoButton.rx.tap.asControlEvent().subscribe(onNext: { [unowned self] in
            let attr1 = NSAttributedString(string: "Transfer.Step.LimitInfo.First".localized, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .bold)])
            let attr2 = NSAttributedString(string: "Transfer.Step.LimitInfo.Second".localized)
            let attr = NSMutableAttributedString(attributedString: attr1)
            attr.append(attr2)
            Alert.Basic(attributed: attr).show(self)
        }).disposed(by: disposeBag)
        
        stepPriceInfoButton.rx.tap.asControlEvent().subscribe(onNext: { [unowned self] in
            let attr1 = NSAttributedString(string: "Transfer.Step.PriceInfo.First".localized + "\n", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .bold)])
            let attr2 = NSAttributedString(string: "Transfer.Step.PriceInfo.Second".localized)
            let attr3 = NSAttributedString(string: "Transfer.Step.PriceInfo.Third".localized)
            let superscript = NSMutableAttributedString(string: "Transfer.Step.PriceInfo.Superscript".localized)
            superscript.setAttributes([NSAttributedString.Key.baselineOffset: 10, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 7)], range: NSRange(location: 2, length: 3))
            
            let attr = NSMutableAttributedString(attributedString: attr1)
            attr.append(attr2)
            attr.append(superscript)
            attr.append(attr3)
            Alert.Basic(attributed: attr).show(self)
        }).disposed(by: disposeBag)
        
        estimatedFeeInfoButton.rx.tap.asControlEvent().subscribe(onNext: { (_) in
            Alert.Basic(message: "Transfer.EstimatedStep".localized).show(self)
        }).disposed(by: disposeBag)
        
        viewData.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: {
            self.viewImage.isHighlighted = !self.viewImage.isHighlighted
            self.dataView.isHidden = !self.viewImage.isHighlighted
            
            if self.viewImage.isHighlighted {
                guard let text = self.dataLabel.text else { return }
                let lf = text.enumerated().filter({ $0.element == "\n" })
                let size = text.boundingRect(size: CGSize(width: self.dataLabel.frame.width, height: .greatestFiniteMagnitude), font: self.dataLabel.font)
                self.dataViewHeight.constant = size.height + 14.0 * CGFloat(lf.count == 0 ? 1 : lf.count)
                self.view.layoutIfNeeded()
                self.scrollView.setContentOffset(CGPoint(x: 0, y: self.scrollView.contentSize.height - self.scrollView.bounds.height + self.scrollView.contentInset.bottom), animated: true)
                
            } else {
                self.dataViewHeight.constant = 0
            }
        }).disposed(by: disposeBag)
        
        sendButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: {
            guard let received = Conn.received else { return }
            guard let to = received.payload?.params.to else { return }
            guard let stepPrice = self.stepPrice else { return }
            guard let key = self.privateKey else { return }
            guard let balance = self.balance else { return }
            guard let limit = BigUInt(self.stepLimitInputBox.textField.text!.prefix0xRemoved()) else { return }
            
            let estimated = stepPrice * limit
            
            self.generateTransaction()
            guard let tx = self.transaction else { return }
            
            if Conn.tokenDecimal != nil {
                guard self.value <= balance else {
                    Conn.sendError(error: .insufficient(.balance))
                    return
                }
            } else {
                guard self.value + estimated <= balance else {
                    Conn.sendError(error: .insufficient(.balance))
                    return
                }
            }
            
            let confirm = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "SendConfirmView") as! SendConfirmViewController

            // irc
            if let tokenSymbol = Conn.tokenSymbol, let decimals = Conn.tokenDecimal {
                confirm.feeType = "icx"
                confirm.fee = Tools.bigToString(value: estimated, decimal: 18, 18, false)
                confirm.address = to
                confirm.value = Tools.bigToString(value: self.value, decimal: decimals, decimals, false).currencySeparated()
                confirm.type = tokenSymbol.uppercased()

                confirm.handler = {
                    if let signed = try? SignedTransaction(transaction: tx, privateKey: key) {
                        let result = self.provider.sendTransaction(signedTransaction: signed).execute()
                        confirm.dismiss(animated: true, completion: {
                            switch result {
                            case .failure(let error):
                                Log.Debug("Error - \(error)")
                                var msg = ""
                                switch error {
                                case .error(error: let error):
                                        msg = "\n" + error.localizedDescription
                                    
                                default:
                                    break
                                }
                                
                                Tools.toast(message: "Error.CommonError".localized + msg)
                            
                            case .success(let hash):
                                let complete = Alert.Basic(message: "Alert.Connect.Send.Completed".localized)
                                complete.handler = {
                                    Conn.sendICXHash(txHash: hash)
                                }
                                complete.show(self)
                            }
                        })

                    } else {
                        Conn.sendError(error: .sign)
                    }
                }
                confirm.show(self)
            } else {
                confirm.feeType = "icx"
                confirm.fee = Tools.bigToString(value: estimated, decimal: 18, 18, false)
                confirm.address = to

                confirm.value = Tools.bigToString(value: self.value, decimal: 18, 18, false).currencySeparated()
                confirm.type = "icx"
                confirm.handler = {
                    if let signed = try? SignedTransaction(transaction: tx, privateKey: key) {
                        let result = self.provider.sendTransaction(signedTransaction: signed).execute()
                        confirm.dismiss(animated: true, completion: {
                            switch result {
                            case .failure(let error):
                                Log.Debug("Error - \(error)")
                                Conn.sendError(error: .network(error))
                            
                            case .success(let hash):
                                let complete = Alert.Basic(message: "Alert.Connect.Send.Completed".localized)
                                complete.handler = {
                                    Conn.sendICXHash(txHash: hash)
                                }
                                complete.show(self)
                            }
                        })
                    } else {
                        Conn.sendError(error: .sign)
                    }
                }
                confirm.show(self)
            }
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        guard let from = Conn.received?.payload?.params.from, let toAddress = Conn.received?.payload?.params.to, let wallet = WManager.loadWalletBy(address: from, type: .icx) as? ICXWallet else { return }
        
        navTitle.text = wallet.alias
        
        // developer mode
        if UserDefaults.standard.bool(forKey: "Developer") {
            developer.isHidden = false
            developerTitle.text = "Connect.Send.Developer.Title".localized
            
            let networkProvider = UserDefaults.standard.integer(forKey: "Provider")
            guard let provider = Configuration.HOST(rawValue: networkProvider) else {
                networkLabel.text = Configuration.HOST.main.name
                return
            }
            networkLabel.text = provider.name
        } else {
            developer.isHidden = true
        }
        
        amountTitle.text = "Connect.Send.Amount".localized + " (\(self.symbol))"
        amount.text = "-"
        exchangeAmount.text = "- USD"
        toTitle.text = "Connect.Send.to".localized
        to.text = toAddress
        stepLimitTitle.text = "Connect.Send.StepLimit".localized
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
        
        self.data.isHidden = Conn.received?.payload?.params.data == nil ? true : false
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
                self.calculateStepLimit()
                self.sendButton.isEnabled = self.validateLimit()
            }
        }
    }

    func setting() {
        
        if let decimal = Conn.tokenDecimal, let symbol = Conn.tokenSymbol {
            guard let data = Conn.received?.payload?.params.data else { return }
            
            switch data {
            case .call(let call):
                guard let value = call.params?["_value"] as? String else {
                    Conn.sendError(error: .notFound(.value))
                    return
                }
                guard let bigValue = BigUInt(value.prefix0xRemoved(), radix: decimal) else {
                    Conn.sendError(error: .invalidParameter(.value))
                    return
                }
                self.value = bigValue
            default: return
            }
            
            amount.text = Tools.bigToString(value: self.value, decimal: decimal, decimal, false).currencySeparated()
            if let exchange = Tools.balanceToExchange(self.value, from: symbol.lowercased(), to: "usd", belowDecimal: 2, decimal: decimal) {
                exchangeAmount.text = exchange + " USD"
            } else {
                exchangeAmount.text = "- USD"
            }
        } else {
            let valueString = Conn.received?.payload?.params.value ?? "0"
            guard let value = BigUInt(valueString.prefix0xRemoved(), radix: 16) else {
                Conn.sendError(error: ConnectError.invalidParameter(.value))
                return
            }
            self.value = value
            
            amount.text = Tools.bigToString(value: self.value, decimal: 18, 18, false).currencySeparated()
            if let exchange = Tools.balanceToExchange(self.value, from: "icx", to: "usd", belowDecimal: 2, decimal: 18) {
                exchangeAmount.text = exchange + " USD"
            } else {
                exchangeAmount.text = "- USD"
            }
        }
        if let data = Conn.received?.payload?.params.data {
            switch data {
            case .message(let message):
                if message == "" {
                    dataLabel.text = message
                    return
                }
                
                guard let msgData = message.prefix0xRemoved().hexToData(), let str = String(data: msgData, encoding: .utf8) else {
                    Conn.sendError(error: .invalidParameter(.data))
                    return
        
                }
                dataLabel.text = str
                
            case .call(let call):
                var callData: [String: Any]
                callData = ["method": call.method]
                
                guard let params: [String: Any] = call.params else { return }
                callData["params"] = params
                
                guard let json = try? JSONSerialization.data(withJSONObject: callData, options: .prettyPrinted), let jsonString = String(data: json, encoding: .utf8) else { return }
                
                dataLabel.text = jsonString
            }
        }
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
        guard let totalBalance: BigUInt = self.balance else {
            self.remain.text = ""
            self.exchangeRemain.text = "- USD"
            return false
        }
        
        guard let limitString = self.stepLimitInputBox.textField.text , limitString != "", let limit = BigUInt(limitString) else {
            if showError { self.stepLimitInputBox.setState(.error, "Error.Transfer.EmptyLimit".localized)}
            let limit = BigUInt(0)
            self.estimatedFee.text = Tools.bigToString(value: limit, decimal: 18, 18, false).currencySeparated()
            self.exchangeEstimatedFee.text = Tools.balanceToExchange(limit, from: "icx", to: "usd", belowDecimal: 2, decimal: 18)! + " USD"
            self.remain.text = Tools.bigToString(value: totalBalance, decimal: decimal, decimal, false).currencySeparated()
            if let exchangedRemain = Tools.balanceToExchange(totalBalance, from: "icx", to: "usd", belowDecimal: 2, decimal: decimal) {
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
            
            if (symbol != "ICX" ? self.value : estimated + self.value) > totalBalance {
                self.remain.text = ""
                self.exchangeRemain.text = "- USD"
                return false
            }
            let remain = symbol != "ICX" ? totalBalance - self.value : totalBalance - (estimated + self.value)
            Log.Debug("remain 2 - \(remain)")
            self.remain.text = Tools.bigToString(value: remain, decimal: decimal, decimal, false)
            if symbol != "ICX" {
                self.exchangeRemain.text = "- USD"
            } else {
                guard let exchanged = Tools.balanceToExchange(remain, from: "icx", to: "usd", belowDecimal: 2, decimal: decimal) else {
                    self.exchangeRemain.text = "- USD"
                    return false
                }
                self.exchangeRemain.text = exchanged + " USD"
            }
        }
        return true
    }
    
    func refresh() {
        self.provider = ConnManager.provider
        
        let networkId = self.provider.nid
        transaction?.nid(networkId)
        
        let host: Int = {
            switch networkId {
            case "0x1": return 0
            case "0x2": return 1
            case "0x3": return 2
            default: return 0
            }
        }()
        guard let provider = Configuration.HOST(rawValue: host) else {
            networkLabel.text = Configuration.HOST.main.name
            return
        }
        networkLabel.text = provider.name
        self.balance = refreshBalance()
    }
    
    func refreshBalance() -> BigUInt? {
        let provider = self.provider
        guard let fromAddress = Conn.received?.payload?.params.from else { return nil }
        
        if symbol == "ICX" {
            let request = provider.getBalance(address: fromAddress).execute()
            
            switch request {
            case .success(let balance):
                return balance
            case .failure:
                return nil
            }
        } else {
            guard let contractAddress = Conn.received?.payload?.params.to else { return nil }
            let call = Call<BigUInt>(from: fromAddress, to: contractAddress, method: "balanceOf", params: ["_owner": fromAddress])
            let request = provider.call(call).execute()
            
            switch request {
            case .success(let balance):
                return balance
            case .failure:
                return nil
            }
        }
    }
    
    @discardableResult
    func calculateStepLimit() -> BigUInt? {
        let step: BigUInt = Conn.received?.payload?.params.data == nil ? BigUInt(integerLiteral: 100000) : BigUInt(integerLiteral: 1000000)
        self.stepLimitInputBox.textField.text = String(step)
        return step
    }
}
