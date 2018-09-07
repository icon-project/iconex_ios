//
//  WalletDetailViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import BigInt
import web3swift

class WalletDetailCell: UITableViewCell {
    @IBOutlet weak var txTitleLabel: UILabel!
    @IBOutlet weak var txDateLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
}

class WalletDetailLoadCell: UITableViewCell {
    @IBOutlet weak var indicator: UIImageView!
}

class WalletDetailNoCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
}

class WalletDetailViewController: UIViewController {
    
    @IBOutlet weak var headerMain: UIView!
    @IBOutlet weak var headerLoading: IXIndicator!
    
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    
    @IBOutlet weak var upperLoaderView: UIView!
    @IBOutlet weak var upperConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var refresh01: UIImageView!
    @IBOutlet weak var refresh02: UIImageView!
    
    @IBOutlet weak var topSelectContainer: UIView!
    @IBOutlet weak var topSelectLabel: UILabel!
    @IBOutlet weak var topSelectButton: UIButton!
    
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var exchangeLabel: UILabel!
    @IBOutlet weak var exchangeSelectContainer: UIView!
    @IBOutlet weak var exchangeSelectLabel: UILabel!
    @IBOutlet weak var exchangeSelectButton: UIButton!
    
    @IBOutlet weak var stackContainer: UIStackView!
    @IBOutlet weak var swapButton: UIButton!
    @IBOutlet weak var outButton: UIButton!
    @IBOutlet weak var inButton: UIButton!
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var filterLabel: UILabel!
    @IBOutlet weak var filterButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var etherTop: NSLayoutConstraint!
    @IBOutlet weak var etherContainer: UIView!
    @IBOutlet weak var etherTransLabel: UILabel!
    @IBOutlet weak var etherScan: UILabel!
    @IBOutlet weak var etherButton: UIButton!
    
    @IBOutlet weak var fullLoaderContainer: UIView!
    @IBOutlet weak var fullLoaderImage: UIImageView!
    
    private let MAX_LIMIT: CGFloat = 100.0
    
    private var isDragTriggered: Bool = false
    private var isScrollable: Bool = true
    
    var walletInfo: WalletInfo?
    var token: TokenInfo?
    var historyList = [Tracker.TxList]()
    var filteredList: [Tracker.TxList]?
    var holdList: [TransactionModel]?
    
    var step: Int = 1
    private var totalData: Int = 0
    var isLoaded: Bool = false {
        willSet {
            if !newValue {
                tableView.isScrollEnabled = false
                fullLoaderContainer.isHidden = false
                Tools.rotateAnimation(inView: fullLoaderImage)
            } else {
                tableView.isScrollEnabled = true
                fullLoaderContainer.isHidden = true
            }
        }
    }
    
    var viewState: (state: Int, type: Int) = (0, 0) {
        willSet {
            var former = "Detail.Filter.Complete".localized
            var latter = "Detail.Filter.All".localized
            
            switch newValue.state {
            case 0:
                former = "Detail.Filter.Complete".localized
                
            case 1:
                former = "Detail.Filter.Pending".localized
                
            default:
                break
            }
            
            switch newValue.type {
            case 0:
                latter = "Detail.Filter.All".localized
                
            case 1:
                latter = "Detail.Filter.Transfer".localized
                
            case 2:
                latter = "Detail.Filter.Deposit".localized
                
            default:
                break
            }
            
            filterLabel.text = former + " ∙ " + latter
        }
    }
    
    let disposeBag = DisposeBag()
    
    var exchangeType: String = "usd" {
        didSet {
            loadExchanged()
        }
    }
    
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
        
        requestData()
    }
    
    func initialize() {
        
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
        
        outButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            guard let wallet = WManager.loadWalletBy(info: self.walletInfo!) else { return }
            if let token = self.token {
                guard let balances = WManager.tokenBalanceList[token.dependedAddress], let balance = balances[token.contractAddress], balance != BigUInt(0) else  {
                    let alert = UIStoryboard(name: "Alert", bundle: nil).instantiateInitialViewController() as! BasicActionViewController
                    alert.message = "Error.Detail.InsufficientBalance".localized
                    self.present(alert, animated: true, completion: nil)
                    
                    return
                }
            } else {
                guard let balance = wallet.balance, balance != BigUInt(0) else {
                    Alert.Basic(message: "Error.Detail.InsufficientBalance".localized).show(self)
                    return
                }
            }
            
            let pwdAlert = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "WalletPasswordView") as! WalletPasswordViewController
            pwdAlert.walletInfo = self.walletInfo
            
            pwdAlert.addConfirm(completion: { (isSuccess, privKey) in
                if isSuccess {
                    if self.walletInfo!.type == .icx {
                        let sendView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ICXSendView") as! ICXSendViewController
                        sendView.walletInfo = self.walletInfo
                        sendView.privateKey = privKey
                        self.navigationController?.pushViewController(sendView, animated: true)
                    } else if self.walletInfo!.type == .eth {
                        let ethSend = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ETHSendView") as! ETHSendViewController
                        ethSend.walletInfo = self.walletInfo
                        if let token = self.token {
                            ethSend.token = token
                        }
                        ethSend.privateKey = privKey
                        self.navigationController?.pushViewController(ethSend, animated: true)
                    }
                    
                } else {
                    
                }
            })
            
            self.present(pwdAlert, animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        inButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: {[unowned self] in
                Alert.PrivateInfo(walletInfo: self.walletInfo!).show(self)
            }).disposed(by: disposeBag)
        
        filterButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            let viewOption = UIStoryboard(name: "ActionControls", bundle: nil).instantiateViewController(withIdentifier: "ViewOption") as! ViewOptionViewController
            viewOption.present(from: self, title: "Detail.ViewOption".localized, state: self.viewState)
            viewOption.delegate = self
        }).disposed(by: disposeBag)
        
        exchangeSelectButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            let selectable = UIStoryboard(name: "ActionControls", bundle: nil).instantiateViewController(withIdentifier: "SelectableActionController") as! SelectableActionController
            selectable.present(from: self, title: "Detail.Select.Unit".localized, items: ["USD", "BTC", "ETH"])
            selectable.handler = ({ [unowned self] (selectedIndex) in
                switch selectedIndex {
                case 0:
                    self.exchangeType = "usd"
                    
                case 1:
                    self.exchangeType = "btc"
                    
                case 2:
                    self.exchangeType = "eth"
                    
                default:
                    self.exchangeType = "usd"
                }
            })
        }).disposed(by: disposeBag)
        
        topSelectButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            guard let wallet = WManager.loadWalletBy(info: self.walletInfo!) else { return }
            var info = [(name: String, balance: String, symbol: String)]()
            
            var balance = "-"
            if let value = WManager.walletBalanceList[wallet.address!] {
                balance = Tools.bigToString(value: value, decimal: wallet.decimal, 4)
            }
            if Preference.shared.navSelected == 0 {
                info.append((name: wallet.type == .eth ? "Ethereum" : "ICON", balance: balance, symbol: wallet.type.rawValue.uppercased()))
                
                if wallet.type == .eth {
                    let eth = wallet as! ETHWallet
                    
                    if let tokenList = eth.tokens {
                        for token in tokenList {
                            var tokenBalance = "-"
                            if let balances = WManager.tokenBalanceList[token.dependedAddress] {
                                if let bigBalance = balances[token.contractAddress] {
                                    tokenBalance = Tools.bigToString(value: bigBalance, decimal: wallet.decimal, 4)
                                }
                            }
                            
                            info.append((name: token.name, balance: tokenBalance, symbol: token.symbol))
                        }
                    }
                }
                
            } else {
                if wallet.type == .eth {
                    info.append((name: "Ethereum", balance: balance, symbol: "ETH"))
                    let eth = wallet as! ETHWallet
                    
                    if let tokenList = eth.tokens {
                        for token in tokenList {
                            var tokenBalance = "-"
                            if let balances = WManager.tokenBalanceList[token.dependedAddress] {
                                if let bigBalance = balances[token.contractAddress] {
                                    tokenBalance = Tools.bigToString(value: bigBalance, decimal: wallet.decimal, 4)
                                }
                            }
                            info.append((name: token.name, balance: tokenBalance, symbol: token.symbol))
                        }
                    }
                } else {
                    info.append((name: "ICON", balance: balance, symbol: "ICX"))
                }
            }
            
            let selectable = UIStoryboard(name: "ActionControls", bundle: nil).instantiateViewController(withIdentifier: "SelectableActionController") as! SelectableActionController
            selectable.present(from: self, title: "Detail.SelectCoin".localized, info: info)
            selectable.handler = ({ [unowned self] selectedIndex in
                
                if selectedIndex == 0 {
                    self.token = nil
                } else {
                    let eth = wallet as! ETHWallet
                    let token = eth.tokens![selectedIndex - 1]
                    self.token = token
                }
                self.initializeUI()
                self.loadExchanged()
            })
            
        }).disposed(by: disposeBag)
        
        etherButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let address = self.walletInfo?.address else {
                    return
                }
                
                let url = Ethereum.etherScanURL.appendingPathComponent(address)
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }).disposed(by: disposeBag)
        
        exchangeType = "usd"
        viewState = (0, 0)
        
        moreButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                
                let detail = UIStoryboard(name: "Menu", bundle: nil).instantiateViewController(withIdentifier: "WalletDetailMenu") as! WalletDetailMenuController
                detail.present(from: self, walletInfo: self.walletInfo!)
                detail.handler = { index in
                    let wallet = WManager.loadWalletBy(info: self.walletInfo!)!
                    switch index {
                    case 0:
                        // 지갑 이름 변경
                        let change = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "ChangeNameView") as! ChangeNameViewController
                        change.completionHandler = { [unowned self] (newName) in
                            do {
                                let result = try WManager.changeWalletName(former: wallet.alias!, newName: newName)
                                
                                if result {
                                    WManager.loadWalletList()
                                    guard let app = UIApplication.shared.delegate as? AppDelegate, let nav = app.window?.rootViewController as? UINavigationController, let main = nav.viewControllers[0] as? MainViewController else {
                                        return
                                    }
                                    main.loadWallets()
                                } else {
                                    let basic = Alert.Basic(message: "Error.CommonError".localized)
                                    self.present(basic, animated: true, completion: nil)
                                }
                            } catch {
                                Log.Debug("error: \(error)")
                                let message = "Error.CommonError".localized
                                let basic = Alert.Basic(message: message)
                                self.present(basic, animated: true, completion: nil)
                            }
                        }
                        self.present(change, animated: true, completion: nil)
                        break
                        
                    case 1:
                        // 토큰 관리
                        Alert.TokenManage(walletInfo: self.walletInfo!).show(self)
                        break
                        
                    case 2:
                        // 지갑 백업
                        let auth = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "WalletPasswordView") as! WalletPasswordViewController
                        auth.walletInfo = self.walletInfo!
                        auth.addConfirm(completion: { [unowned self] (isSuccess, privKey) in
                            if isSuccess {
                                let backup = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WalletBackupView") as! WalletBackupViewController
                                backup.privKey = privKey
                                backup.walletInfo = self.walletInfo
                                
                                self.present(backup, animated: true, completion: nil)
                            }
                        })
                        self.present(auth, animated: true, completion: nil)
                        
                    case 3:
                        // 지갑 비밀번호 변경
                        let change = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChangePasswordView") as! ChangePasswordViewController
                        change.walletInfo = self.walletInfo
                        self.present(change, animated: true, completion: nil)
                        break
                        
                    case 4:
                        // 지갑 삭제
                        let wallet = WManager.loadWalletBy(info: self.walletInfo!)!
                        guard let balance = WManager.walletBalanceList[self.walletInfo!.address] else {
                            Alert.Confirm(message: "Alert.Wallet.Remove.UnknownBalance".localized, cancel: "Common.No", confirm: "Common.Yes", handler: {
                                Alert.checkPassword(walletInfo: self.walletInfo!, action: { (isSuccess, _) in
                                    if !WManager.deleteWallet(wallet: wallet) {
                                        Alert.Basic(message: "Error.CommonError".localized).show(self)
                                    } else {
                                        let app = UIApplication.shared.delegate as! AppDelegate
                                        let nav = app.window!.rootViewController as! UINavigationController
                                        let main = nav.viewControllers[0] as! MainViewController
                                        main.loadWallets()
                                        self.navigationController?.popToRootViewController(animated: true)
                                    }
                                }).show(self)
                            }).show(self)
                            return
                        }
                        if balance == BigUInt(0) {
                            
                            Alert.Confirm(message: "Alert.Wallet.Remove".localized, cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: {
                                if !WManager.deleteWallet(wallet: wallet) {
                                    Alert.Basic(message: "Error.CommonError".localized).show(self)
                                } else {
                                    let app = UIApplication.shared.delegate as! AppDelegate
                                    let nav = app.window!.rootViewController as! UINavigationController
                                    let main = nav.viewControllers[0] as! MainViewController
                                    main.loadWallets()
                                    self.navigationController?.popToRootViewController(animated: true)
                                }
                            }).show(self)
                            return
                        } else {
                            Alert.Confirm(message: "Alert.Wallet.RemainBalance".localized, cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: {
                                Alert.checkPassword(walletInfo: self.walletInfo!, action: { (isSuccess, _) in
                                    if isSuccess {
                                        if !WManager.deleteWallet(wallet: wallet) {
                                            Alert.Basic(message: "Error.CommonError".localized).show(self)
                                        } else {
                                            let app = UIApplication.shared.delegate as! AppDelegate
                                            let nav = app.window!.rootViewController as! UINavigationController
                                            let main = nav.viewControllers[0] as! MainViewController
                                            main.loadWallets()
                                            self.navigationController?.popToRootViewController(animated: true)
                                        }
                                    }
                                }).show(self)
                            }).show(self)
                        }
                        break
                        
                    default:
                        break
                    }
                }
                
            }).disposed(by: disposeBag)
        
        infoButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                Alert.Basic(message: "Alert.ICX.Transfer.Info".localized).show(self)
            }).disposed(by: disposeBag)
        
        tableView.rx.didEndDragging.observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] _ in
            guard self.viewState.state == 0, self.viewState.type == 0, !self.isDragTriggered else { return }
            let height = self.tableView.contentSize.height
            let offset = self.tableView.contentOffset.y
            if offset + self.tableView.frame.height >= height && self.totalData >= self.step * 10 {
                self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
                self.step += 1
                self.fetchRecentTransaction()
            } else {
                Log.Debug("\(self.totalData), \(self.historyList.count)")
                guard self.totalData != self.historyList.count else {
                    self.tableView.contentInset = .zero
                    return
                }
                self.tableView.contentInset = UIEdgeInsetsMake(0, 0, -76, 0)
                
                if offset < -self.MAX_LIMIT {
                    self.isDragTriggered = true
                    self.tableView.contentInset = UIEdgeInsetsMake(78, 0, 0, 0)
                    self.refresh01.transform = CGAffineTransform.identity
                    Tools.rotateAnimation(inView: self.refresh01)
                    
                    Observable<Int>.timer(0.5, scheduler: MainScheduler.instance).debug("timer").subscribe(onNext: { _ in
                        self.requestBalance(true)
                        self.step = 1
                        self.totalData = 0
                        self.fetchRecentTransaction(true)
                    }).disposed(by: self.disposeBag)
                    
                    Log.Debug("Now Load!!")
                }
            }
        }).disposed(by: disposeBag)
        
        tableView.rx.didScroll.observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] in
            
            let offset = self.tableView.contentOffset.y
            
            self.etherTop.constant = 255 - offset
            
            if offset < 0 {
                self.upperConstraint.constant = offset
                
                guard !self.isDragTriggered else { return }
                
                let ratio = abs(CGFloat(offset / self.MAX_LIMIT))
                let alphaRatio = max(min(1 - ratio, 1), 0)
                let rotateRatio = min(2 * CGFloat.pi * ratio, 2 * CGFloat.pi)
                
                self.refresh02.alpha = alphaRatio
                self.refresh01.transform = CGAffineTransform(rotationAngle: rotateRatio)
                self.refresh02.transform = CGAffineTransform(rotationAngle: -rotateRatio)
            }
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        fullLoaderContainer.isHidden = true
        swapButton.isHidden = true
        
        navBar.layer.shadowOffset = CGSize(width: 0, height: 2)
        navBar.layer.shadowRadius = 6 / 2
        navBar.layer.shadowColor = UIColor(0, 0, 0, 0.1).cgColor
        navBar.layer.shadowOpacity = 0.0
        
        topSelectContainer.corner(topSelectContainer.frame.height / 2)
        exchangeSelectContainer.corner(exchangeSelectContainer.frame.height / 2)
        
        swapButton.setTitle("Swap.Swap".localized, for: .normal)
        outButton.setTitle("Detail.Filter.Transfer".localized, for: .normal)
        inButton.setTitle("Detail.Filter.Deposit".localized, for: .normal)
        
        infoLabel.text = "Detail.TxHistory".localized
        
        etherTransLabel.text = "Detail.ETHTransactions".localized
        let attr = NSAttributedString(string: "Etherscan", attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .regular), .underlineStyle: NSUnderlineStyle.styleSingle.rawValue])
        etherScan.attributedText = attr
        
        if let wallet = self.walletInfo {
            if let token = self.token {
                topSelectLabel.text = token.name
                unitLabel.text = token.symbol
                etherContainer.isHidden = false
                
                if wallet.type == .eth && token.symbol.lowercased() == "icx" {
                    swapButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
                        if let balances = WManager.tokenBalanceList[token.dependedAddress], let balance = balances[token.contractAddress], balance != BigUInt(0) {
                            
                            let ethWallet = WManager.loadWalletBy(info: wallet) as! ETHWallet
                            
                            guard let walletBalance = ethWallet.balance, walletBalance != BigUInt(0) else {
                                Alert.Basic(message: "Error.Swap.NoETH".localized).show(self)
                                return
                            }
                            
                            Alert.checkPassword(walletInfo: self.walletInfo!, action: { (isSuccess, privateKey) in
                                
                                SwapManager.sharedInstance.walletInfo = self.walletInfo
                                SwapManager.sharedInstance.privateKey = privateKey
                                
                                if let swapAddress = token.swapAddress, WManager.walletInfoList.filter({ $0.address == swapAddress }).first != nil {
                                    let swap = UIStoryboard(name: "Swap", bundle: nil).instantiateViewController(withIdentifier: "SwapStep2") as! SwapStep2ViewController
                                    self.present(swap, animated: true, completion: nil)
                                } else {
                                    let swap = UIStoryboard(name: "Swap", bundle: nil).instantiateInitialViewController() as! SwapStepViewController
                                    self.present(swap, animated: true, completion: nil)
                                }
                                
                            }).show(self)
                            
                        } else {
                            Alert.Basic(message: "Error.Swap.NoICX".localized).show(self)
                        }
                    }).disposed(by: disposeBag)
                    
                    self.swapButton.isHidden = false
                }
            } else {
                if wallet.type == .icx {
                    topSelectLabel.text = "ICON"
                    unitLabel.text = "ICX"
                    etherContainer.isHidden = true
                } else if wallet.type == .eth {
                    topSelectLabel.text = "Ethereum"
                    unitLabel.text = "ETH"
                    etherContainer.isHidden = false
                }
            }
        } else {
            if let token = self.token {
                topSelectLabel.text = token.name
                unitLabel.text = token.symbol
                etherContainer.isHidden = false
            }
        }
    }
    
    func loadData() {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 1))
        if viewState.state == 0 {
            tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
            
            if viewState.type == 0 {
                filteredList = historyList
                
                if let list = filteredList, list.count != 0, list.count < totalData {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "WalletDetailLoadCell") as! WalletDetailLoadCell
                    cell.backgroundColor = UIColor.white
                    Tools.rotateAnimation(inView: cell.indicator)
                    tableView.tableFooterView = cell
                }
            } else if viewState.type == 1 {
                filteredList = historyList.filter { $0.fromAddr == walletInfo!.address }
            } else {
                filteredList = historyList.filter { $0.fromAddr != walletInfo!.address }
            }
        } else {
            
            switch viewState.type {
            case 0:
                holdList = Transaction.transactionList(address: walletInfo!.address)
                
            case 1:
                holdList = Transaction.transactionList(address: walletInfo!.address)?.filter({ $0.from == walletInfo!.address })
                
            case 2:
                holdList = Transaction.transactionList(address: walletInfo!.address)?.filter({ $0.from != walletInfo!.address })
                
            default:
                holdList = Transaction.transactionList(address: walletInfo!.address)
                
            }
        }
        self.tableView.reloadData()
    }
    
    func requestData() {

        self.requestBalance()
        
        fetchRecentTransaction()
    }
    
    func requestBalance(_ dragged: Bool = false) {
        guard let info = self.walletInfo else {
            return
        }
        guard let wallet = WManager.loadWalletBy(info: info) else { return }
        titleLabel.text = wallet.alias
        
        if let token = self.token {
            if dragged {
                
                DispatchQueue.global(qos: .default).async {
                    if let balance = Ethereum.requestTokenBalance(token: token) {
                        DispatchQueue.main.async { [unowned self] in
                            let balance = Tools.bigToString(value: balance, decimal: token.defaultDecimal, 4)
                            let attr = NSAttributedString(string: balance, attributes: [.kern: -2.0])
                            self.balanceLabel.attributedText = attr
                            self.loadExchanged()
                            self.refresh01.layer.removeAllAnimations()
                            self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
                            self.isDragTriggered = false
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.balanceLabel.text = NSAttributedString(string: "-").string
                            self.refresh01.layer.removeAllAnimations()
                            self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
                            self.isDragTriggered = false
                        }
                    }
                }
            } else {
                if let balances = WManager.tokenBalanceList[wallet.address!], let balance = balances[token.contractAddress] {
                    Log.Debug("balace \(balances)")
                    headerLoading.isHidden = true
                    balanceLabel.isHidden = false
                    let balance = Tools.bigToString(value: balance, decimal: token.defaultDecimal, 4)
                    let attr = NSAttributedString(string: balance, attributes: [.kern: -2.0])
                    self.balanceLabel.attributedText = attr
                } else {
                    self.headerLoading.isHidden = false
                    self.balanceLabel.isHidden = true
                    
                    DispatchQueue.global(qos: .default).async {
                        if let balance = Ethereum.requestTokenBalance(token: token) {
                            DispatchQueue.main.async { [unowned self] in
                                self.headerLoading.isHidden = true
                                self.balanceLabel.isHidden = false
                                let balance = Tools.bigToString(value: balance, decimal: token.defaultDecimal, 4)
                                let attr = NSAttributedString(string: balance, attributes: [.kern: -2.0])
                                self.balanceLabel.attributedText = attr
                                self.loadExchanged()
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.headerLoading.isHidden = true
                                self.balanceLabel.isHidden = false
                                self.balanceLabel.text = NSAttributedString(string: "-").string
                            }
                        }
                    }
                }
            }
        } else {
            if dragged {
                WManager.getBalance(wallet: wallet) { [weak self] (isSuccess) in
                    if let value = WManager.walletBalanceList[wallet.address!] {
                        let balance = Tools.bigToString(value: value, decimal: wallet.decimal, 4)
                        let attr = NSAttributedString(string: balance, attributes: [.kern: -2.0])
                        self?.balanceLabel.attributedText = attr
                        self?.loadExchanged()
                    } else {
                        self?.balanceLabel.text = NSAttributedString(string: "-").string
                    }
                    self?.refresh01.layer.removeAllAnimations()
                    self?.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
                    self?.isDragTriggered = false
                }
            } else {
                if let value = WManager.walletBalanceList[wallet.address!] {
                    headerLoading.isHidden = true
                    balanceLabel.isHidden = false
                    let balance = Tools.bigToString(value: value, decimal: wallet.decimal, 4)
                    let attr = NSAttributedString(string: balance, attributes: [.kern: -2.0])
                    self.balanceLabel.attributedText = attr
                    self.loadExchanged()
                } else {
                    headerLoading.isHidden = false
                    balanceLabel.isHidden = true
                    WManager.getBalance(wallet: wallet) { [weak self] (isSuccess) in
                        self?.headerLoading.isHidden = true
                        self?.balanceLabel.isHidden = false
                        if let value = WManager.walletBalanceList[wallet.address!] {
                            let balance = Tools.bigToString(value: value, decimal: wallet.decimal, 4)
                            let attr = NSAttributedString(string: balance, attributes: [.kern: -2.0])
                            self?.balanceLabel.attributedText = attr
                            self?.loadExchanged()
                        } else {
                            self?.balanceLabel.text = NSAttributedString(string: "-").string
                        }
                    }
                }
            }
        }
    }
    
    func fetchRecentTransaction(_ reset: Bool = false) {
        guard let info = self.walletInfo else { return }
        guard let wallet = WManager.loadWalletBy(info: info), let address = wallet.address else { return }
        guard wallet.type == .icx else { return }
        if !isLoaded { isLoaded = false }
        
        if totalData != 0 {
            guard let list = filteredList, totalData > list.count else { return }
        }
        
        if reset { historyList.removeAll() }
        
        var tracker: Tracker {
            switch Config.host {
            case .main:
                return Tracker.main()
                
            case .dev:
                return Tracker.dev()
                
            case .local:
                return Tracker.local()
            }
        }
        
        var type: Tracker.TXType {
            return address.hasPrefix("hx") ? .icxTransfer : .tokenTransfer
        }
        
        if let response = tracker.transactionList(address: address, page: self.step, txType: type) {
            guard let listSize = response["listSize"] as? Int else { return }
            guard let list = response["data"] as? [[String: Any]] else { return }
            
            for txDic in list {
                let tx = Tracker.TxList(dic: txDic)
                self.historyList.append(tx)
                Transaction.updateTransactionCompleted(txHash: tx.txHash)
            }
            
            self.totalData = listSize
        }
        self.isLoaded = true
        
        self.loadData()
    }
    
    func loadExchanged() {
        exchangeSelectLabel.text = exchangeType.uppercased()
        
        
        if let token = self.token {
            guard let balances = WManager.tokenBalanceList[token.dependedAddress], let balance = balances[token.contractAddress] else {
                return
            }
            
            guard token.symbol.lowercased() != exchangeType, let exchanged = Tools.balanceToExchange(balance, from: token.symbol.lowercased(), to: exchangeType, belowDecimal: exchangeType == "usd" ? 2 : 4, decimal: token.decimal) else {
                exchangeLabel.text = Tools.bigToString(value: balance, decimal: token.defaultDecimal, exchangeType == "usd" ? 2 : 4).currencySeparated()
                return
            }
            exchangeLabel.text = exchanged.currencySeparated()
        } else {
            guard let wallet = WManager.loadWalletBy(info: self.walletInfo!), let balance = wallet.balance else {
                return
            }
            guard exchangeType != wallet.type.rawValue, let exchanged = Tools.balanceToExchange(balance, from: wallet.type.rawValue, to: exchangeType, belowDecimal: exchangeType == "usd" ? 2 : 4, decimal: wallet.decimal) else {
                exchangeLabel.text = Tools.bigToString(value: balance, decimal: wallet.decimal, exchangeType == "usd" ? 2 : 4).currencySeparated()
                return
            }
            
            exchangeLabel.text = exchanged.currencySeparated()
        }
    }
}

extension WalletDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewState.state == 0 {
            guard let history = filteredList, history.count != 0 else {
                return 1
            }
            
            //            return viewState.type == 0 ? (history.count >= 10 ? history.count + 1 : history.count) : history.count
            return history.count
        } else {
            guard let hold = holdList else {
                return 1
            }
            
            return hold.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewState.state == 0 {
            guard let list = filteredList, list.count != 0 else {
                var height = tableView.frame.height
                if let headerView = tableView.tableHeaderView {
                    height = height - headerView.frame.height
                }
                
                return height
            }
        } else {
            guard let list = holdList, list.count != 0 else {
                var height = tableView.frame.height
                if let headerView = tableView.tableHeaderView {
                    height = height - headerView.frame.height
                }
                
                return height
            }
        }
        
        return 76
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if viewState.state == 0 {
            guard let list = filteredList, list.count != 0 else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "WalletDetailNoCell", for: indexPath) as! WalletDetailNoCell
                cell.title.text = "Detail.NoTxHistory".localized
                return cell
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "WalletDetailCell", for: indexPath) as! WalletDetailCell
            let history = list[indexPath.row]
            
            let attrString = NSAttributedString(string: history.txHash, attributes: [.underlineStyle: NSUnderlineStyle.styleSingle.rawValue])
            
            cell.txTitleLabel.attributedText = attrString
            
            if history.txType == "0" {
                
                if history.fromAddr == walletInfo!.address {
                    cell.amountLabel.text = "-" + history.amount
                    cell.amountLabel.textColor = UIColor(230, 92, 103)
                    cell.typeLabel.textColor = UIColor(230, 92, 103)
                    cell.txDateLabel.textColor = UIColor(230, 92, 103)
                } else {
                    cell.amountLabel.text = "+" + history.amount
                    cell.amountLabel.textColor = UIColor(74, 144, 226)
                    cell.typeLabel.textColor = UIColor(74, 144, 226)
                    cell.txDateLabel.textColor = UIColor(74, 144, 226)
                }
            }
            cell.typeLabel.text = "ICX"
            
            let array = history.createDate.components(separatedBy: ".")
            let dateString = array[0].replacingOccurrences(of: "T", with: " ")
            if array.count > 1 {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                let date = dateFormatter.date(from: dateString)
                
                cell.txDateLabel.text = date?.toString(format: "yyyy-MM-dd HH:mm:ss")
            }
            return cell
        } else {
            guard let list = holdList, list.count != 0 else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "WalletDetailNoCell", for: indexPath) as! WalletDetailNoCell
                cell.title.text = "Detail.NoTxHistory".localized
                return cell
            }
            
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "WalletDetailCell", for: indexPath) as! WalletDetailCell
            let transaction = list[indexPath.row]
            
            let attrString = NSAttributedString(string: transaction.txHash, attributes: [.underlineStyle: NSUnderlineStyle.styleSingle.rawValue])
            
            cell.txTitleLabel.attributedText = attrString
            
            cell.amountLabel.textColor = UIColor(38, 38, 38)
            cell.typeLabel.text = "ICX"
            cell.typeLabel.textColor = UIColor(38, 38, 38)
            cell.txDateLabel.text = "Detail.Filter.Pending".localized
            cell.txDateLabel.textColor = UIColor(38, 38, 38)
            cell.amountLabel.text = transaction.value
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if viewState.state == 0 {
            guard let list = filteredList, list.count != 0 else {
                return
            }
            
            let history = list[indexPath.row]
            Alert.transactionDetail(txHash: history.txHash).show(self)
        } else if viewState.state == 1 {
            guard let list = holdList, list.count != 0 else {
                return
            }
            
            let pending = list[indexPath.row]
            Alert.transactionDetail(txHash: pending.txHash).show(self)
        }
    }
}

extension WalletDetailViewController: ViewOptionDelegate {
    func viewOptionfilterSelected(state: (Int, Int)) {
        viewState = state
        
        self.loadData()
    }
}
