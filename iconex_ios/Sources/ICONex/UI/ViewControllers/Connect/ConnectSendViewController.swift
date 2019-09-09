//
//  ConnectSendViewController.swift
//  iconex_ios
//
//  Created by Seungyeon Lee on 2019/09/08.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import ICONKit
import BigInt
import PanModal

class ConnectSendViewController: BaseViewController {
    @IBOutlet weak var navBar: PopableTitleView!
    @IBOutlet weak var developer: UIView!
    @IBOutlet weak var networkView: UIView!
    @IBOutlet weak var developerTitle: UILabel!
    @IBOutlet weak var networkLabel: UILabel!
    @IBOutlet weak var chooseNetworkButton: UIButton!
    
    @IBOutlet weak var amountTitle: UILabel!
    @IBOutlet weak var amountSymbol: UILabel!
    @IBOutlet weak var amount: UILabel!
    
    @IBOutlet weak var toTitle: UILabel!
    @IBOutlet weak var to: UILabel!
    
    @IBOutlet weak var footerBox: UIView!
    
    @IBOutlet weak var stepLimitTitle: UILabel!
    @IBOutlet weak var stepLimitLabel: UILabel!
    
    @IBOutlet weak var estimatedFeeTitle: UILabel!
    @IBOutlet weak var estimatedFeeLabel: UILabel!
    
    @IBOutlet weak var exchangedLabel: UILabel!
    
    @IBOutlet weak var viewData: UIButton!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var amountTitleTopConstraint: NSLayoutConstraint!
    
    private var costs: BigUInt = 0
    private var stepPrice: BigUInt = 0
    private var stepLimit: BigUInt = 0
    
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
    
    var selectedWallet: ICXWallet?
    var privateKey: PrivateKey?
    
    var connTx: ConnectTransaction?
    
    private var transaction: Transaction?
    
    private var balance: BigUInt?
    
    private var provider: ICONService = Manager.icon.service
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView?.rx.didScroll
            .subscribe({ (_) in
                self.view.endEditing(true)
            }).disposed(by: disposeBag)
        
        self.stepPrice = Manager.icon.stepPrice ?? 0
        
        if Conn.tokenSymbol != nil {
            self.costs = Manager.icon.stepCost?.contractCall.hexToBigUInt() ?? 0
            
        } else {
            if Conn.received?.payload?.params.data == nil {
                self.costs = Manager.icon.stepCost?.defaultValue.hexToBigUInt() ?? 0
            } else {
                self.costs = Manager.icon.stepCost?.input.hexToBigUInt() ?? 0
            }
        }
        
        if let stepLimit = Conn.received?.payload?.params.stepLimit {
            self.costs = stepLimit
        }
        
        self.stepLimit = self.costs * self.stepPrice
        
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
        
        if let stepLimit = txInfo.stepLimit {
            tx.stepLimit(stepLimit)
        } else {
            if txInfo.data != nil {
                tx.stepLimit(1000000)
            } else {
                tx.stepLimit(100000)
            }
        }
        
        transaction = tx
    }
    
    func initialize() {
        guard let wallet = self.selectedWallet else { return }
        navBar.set(title: wallet.name)
        navBar.actionHandler = {
            Alert.basic(title: "Alert.Connect.Send.Cancel1".localized, subtitle: "Alert.Connect.Send.Cancel2".localized, isOnlyOneButton: false, confirmAction: {
                Conn.sendError(error: ConnectError.userCancel)
            }).show()
        }
        
        // developermode choose network button
        chooseNetworkButton.rx.tap.asControlEvent().subscribe { (_) in
            let picker = UIStoryboard(name: "Picker", bundle: nil).instantiateInitialViewController() as! IXPickerViewController
            picker.items = ["Mainnet", "Euljiro", "Yeouido"]
            picker.selectedAction = { index in
                guard let provider = Configuration.HOST(rawValue: index) else {
                    self.networkLabel.text = Configuration.HOST.main.name
                    return
                }
                self.networkLabel.text = provider.name
                ConnManager.provider = ICONService(provider: provider.provider, nid: provider.nid)
                self.refresh()
            }
            picker.pop()
        }.disposed(by: disposeBag)
        
        
        
        viewData.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: {
            guard let data = Conn.received?.payload?.params.data else { return }
            
            let dataVC = self.storyboard?.instantiateViewController(withIdentifier: "DataView") as! ConnectDataViewController
            
            switch data {
            case .message(let message):
                guard !message.isEmpty else { return }
                
                guard let msgData = message.prefix0xRemoved().hexToData(), let messageString = String(data: msgData, encoding: .utf8) else {
                    Conn.sendError(error: .invalidParameter(.data))
                    return
                    
                }
                dataVC.dataString = messageString
                
            case .call(let call):
                var callData: [String: Any]
                callData = ["method": call.method]
                
                guard let params: [String: Any] = call.params else { return }
                callData["params"] = params
                
                guard let json = try? JSONSerialization.data(withJSONObject: callData, options: .prettyPrinted), let jsonString = String(data: json, encoding: .utf8) else { return }
                
                dataVC.dataString = jsonString
            }
            self.presentPanModal(dataVC)

        }).disposed(by: disposeBag)
        
        cancelButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                Alert.basic(title: "Alert.Connect.Send.Cancel1".localized, subtitle: "Alert.Connect.Send.Cancel2".localized, isOnlyOneButton: false, confirmAction: {
                    Conn.sendError(error: ConnectError.userCancel)
                }).show()
        }.disposed(by: disposeBag)
        
        sendButton.rx.tap.asControlEvent().subscribe(onNext: {
            guard let received = Conn.received else { return }
            guard let to = received.payload?.params.to else { return }
            guard let pk = self.privateKey else { return }
            guard let balance = self.balance else { return }
            
            self.generateTransaction()
            guard let tx = self.transaction else { return }

            if Conn.tokenDecimal != nil {
                guard self.value <= balance else {
                    Conn.sendError(error: .insufficient(.balance))
                    return
                }
            } else {
                guard self.value + self.stepLimit <= balance else {
                    Conn.sendError(error: .insufficient(.balance))
                    return
                }
            }
            let estimatedFee = self.stepLimit * self.stepPrice
            let estimatedExchange = Tool.calculatePrice(currency: "icxusd", balance: estimatedFee)
            
            
            let sendInfo: SendInfo? = {
                if Conn.tokenDecimal == nil {
                    return SendInfo(transaction: tx, privateKey: pk, stepLimitPrice: self.stepLimit.toString(decimal: 18, 9), estimatedFee: estimatedFee.toString(decimal: 18, 9), estimatedUSD: estimatedExchange)
                } else {
                    guard let token = DB.allTokenList().filter({ $0.contract == to }).first else { return nil }
                    
                    return SendInfo(transaction: tx, privateKey: pk, stepLimitPrice: self.stepLimit.toString(decimal: 18, 9), estimatedFee: estimatedFee.toString(decimal: 18, 9), estimatedUSD: estimatedExchange, token: token, tokenAmount: self.value, tokenToAddress: to)
                }
            }()
            
            guard let txInfo = sendInfo else { return }
            
            Alert.send(sendInfo: txInfo, confirmAction: { (isSuccess, txHash) in
                if isSuccess {
                    Alert.basic(title: "Alert.Connect.Send.Completed1".localized, subtitle: "Alert.Connect.Send.Completed2".localized, leftButtonTitle: "Common.Confirm".localized, cancelAction: {
                        if txHash != nil {
                            Conn.sendICXHash(txHash: txHash!)
                        }
                        
                    }).show()
                } else {
                    Log(txHash, .error)
                    Alert.basic(title: "Error.CommonError".localized, leftButtonTitle: "Common.Confirm".localized, cancelAction: {
                        Conn.sendError(error: .invalidJSON)
                    }).show()
                }
            }).show()
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        guard let wallet = self.selectedWallet else { return }
        guard let toAddress = Conn.received?.payload?.params.to else { return }
        
        navBar.set(title: wallet.name)
        
        // developer mode
        if UserDefaults.standard.bool(forKey: "Developer") {
            developer.isHidden = false
            developerTitle.size12(text: "Connect.Send.Developer.Title".localized, color: .gray77)
            
            let networkProvider = UserDefaults.standard.integer(forKey: "Provider")
            guard let provider = Configuration.HOST(rawValue: networkProvider) else {
                networkLabel.size16(text: Configuration.HOST.main.name, color: .gray77)
                return
            }
            networkLabel.size16(text: provider.name, color: .gray77)
            
            networkView.layer.cornerRadius = 4
            networkView.clipsToBounds = true
            networkView.backgroundColor = .gray250
            networkView.layer.borderColor = UIColor.gray230.cgColor
            networkView.layer.borderWidth = 1
            
        } else {
            developer.isHidden = true
            amountTitleTopConstraint.constant = 40
        }
        
        amountTitle.size16(text: "Connect.Send.Amount".localized, color: .gray77, weight: .medium)
        amountSymbol.size12(text: "(\(self.symbol))", color: .gray77, weight: .medium)
        amount.text = "-"
        toTitle.size16(text: "Connect.Send.to".localized, color: .gray77, weight: .medium)
        to.size12(text: toAddress, color: .gray77)
        
        footerBox.layer.cornerRadius = 4
        footerBox.clipsToBounds = true
        footerBox.backgroundColor = .gray250
        footerBox.layer.borderColor = UIColor.gray230.cgColor
        footerBox.layer.borderWidth = 1
        
        stepLimitTitle.size12(text: "Connect.Send.StepLimit".localized, color: .gray128, weight: .light)
        estimatedFeeTitle.size12(text: "Connect.Send.EstimatedFee".localized + " (ICX)", color: .gray128, weight: .light)
        
        viewData.isHidden = Conn.received?.payload?.params.data == nil ? true : false
        viewData.roundGray230()
        viewData.setTitle("Send.InputBox.Data.View".localized, for: .normal)
        
        cancelButton.setTitle("Common.Cancel".localized, for: .normal)
        cancelButton.round02()
        
        sendButton.setTitle("Transfer.Transfer".localized, for: .normal)
        sendButton.lightMintRounded()
    }
    
    func setting() {
        
        if let decimal = Conn.tokenDecimal {
            guard let data = Conn.received?.payload?.params.data else { return }
            
            switch data {
            case .call(let call):
                guard let value = call.params?["_value"] as? String else {
                    Conn.sendError(error: .notFound(.value))
                    return
                }
                guard let bigValue = BigUInt(value.prefix0xRemoved(), radix: 16) else {
                    Conn.sendError(error: .invalidParameter(.value))
                    return
                }
                self.value = bigValue
            default: return
            }
            
            amount.text = self.value.toString(decimal: decimal, decimal, false).currencySeparated()
            
        } else {
            let valueString = Conn.received?.payload?.params.value ?? "0"
            guard let value = BigUInt(valueString.prefix0xRemoved(), radix: 16) else {
                Conn.sendError(error: ConnectError.invalidParameter(.value))
                return
            }
            self.value = value
            
            amount.text = self.value.toString(decimal: 18, 18, false).currencySeparated()
        }
    }
    
    override func refresh() {
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
    
    func refreshBalance() -> BigUInt {
        guard let fromAddress = Conn.received?.payload?.params.from else { return 0 }
        
        if symbol.uppercased() == "ICX" {
            let request = self.provider.getBalance(address: fromAddress).execute()
            
            switch request {
            case .success(let balance):
                return balance
            case .failure:
                return 0
            }
        } else {
            guard let contractAddress = Conn.received?.payload?.params.to else { return 0 }
            let call = Call<BigUInt>(from: fromAddress, to: contractAddress, method: "balanceOf", params: ["_owner": fromAddress])
            let request = self.provider.call(call).execute()
            
            switch request {
            case .success(let balance):
                return balance
            case .failure:
                return 0
            }
        }
    }
}

extension ConnectSendViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    func shouldRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return false
    }
    
    var isHapticFeedbackEnabled: Bool {
        return false
    }
    
    var topOffset: CGFloat {
        return app.window!.safeAreaInsets.top
    }
    
    var backgroundAlpha: CGFloat {
        return 0.4
    }
    
    var cornerRadius: CGFloat {
        return 18.0
    }
}
