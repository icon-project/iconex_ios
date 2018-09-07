//
//  SwapStepFiveViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import BigInt
import web3swift

class SwapStepFiveViewController: BaseViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerLabel1: UILabel!
    @IBOutlet weak var amntTitleLabel: UILabel!
    @IBOutlet weak var amntLabel: UILabel!
    @IBOutlet weak var excAmntLabel: UILabel!
    @IBOutlet weak var transAmntLabel: UILabel!
    @IBOutlet weak var transInputBox: IXInputBox!
    @IBOutlet weak var add1: UIButton!
    @IBOutlet weak var add2: UIButton!
    @IBOutlet weak var add3: UIButton!
    @IBOutlet weak var add4: UIButton!
    @IBOutlet weak var swapAddrTitle: UILabel!
    @IBOutlet weak var swapAddrLabel: UILabel!
    @IBOutlet weak var swapAddrDesc1: UILabel!
    @IBOutlet weak var swapAddrDesc2: UILabel!
    @IBOutlet weak var recvAddrTitle: UILabel!
    @IBOutlet weak var recvAddrLabel: UILabel!
    @IBOutlet weak var recvAddrDesc: UILabel!
    @IBOutlet weak var limitGasTitle: UILabel!
    @IBOutlet weak var limitGasLabel: UILabel!
    @IBOutlet weak var gasPriceTitle: UILabel!
    @IBOutlet weak var gasPriceLabel: UILabel!
    @IBOutlet weak var estmFeeTitleLabel: UILabel!
    @IBOutlet weak var estmFeeLabel: UILabel!
    @IBOutlet weak var excEstmFeeLabel: UILabel!
    @IBOutlet weak var remainTitle: UILabel!
    @IBOutlet weak var remainLabel: UILabel!
    @IBOutlet weak var excRemainLabel: UILabel!
    @IBOutlet weak var bottomDescLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!

    var delegate: SwapStepDelegate?
    var totalBaseBalance: BigUInt?
    var totalTokenBalance: BigUInt?
    
    private var _gasPrice: BigUInt?
    private var _gasLimit: BigUInt?
    
    private var burnAddress = "0x0000000000000000000000000000000000000000"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        initializeUI()
        initialize()
    }

    func initializeUI() {
        headerLabel1.text = "Swap.Step5.SwapAddress.Header1".localized
        amntTitleLabel.text = "Transfer.Balance".localized + " (ICX)"
        
        transAmntLabel.text = "Swap.Step5.SwapAmount".localized + " (ICX)"
        transInputBox.setState(.normal, "")
        transInputBox.setType(.numeric)
        transInputBox.textField.placeholder = "Placeholder.SwapAmount".localized
        
        add1.styleDark()
        add1.cornered()
        add1.setTitle("+10", for: .normal)
        add2.styleDark()
        add2.cornered()
        add2.setTitle("+100", for: .normal)
        add3.styleDark()
        add3.cornered()
        add3.setTitle("+1000", for: .normal)
        add4.styleDark()
        add4.cornered()
        add4.setTitle("Transfer.Max".localized, for: .normal)
        
        swapAddrTitle.text = "Swap.Step5.SwapAddress.Header".localized
        swapAddrLabel.text = burnAddress
        swapAddrDesc1.text = "Swap.Step5.SwapAddress.Desc1".localized
        swapAddrDesc2.text = "Swap.Step5.SwapAddress.Desc2".localized
        
        recvAddrTitle.text = "Swap.Step5.ICXAddress.Header1".localized
        recvAddrDesc.text = "Swap.Step5.ICXAddress.Desc1".localized
        
        limitGasTitle.text = "Swap.Step5.GasLimit".localized
        limitGasLabel.text = "-"
        gasPriceTitle.text = "Swap.Step5.GasPrice".localized
        gasPriceLabel.text = "- Gwei"
        estmFeeTitleLabel.text = "Swap.Step5.EstimatedFee".localized + " (ETH)"
        estmFeeLabel.text = "-"
        excEstmFeeLabel.text = "-"
        remainTitle.text = "Swap.Step5.EstimatedRemain".localized + " (ICX)"
        bottomDescLabel.text = "Swap.Step5.BottomDesc".localized
        
        doneButton.styleDark()
        doneButton.rounded()
        doneButton.setTitle("Common.Done".localized, for: .normal)
        
        doneButton.isEnabled = false
        
        let wallet = WManager.loadWalletBy(info: SwapManager.sharedInstance.walletInfo!) as! ETHWallet
        let token = wallet.tokens!.filter { $0.symbol.lowercased() == "icx" }.first!
        if let balances = WManager.tokenBalanceList[token.dependedAddress], let balance = balances[token.contractAddress] {
            totalBaseBalance = balance
            amntLabel.text = Tools.bigToString(value: balance, decimal: token.decimal, token.decimal, false)
            remainLabel.text = Tools.bigToString(value: balance, decimal: token.decimal, token.decimal, false)
            if let exchanged = Tools.balanceToExchange(balance, from: "icx", to: "usd", belowDecimal: 2, decimal: token.decimal) {
                excAmntLabel.text = exchanged.currencySeparated() + " USD"
                excRemainLabel.text = exchanged.currencySeparated() + " USD"
            } else {
                excAmntLabel.text = "-"
                excRemainLabel.text = "-"
            }
        } else {
            excAmntLabel.text = "-"
            excRemainLabel.text = "-"
        }
        
        recvAddrLabel.text = token.swapAddress
    }
    
    func initialize() {
        keyboardHeight().observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] (height: CGFloat) in
            if height == 0 {
                self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            } else {
                var keyboardHeight: CGFloat = height
                if #available(iOS 11.0, *) {
                    keyboardHeight = keyboardHeight - (self.view.safeAreaInsets.bottom + 76)
                }
                self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
            }
        }).disposed(by: disposeBag)
        
        add1.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let formerValue = Tools.stringToBigUInt(inputText: self.transInputBox.textField.text!) else {
                    return
                }
                guard let info = SwapManager.sharedInstance.walletInfo else { return }
                guard let wallet = WManager.loadWalletBy(info: info) else { return }
                let result = formerValue + BigUInt(10).power(19)
                let stringValue = Tools.bigToString(value: result, decimal: wallet.decimal, wallet.decimal, true)
                self.transInputBox.textField.text = stringValue
                if self.validateBalance() {
                    self.fetchETHPrices()
                }
            }).disposed(by: disposeBag)
        
        add2.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let formerValue = Tools.stringToBigUInt(inputText: self.transInputBox.textField.text!) else {
                    return
                }
                guard let info = SwapManager.sharedInstance.walletInfo else { return }
                guard let wallet = WManager.loadWalletBy(info: info) else { return }
                let result = formerValue + BigUInt(10).power(20)
                let stringValue = Tools.bigToString(value: result, decimal: wallet.decimal, wallet.decimal, true)
                self.transInputBox.textField.text = stringValue
                if self.validateBalance() {
                    self.fetchETHPrices()
                }
            }).disposed(by: disposeBag)
        
        add3.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let formerValue = Tools.stringToBigUInt(inputText: self.transInputBox.textField.text!) else {
                    return
                }
                guard let info = SwapManager.sharedInstance.walletInfo else { return }
                guard let wallet = WManager.loadWalletBy(info: info) else { return }
                let result = formerValue + BigUInt(10).power(21)
                let stringValue = Tools.bigToString(value: result, decimal: wallet.decimal, wallet.decimal, true)
                self.transInputBox.textField.text = stringValue
                if self.validateBalance() {
                    self.fetchETHPrices()
                }
            }).disposed(by: disposeBag)
        
        add4.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let info = SwapManager.sharedInstance.walletInfo else { return }
                guard let wallet = WManager.loadWalletBy(info: info) else { return }
                guard let fullValue = self.totalBaseBalance else { return }
                self.transInputBox.textField.text = Tools.bigToString(value: fullValue, decimal: wallet.decimal, wallet.decimal, true)
                if self.validateBalance() {
                    self.fetchETHPrices()
                }
            }).disposed(by: disposeBag)
        
        transInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.transInputBox.setState(.focus, nil)
        }).disposed(by: disposeBag)
        transInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            if self.validateBalance() {
                self.fetchETHPrices()
            }
        }).disposed(by: disposeBag)
        transInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            if self.validateBalance() {
                self.fetchETHPrices()
            }
        }).disposed(by: disposeBag)
        transInputBox.textField.rx.controlEvent(UIControlEvents.editingChanged).subscribe(onNext: { [unowned self] in
            guard let sendValue = self.transInputBox.textField.text, let send = Tools.stringToBigUInt(inputText: sendValue), let exchanged = Tools.balanceToExchange(send, from: "icx", to: "usd", belowDecimal: 2, decimal: 18) else {
                return
            }
            self.transInputBox.setState(.exchange, exchanged.currencySeparated() + " USD")
        }).disposed(by: disposeBag)
        
        doneButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.sendToken()
        }).disposed(by: disposeBag)
        
        scrollView.rx.didEndDragging.observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] _ in
            self.view.endEditing(false)
        }).disposed(by: disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @discardableResult
    func validateBalance() -> Bool {
        guard let sendText = self.transInputBox.textField.text, sendText != "" else {
            self.transInputBox.setState(.error, "Error.EnterSwapAmount".localized)
            self.doneButton.isEnabled = false
            return false
        }
        
        let wallet = WManager.loadWalletBy(info: SwapManager.sharedInstance.walletInfo!) as! ETHWallet
        let icxValue = Tools.stringToBigUInt(inputText: sendText)!
        
        guard let totalToken = self.totalBaseBalance else { return false }
        
        if icxValue > totalToken {
            self.transInputBox.setState(.error, "Error.Transfer.AboveMax".localized)
            self.doneButton.isEnabled = false
            return false
        } else if icxValue == BigUInt(0) {
            self.transInputBox.setState(.error, "Error.EnterSwapAmount".localized)
            self.doneButton.isEnabled = false
            return false
        }
        
        self.transInputBox.textField.text = Tools.bigToString(value: icxValue, decimal: wallet.decimal, wallet.decimal, true)
        self.remainLabel.text = Tools.bigToString(value: totalToken - (icxValue), decimal: wallet.decimal, wallet.decimal, true)
        if let excRemainBalance = Tools.balanceToExchange(totalToken - (icxValue), from: "icx", to: "usd", belowDecimal: 2, decimal: wallet.decimal) {
            self.excRemainLabel.text = excRemainBalance.currencySeparated() + " USD"
        }
        
        guard let sendValue = self.transInputBox.textField.text, let send = Tools.stringToBigUInt(inputText: sendValue), let exchanged = Tools.balanceToExchange(send, from: "icx", to: "usd", belowDecimal: 2, decimal: 18) else {
            return false
        }
        self.transInputBox.setState(.exchange, exchanged.currencySeparated() + " USD")
        
        return true
    }
    
    func fetchETHPrices() {
        let wallet = WManager.loadWalletBy(info: SwapManager.sharedInstance.walletInfo!) as! ETHWallet
        let token = wallet.tokens!.filter { $0.symbol.lowercased() == "icx" }.first!
        let sendText = self.transInputBox.textField.text!
        let icxValue = Tools.stringToBigUInt(inputText: sendText)!
        
        self.doneButton.setTitle("", for: .normal)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: doneButton.frame.width / 2 - 20, y: doneButton.frame.height / 2 - 20), size: CGSize(width: 40, height: 40)))
        imageView.image = #imageLiteral(resourceName: "icRefresh01")
        imageView.tag = 999
        doneButton.addSubview(imageView)
        Tools.rotateAnimation(inView: imageView)
        
        var isDone = 0
        
        DispatchQueue.global().async {
            if var gasPrice = Ethereum.gasPrice {
//            if let gasPrice = Web3.Utils.parseToBigUInt("21", units: .Gwei) {
                gasPrice += Web3.Utils.parseToBigUInt("10", units: .Gwei)!
                gasPrice = max(min((Web3.Utils.parseToBigUInt("99", units: .Gwei)!), gasPrice), Web3.Utils.parseToBigUInt("21", units: .Gwei)!)
                Log.Debug("gas price \(gasPrice)")
                self._gasPrice = gasPrice
                if let gasResult = Ethereum.requestTokenEstimatedGas(value: icxValue, gasPrice: gasPrice, from: wallet.address!, to: self.burnAddress, tokenInfo: token) {
                    self._gasLimit = gasResult * 2
                    guard let estimatedGas = self._gasLimit else { return }
                    DispatchQueue.main.async {
                        isDone += 1
                        
                        self.estmFeeLabel.text = Tools.bigToString(value: gasPrice * estimatedGas, decimal: wallet.decimal, wallet.decimal, true)
                        if let exchangeFee = Tools.balanceToExchange(gasPrice * estimatedGas, from: "eth", to: "usd", belowDecimal: 2, decimal: wallet.decimal) {
                            self.excEstmFeeLabel.text = exchangeFee.currencySeparated() + " USD"
                        }
                        self.limitGasLabel.text = String(estimatedGas)
                        if self._gasLimit != nil && self._gasPrice != nil {
                            self.doneButton.isEnabled = true
                        } else { self.doneButton.isEnabled = false }
                        
                        if isDone == 2 {
                            let image = self.doneButton.viewWithTag(999)
                            image?.removeFromSuperview()
                            
                            self.doneButton.setTitle("Common.Done".localized, for: .normal)
                        }
                    }
                }
                let gasPriceString = Web3.Utils.formatToEthereumUnits(gasPrice, toUnits: .Gwei, decimals: 18, decimalSeparator: ".")!
                DispatchQueue.main.async {
                    isDone += 1
                    
                    self.gasPriceLabel.text = gasPriceString + " Gwei"
                    if self._gasLimit != nil && self._gasPrice != nil {
                        self.doneButton.isEnabled = true
                        
                    } else { self.doneButton.isEnabled = false }
                    
                    if isDone == 2 {
                        let image = self.doneButton.viewWithTag(999)
                        image?.removeFromSuperview()
                        
                        self.doneButton.setTitle("Common.Done".localized, for: .normal)
                    }
                }
            }
        }
    }
    
    func sendToken() {
        guard let gasPrice = _gasPrice, let gasLimit = _gasLimit else {
            return
        }
        
        let wallet = WManager.loadWalletBy(info: SwapManager.sharedInstance.walletInfo!) as! ETHWallet
        let sendText = self.transInputBox.textField.text!
        let sendValue = Tools.stringToBigUInt(inputText: sendText)!
        let swapValue = Tools.bigToString(value: sendValue, decimal: 18, 18, false, true)
        
        let swapSendConfirm = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "SwapSendConfirmView") as! SwapSendConfirmViewController
        swapSendConfirm._gasLimit = gasLimit
        swapSendConfirm._gasPrice = gasPrice
        swapSendConfirm.feeValue = Tools.bigToString(value: gasPrice * gasLimit, decimal: wallet.decimal, wallet.decimal, true)
        swapSendConfirm.swapValue = swapValue
        swapSendConfirm.handler = {
            self.dismiss(animated: true, completion: {
                let app = UIApplication.shared.delegate as! AppDelegate
                let root = app.window!.rootViewController as! UINavigationController
                let main = root.viewControllers[0]
                
                let swapConfirm = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "SwapConfirmView") as! SwapConfirmViewController
                swapConfirm.show(main)
            })
        }
        self.present(swapSendConfirm, animated: true, completion: nil)
    }
}
