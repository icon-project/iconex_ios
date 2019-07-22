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
import ICONKit
import Web3swift

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
    
    var walletInfo: BaseWalletConvertible!
    var token: Token?
    var historyList = [Tracker.TxList]()
    var filteredList: [Tracker.TxList]?
    var holdList: [TransactionModel]?
    
    var step: Int = 1
    private var totalData: Int = 0
    private var exchangeItem: [String] {
        if self.walletInfo.address.hasPrefix("hx") {
            return ["USD", "BTC", "ETH"]
        } else {
            return ["USD", "BTC", "ICX"]
        }
    }
    var isLoaded: Bool = false {
        willSet {
            if !newValue {
                tableView.isScrollEnabled = false
                fullLoaderContainer.isHidden = false
                Tool.rotateAnimation(inView: fullLoaderImage)
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
        closeButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
        
        outButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            guard let wallet = WManager.loadWalletBy(info: self.walletInfo!) else { return }
            if let token = self.token {
                guard let balances = Balance.tokenBalanceList[token.dependedAddress.add0xPrefix()], let balance = balances[token.contractAddress], balance != BigUInt(0) else  {
                    
                    let alert = UIStoryboard(name: "Alert", bundle: nil).instantiateInitialViewController() as! BasicActionViewController
                    alert.message = "Error.Detail.InsufficientBalance".localized
                    self.present(alert, animated: true, completion: nil)
                    
                    return
                }
                
                guard let walletBalance = Balance.walletBalanceList[wallet.address!], walletBalance != BigUInt(0) else {
                    let errMsg = wallet.type == .icx ? "Error.Transfer.InsufficientFee.ICX".localized : "Error.Transfer.InsufficientFee.ETH".localized
                    Alert.Basic(message: errMsg).show(self)
                    return
                }
            } else {
                guard let balance = Balance.walletBalanceList[wallet.address!], balance != BigUInt(0) else {
                    Alert.Basic(message: "Error.Detail.InsufficientBalance".localized).show(self)
                    return
                }
            }
            
            let pwdAlert = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "WalletPasswordView") as! WalletPasswordViewController
            pwdAlert.walletInfo = self.walletInfo
            
            pwdAlert.addConfirm(completion: { (isSuccess, privKey) in
                if isSuccess {
                    let prvKey = PrivateKey(hex: privKey.hexToData()!)
                    
                    if self.walletInfo!.type == .icx {
                        let sendView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ICXSendView") as! ICXSendViewController
                        sendView.walletInfo = self.walletInfo
                        if let token = self.token {
                            sendView.token = token
                        }
                        sendView.privateKey = prvKey
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
        
        inButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: {[unowned self] in
                Alert.PrivateInfo(walletInfo: self.walletInfo).show(self)
            }).disposed(by: disposeBag)
        
        filterButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            let viewOption = UIStoryboard(name: "ActionControls", bundle: nil).instantiateViewController(withIdentifier: "ViewOption") as! ViewOptionViewController
            viewOption.present(from: self, title: "Detail.ViewOption".localized, state: self.viewState)
            viewOption.delegate = self
        }).disposed(by: disposeBag)
        
        exchangeSelectButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            let selectable = UIStoryboard(name: "ActionControls", bundle: nil).instantiateViewController(withIdentifier: "SelectableActionController") as! SelectableActionController
            selectable.present(from: self, title: "Detail.Select.Unit".localized, items: self.exchangeItem)
            selectable.handler = ({ [unowned self] (selectedIndex) in
                self.exchangeType = self.exchangeItem[selectedIndex].lowercased()
            })
        }).disposed(by: disposeBag)
        
        topSelectButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            guard let wallet = WManager.loadWalletBy(info: self.walletInfo!) else { return }
            var info = [(name: String, balance: String, symbol: String)]()
            
            var balance = "-"
            if let value = Balance.walletBalanceList[wallet.address!] {
                balance = Tool.bigToString(value: value, decimal: wallet.decimal, 4)
            }
            
            info.append((name: wallet.type == .eth ? "Ethereum" : "ICON", balance: balance, symbol: wallet.type.rawValue.uppercased()))
            
            if let tokenList = wallet.tokens {
                for token in tokenList {
                    var tokenBalance = "-"
                    if let balances = Balance.tokenBalanceList[token.dependedAddress.add0xPrefix()] {
                        if let bigBalance = balances[token.contractAddress] {
                            tokenBalance = Tool.bigToString(value: bigBalance, decimal: token.decimal, 4)
                        }
                    }
                    
                    info.append((name: token.name, balance: tokenBalance, symbol: token.symbol))
                }
            }

            let selectable = UIStoryboard(name: "ActionControls", bundle: nil).instantiateViewController(withIdentifier: "SelectableActionController") as! SelectableActionController
            selectable.present(from: self, title: "Detail.SelectCoin".localized, info: info)
            selectable.handler = ({ [unowned self] selectedIndex in
                
                if selectedIndex == 0 {
                    self.token = nil
                } else {
                    let token = wallet.tokens![selectedIndex - 1]
                    self.token = token
                }
                self.initializeUI()
                self.requestBalance()
                self.loadExchanged()
                self.fetchRecentTransaction(true)
            })
            
        }).disposed(by: disposeBag)
        
        etherButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let address = self.walletInfo?.address else {
                    return
                }
                
                let url = Ethereum.etherScanURL.appendingPathComponent(address)
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }).disposed(by: disposeBag)
        
        exchangeType = "usd"
        viewState = (0, 0)
        
        moreButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                
                let detail = UIStoryboard(name: "Menu", bundle: nil).instantiateViewController(withIdentifier: "WalletDetailMenu") as! WalletDetailMenuController
                detail.present(from: self, walletInfo: self.walletInfo!)
                detail.handler = { index in
                    let wallet = WManager.loadWalletBy(info: self.walletInfo!)!
                    switch index {
                    case 0:
                        // 지갑 이름 변경
                        let change = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "ChangeNameView") as! ChangeNameViewController
                        change.formerName = wallet.alias!
                        change.completionHandler = { [unowned self] (newName) in
                            do {
                                let result = try WManager.changeWalletName(former: wallet.alias!, newName: newName)
                                
                                if result {
                                    WManager.loadWalletList()
                                    guard let app = UIApplication.shared.delegate as? AppDelegate, let nav = app.window?.rootViewController as? UINavigationController, let main = nav.viewControllers[0] as? MainViewController else {
                                        return
                                    }
                                    main.loadWallets()
                                    
                                    self.titleLabel.text = newName
                                } else {
                                    let basic = Alert.Basic(message: "Error.CommonError".localized)
                                    self.present(basic, animated: true, completion: nil)
                                }
                            } catch {
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
                        guard let balance = Balance.walletBalanceList[self.walletInfo!.address] else {
                            Alert.Confirm(message: "Alert.Wallet.Remove.UnknownBalance".localized, cancel: "Common.No", confirm: "Common.Yes", handler: {
                                Alert.checkPassword(walletInfo: self.walletInfo!, action: { (isSuccess, _) in
                                    if !WManager.deleteWallet(wallet: wallet) {
                                        Alert.Basic(message: "Error.CommonError".localized).show(self)
                                    } else {
                                        let app = UIApplication.shared.delegate as! AppDelegate
                                        let nav = app.window!.rootViewController as! UINavigationController
                                        
                                        if WManager.walletInfoList.count == 0 {
                                            let welcome = UIStoryboard(name: "Loading", bundle: nil).instantiateViewController(withIdentifier: "WelcomeView")
                                            app.window?.rootViewController = welcome
                                        } else {
                                            let main = nav.viewControllers[0] as! MainViewController
                                            main.currentIndex = 0
                                            main.loadWallets()
                                            self.navigationController?.popToRootViewController(animated: true)
                                        }
                                    }
                                }).show(self)
                            }).show(self)
                            return
                        }
                        if balance == BigUInt(0) && Balance.tokenBalanceList[self.walletInfo!.address]?.filter({ $0.value != BigUInt(0) }).first == nil {
                            
                            Alert.Confirm(message: "Alert.Wallet.Remove".localized, cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: {
                                if !WManager.deleteWallet(wallet: wallet) {
                                    Alert.Basic(message: "Error.CommonError".localized).show(self)
                                } else {
                                    let app = UIApplication.shared.delegate as! AppDelegate
                                    let nav = app.window!.rootViewController as! UINavigationController
                                    
                                    if WManager.walletInfoList.count == 0 {
                                        let welcome = UIStoryboard(name: "Loading", bundle: nil).instantiateViewController(withIdentifier: "WelcomeView")
                                        app.window?.rootViewController = welcome
                                    } else {
                                        let main = nav.viewControllers[0] as! MainViewController
                                        main.currentIndex = 0
                                        main.loadWallets()
                                        self.navigationController?.popToRootViewController(animated: true)
                                    }
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
                                            
                                            if WManager.walletInfoList.count == 0 {
                                                let welcome = UIStoryboard(name: "Loading", bundle: nil).instantiateViewController(withIdentifier: "WelcomeView")
                                                app.window?.rootViewController = welcome
                                            } else {
                                                let main = nav.viewControllers[0] as! MainViewController
                                                main.currentIndex = 0
                                                main.loadWallets()
                                                self.navigationController?.popToRootViewController(animated: true)
                                            }
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
        
        infoButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                Alert.Basic(message: "Alert.ICX.Transfer.Info".localized).show(self)
            }).disposed(by: disposeBag)
        
        tableView.rx.didEndDragging.observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] _ in
            guard self.viewState.state == 0, self.viewState.type == 0, !self.isDragTriggered else { return }
            let height = self.tableView.contentSize.height
            let offset = self.tableView.contentOffset.y
            if offset + self.tableView.frame.height >= height && self.totalData >= self.step * 10 {
                self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                self.step += 1
                Observable<Int>.timer(0.5, scheduler: MainScheduler.instance).debug("timer").subscribe(onNext: { _ in
                    self.fetchRecentTransaction(true)
                }).disposed(by: self.disposeBag)
            } else {
                self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -76, right: 0)
                
                if offset < -self.MAX_LIMIT {
                    self.isDragTriggered = true
                    self.tableView.contentInset = UIEdgeInsets(top: 78, left: 0, bottom: 0, right: 0)
                    self.refresh01.transform = CGAffineTransform.identity
                    Tool.rotateAnimation(inView: self.refresh01)
                    
                    Observable<Int>.timer(0.5, scheduler: MainScheduler.instance).debug("timer").subscribe(onNext: { _ in
                        self.requestBalance(true)
                        self.step = 1
                        self.totalData = 0
                        self.fetchRecentTransaction(true)
                    }).disposed(by: self.disposeBag)
                    
                    Log("Now Load!!")
                } else if self.totalData < self.step * 10 {
                    self.tableView.contentInset = UIEdgeInsets.zero
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
        
        navBar.layer.shadowOffset = CGSize(width: 0, height: 2)
        navBar.layer.shadowRadius = 6 / 2
        navBar.layer.shadowColor = UIColor(0, 0, 0, 0.1).cgColor
        navBar.layer.shadowOpacity = 0.0
        
        topSelectContainer.corner(topSelectContainer.frame.height / 2)
        exchangeSelectContainer.corner(exchangeSelectContainer.frame.height / 2)
        
        outButton.setTitle("Detail.Filter.Transfer".localized, for: .normal)
        inButton.setTitle("Detail.Filter.Deposit".localized, for: .normal)
        
        infoLabel.text = "Detail.TxHistory".localized
        
        etherTransLabel.text = "Detail.ETHTransactions".localized
        let attr = NSAttributedString(string: "Etherscan", attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .regular), .underlineStyle: NSUnderlineStyle.single.rawValue])
        etherScan.attributedText = attr
        
        if let wallet = self.walletInfo {
            if let token = self.token {
                topSelectLabel.text = token.name
                unitLabel.text = token.symbol
                
                if wallet.type == .eth {
                    if token.symbol.lowercased() == "icx" {
                        etherContainer.isHidden = false
                    }
                } else {
                    etherContainer.isHidden = true
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
            
            if viewState.type == 0 {
                filteredList = historyList
                
                if let list = filteredList, list.count != 0, list.count < totalData {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "WalletDetailLoadCell") as! WalletDetailLoadCell
                    cell.backgroundColor = UIColor.white
                    Tool.rotateAnimation(inView: cell.indicator)
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
                holdList = Transactions.transactionList(address: walletInfo!.address)
                
            case 1:
                holdList = Transactions.transactionList(address: walletInfo!.address)?.filter({ $0.from == walletInfo!.address })
                
            case 2:
                holdList = Transactions.transactionList(address: walletInfo!.address)?.filter({ $0.from != walletInfo!.address })
                
            default:
                holdList = Transactions.transactionList(address: walletInfo!.address)
                
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
                    
                    var result: BigUInt?
                    
                    if wallet.type == .eth {
                        result = Ethereum.requestTokenBalance(token: token)
                    } else {
                        result = WManager.getIRCTokenBalance(tokenInfo: token)
                    }
                    
                    DispatchQueue.main.async {
                        if let balance = result {
                            let stringBalance = Tool.bigToString(value: balance, decimal: token.defaultDecimal, 4)
                            let attr = NSAttributedString(string: stringBalance.currencySeparated(), attributes: [.kern: -2.0])
                            self.balanceLabel.attributedText = attr
                            self.loadExchanged()
                            self.refresh01.layer.removeAllAnimations()
                            self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
                            self.isDragTriggered = false
                        } else {
                            self.balanceLabel.text = NSAttributedString(string: "-").string
                            self.refresh01.layer.removeAllAnimations()
                            self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
                            self.isDragTriggered = false
                        }
                    }
                }
            } else {
                if let balances = Balance.tokenBalanceList[wallet.address!.add0xPrefix()], let balance = balances[token.contractAddress] {
                    Log("balace \(balances)")
                    headerLoading.isHidden = true
                    balanceLabel.isHidden = false
                    let balance = Tool.bigToString(value: balance, decimal: token.defaultDecimal, 4)
                    let attr = NSAttributedString(string: balance.currencySeparated(), attributes: [.kern: -2.0])
                    self.balanceLabel.attributedText = attr
                } else {
                    self.headerLoading.isHidden = false
                    self.balanceLabel.isHidden = true
                    
                    DispatchQueue.global(qos: .default).async {
                        if let balance = Ethereum.requestTokenBalance(token: token) {
                            DispatchQueue.main.async { [unowned self] in
                                self.headerLoading.isHidden = true
                                self.balanceLabel.isHidden = false
                                let balance = Tool.bigToString(value: balance, decimal: token.defaultDecimal, 4)
                                let attr = NSAttributedString(string: balance.currencySeparated(), attributes: [.kern: -2.0])
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
                Balance.getBalance(wallet: wallet) { [weak self] (isSuccess) in
                    if let value = Balance.walletBalanceList[wallet.address!] {
                        let balance = Tool.bigToString(value: value, decimal: wallet.decimal, 4)
                        let attr = NSAttributedString(string: balance.currencySeparated(), attributes: [.kern: -2.0])
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
                if let value = Balance.walletBalanceList[wallet.address!] {
                    headerLoading.isHidden = true
                    balanceLabel.isHidden = false
                    let balance = Tool.bigToString(value: value, decimal: wallet.decimal, 4)
                    let attr = NSAttributedString(string: balance.currencySeparated(), attributes: [.kern: -2.0])
                    self.balanceLabel.attributedText = attr
                    self.loadExchanged()
                } else {
                    headerLoading.isHidden = false
                    balanceLabel.isHidden = true
                    Balance.getBalance(wallet: wallet) { [weak self] (isSuccess) in
                        self?.headerLoading.isHidden = true
                        self?.balanceLabel.isHidden = false
                        if let value = Balance.walletBalanceList[wallet.address!] {
                            let balance = Tool.bigToString(value: value, decimal: wallet.decimal, 4)
                            let attr = NSAttributedString(string: balance.currencySeparated(), attributes: [.kern: -2.0])
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
        
        if reset {
            filteredList = nil
            self.totalData = 0
        }
        
        if totalData != 0 {
            guard let filtered = filteredList, totalData > filtered.count else { return }
        }
        
        var tracker: Tracker {
            switch Config.host {
            case .main:
                return Tracker.main()
                
            case .dev:
                return Tracker.dev()
                
            case .yeouido:
                return Tracker.local()
            }
        }
        
        var txList = Set(historyList)
        if let token = self.token {
            if let response = tracker.tokenTxList(address: address, contractAddress: token.contractAddress, page: self.step) {
                if let listSize = response["listSize"] as? Int, let list = response["data"] as? [[String: Any]] {
                    for txDic in list {
                        let tx = Tracker.TxList(dic: txDic)
                        txList.insert(tx)
                        Transactions.updateTransactionCompleted(txHash: tx.txHash)
                    }
                    
                    self.totalData = listSize
                }
            }
        } else {
            if let response = tracker.transactionList(address: address, page: self.step, txType: .icxTransfer) {
                if let listSize = response["listSize"] as? Int, let list = response["data"] as? [[String: Any]] {
                    for txDic in list {
                        let tx = Tracker.TxList(dic: txDic)
                        txList.insert(tx)
                        Transactions.updateTransactionCompleted(txHash: tx.txHash)
                    }
                    
                    self.totalData = listSize
                }
            }
        }
        self.historyList.removeAll()
        
        let list = Array(txList).sorted { self.token == nil ? $0.createDate > $1.createDate : $0.age > $1.age }
        
        self.historyList.append(contentsOf: list)
        
        self.isLoaded = true
        self.loadData()
    }
    
    func loadExchanged() {
        exchangeSelectLabel.text = exchangeType.uppercased()
        
        if let token = self.token {
            guard let balances = Balance.tokenBalanceList[token.dependedAddress.add0xPrefix()], let balance = balances[token.contractAddress] else {
                return
            }
            
            guard token.symbol.lowercased() != exchangeType, let exchanged = Tool.balanceToExchange(balance, from: token.symbol.lowercased(), to: exchangeType, belowDecimal: exchangeType == "usd" ? 2 : 4, decimal: token.decimal) else {
                exchangeLabel.text = "-"
                return
            }
            exchangeLabel.text = exchanged.currencySeparated()
        } else {
            guard let wallet = WManager.loadWalletBy(info: self.walletInfo!), let balance = Balance.walletBalanceList[wallet.address!] else {
                return
            }
            guard exchangeType != wallet.type.rawValue, let exchanged = Tool.balanceToExchange(balance, from: wallet.type.rawValue, to: exchangeType, belowDecimal: exchangeType == "usd" ? 2 : 4, decimal: wallet.decimal) else {
                exchangeLabel.text = "-"
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
            
            let attrString = NSAttributedString(string: history.txHash, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
            
            cell.txTitleLabel.attributedText = attrString
            
            if history.state == 1 {
                if history.fromAddr == walletInfo!.address {
                    cell.amountLabel.textColor = UIColor(230, 92, 103)
                    cell.typeLabel.textColor = UIColor(230, 92, 103)
                    cell.txDateLabel.textColor = UIColor(230, 92, 103)
                } else {
                    cell.amountLabel.textColor = UIColor(74, 144, 226)
                    cell.typeLabel.textColor = UIColor(74, 144, 226)
                    cell.txDateLabel.textColor = UIColor(74, 144, 226)
                }
            } else {
                cell.amountLabel.textColor = UIColor.lightTheme.text.disabled
                cell.typeLabel.textColor = UIColor.lightTheme.text.disabled
                cell.txDateLabel.textColor = UIColor.lightTheme.text.disabled
            }
            
            if let token = self.token {
                cell.amountLabel.text = (history.fromAddr == walletInfo!.address ? "-" : "+") + history.quantity
                cell.typeLabel.text = token.symbol.uppercased()
                
                
                let array = history.age.components(separatedBy: ".")
                let dateString = array[0].replacingOccurrences(of: "T", with: " ")
                if array.count > 1 {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                    let date = dateFormatter.date(from: dateString)
                    
                    cell.txDateLabel.text = date?.toString(format: "yyyy-MM-dd HH:mm:ss")
                }
            } else {
                cell.amountLabel.text = (history.fromAddr == walletInfo!.address ? "-" : "+") + history.amount
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
            
            let attrString = NSAttributedString(string: transaction.txHash, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
            
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
