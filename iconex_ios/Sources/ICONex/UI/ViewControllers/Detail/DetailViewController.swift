//
//  DetailViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 28/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ICONKit
import BigInt

public enum DetailType {
    case icx, irc, eth, erc
}

public enum TxFilter {
    case all, send, deposit
}

class DetailViewController: BaseViewController, Floatable {
    var selectedWallet: ICXWallet?
    
    @IBOutlet weak var navBar: IXNavigationView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var coinTypeLabel: UILabel!
    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet weak var dropDownButton: UIButton!
    
    @IBOutlet weak var balanceSpinner: UIActivityIndicatorView!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var currencyPriceLabel: UILabel!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var toggleImageView: UIImageView!
    @IBOutlet weak var toggleButton: UIButton!
    
    // stake info box
    @IBOutlet weak var stakeBoxView: UIView!
    @IBOutlet weak var totalBalanceTitle: UILabel!
    @IBOutlet weak var liquidTitle: UILabel!
    @IBOutlet weak var stakedTitle: UILabel!
    
    @IBOutlet weak var totalBalanceLabel: UILabel!
    @IBOutlet weak var liquidLabel: UILabel!
    @IBOutlet weak var stakedLabel: UILabel!
    
    var walletInfo: BaseWalletConvertible? = nil {
        willSet {
            guard let wallet = newValue else { return }
            if let icx = wallet as? ICXWallet {
                selectedWallet = icx
            }
        }
    }
    
    var tokenInfo: Token? = nil
    
    var tracker: Tracker {
        switch Config.host {
        case .main:
            return Tracker.main()
            
        case .euljiro:
            return Tracker.euljiro()
            
        case .yeouido:
            return Tracker.yeouido()
            #if DEBUG
        case .localTest:
            return Tracker.localTest()
            #endif
        }
    }
    
    private var txList = [Tracker.TxList]()
    private var ethTxList = [TransactionModel]()
    
    private var pageIndex: Int = 1
    var detailType: DetailType = .icx
    private var filter: TxFilter = .all
    
    let ixSectionHeader = IXSectionHeader(frame: CGRect.init(x: 0, y: 0, width: .max, height: 36))
    
    var etherButtonView = UIView()
    var etherscanButton = UIButton()
    
    var floater: Floater = Floater(type: .wallet)
    
    private var detailViewModel: DetailViewModel = DetailViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.layoutIfNeeded()
        self.detailViewModel.filter.onNext(.all)
        
        if let token = self.tokenInfo {
            self.detailViewModel.symbol.onNext(token.symbol)
        } else {
            if let _ = self.walletInfo as? ICXWallet {
                self.detailViewModel.symbol.onNext(CoinType.icx.symbol)
            } else {
                self.detailViewModel.symbol.onNext(CoinType.eth.symbol)
            }
        }
        setupBind()
        setupUI()
        
        // refresh control
        let refreshControl = MintRefreshControl()
        refreshControl.tintColor = .white
        refreshControl.backgroundColor = .mint1
        refreshControl.rx.controlEvent(.valueChanged)
            .subscribe { (_) in
                self.pageIndex = 1
                Manager.exchange.getExchangeList()
                self.fetchBalance()
                self.fetchTxList()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(700)) {
                    refreshControl.endRefreshing()
                }
            }.disposed(by: disposeBag)
        
        self.tableView.refreshControl = refreshControl
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 30))
        
        guard let wallet = self.walletInfo else { return }
        
        // coin type
        if let token = self.tokenInfo {
            self.coinTypeLabel.size16(text: token.name, color: .white, weight: .medium, align: .right)
        } else {
            if let _ = wallet as? ICXWallet {
                self.coinTypeLabel.size16(text: CoinType.icx.fullName, color: .white, weight: .medium, align: .right)
            } else if let _ = wallet as? ETHWallet {
                self.coinTypeLabel.size16(text: CoinType.eth.fullName, color: .white, weight: .medium, align: .right)
            }
        }
        
        self.balanceLabel.isHidden = true
        self.balanceSpinner.startAnimating()
        
        // balance
        fetchBalance()
        
        // eth button
        etherscanButton.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.width/2 , height: 40)
        
        let attr = NSAttributedString(string: "Etherscan", attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .regular), .underlineStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: UIColor.mint1])
        
        etherButtonView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: 100))
        etherButtonView.addSubview(etherscanButton)
        
        etherscanButton.translatesAutoresizingMaskIntoConstraints = false
        etherscanButton.centerXAnchor.constraint(equalTo: etherButtonView.centerXAnchor).isActive = true
        etherscanButton.centerYAnchor.constraint(equalTo: etherButtonView.centerYAnchor).isActive = true
    
        etherscanButton.setAttributedTitle(attr, for: .normal)
        
        etherscanButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let ethURL = Ethereum.etherScanURL.appendingPathComponent(wallet.address)
                UIApplication.shared.open(ethURL, options: [:], completionHandler: nil)
        }.disposed(by: disposeBag)
        
        
        floater.delegate = self
        floater.button.rx.tap
            .subscribe(onNext: {
                if let wallet = self.selectedWallet {
                    self.floater.showMenu(wallet: wallet, token: self.tokenInfo, self, isICX: self.detailType == .icx)
                }
                if let eth = wallet as? ETHWallet {
                    self.floater.showMenu(ethWallet: eth, token: self.tokenInfo, self)
                    return
                }
            }).disposed(by: disposeBag)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        attach()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        detach()
    }
    
    private func fetchBalance() {
        guard let wallet = self.walletInfo else { return }
        DispatchQueue.global().async {
            let balance: BigUInt = {
                if let token = self.tokenInfo {
                    if let _ = wallet as? ICXWallet {
                        return Manager.icon.getIRCTokenBalance(dependedAddress: wallet.address, contractAddress: token.contract) ?? 0
                        
                    } else if let _ = wallet as? ETHWallet {
                        let ethBalance = Ethereum.requestTokenBalance(token: token) ?? 0
                        Manager.balance.updateTokenBalance(address: token.parent, contract: token.contract, balance: ethBalance)
                        return ethBalance
                    } else {
                        return 0
                    }
                    
                } else {
                    if let icx = wallet as? ICXWallet {
                        return Manager.icon.getBalance(wallet: icx) ?? 0
                        
                    } else if let eth = wallet as? ETHWallet {
                        return Ethereum.requestBalance(address: eth.address.add0xPrefix()) ?? 0
                    } else {
                        return 0
                    }
                }
            }()
            
            DispatchQueue.main.async {
                self.detailViewModel.balance.onNext(balance)
            }
        }
    }
    
    private func fetchTxList(isRefresh: Bool = true) {
        guard let wallet = self.walletInfo else { return }
        
        switch self.detailType {
        case .eth, .erc:
            ethTxList.removeAll()
            
            if filter == .deposit {
                self.tableView.backgroundView = etherButtonView
                
                self.tableView.separatorStyle = .none
                
                self.tableView.reloadData()
                return
            }
            
            ethTxList = Transactions.etherTxList(address: wallet.address.add0xPrefix()).filter({ (txInfo) -> Bool in
                guard let tokenSymbol = self.tokenInfo?.symbol.lowercased() else {
                    return txInfo.tokenSymbol == nil
                }

                return txInfo.tokenSymbol?.lowercased() == tokenSymbol
            })
            
            if ethTxList.isEmpty {
                let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: self.tableView.bounds.size.height))
                messageLabel.size14(text: "Wallet.Detail.NoTxHistory".localized, color: .gray77, align: .center)
                
                self.tableView.backgroundView = messageLabel
                self.tableView.separatorStyle = .none
            } else {
                self.tableView.backgroundView = nil
                self.tableView.separatorStyle = .singleLine
            }
            
            self.tableView.reloadData()
            
            return
        default: break
        }
        
        var newTxList = [Tracker.TxList]()
        
        DispatchQueue.global().async {
            if let token = self.tokenInfo { //token
                if let transactionList = self.tracker.tokenTxList(address: wallet.address, contractAddress: token.contract, page: self.pageIndex) {
                    if let list = transactionList["data"] as? [[String: Any]] {
                        for i in list {
                            let tx = Tracker.TxList.init(dic: i)
                            switch self.filter {
                            case .all:
                                newTxList.append(tx)
                            case .send:
                                if tx.fromAddr == wallet.address {
                                    newTxList.append(tx)
                                }
                            case .deposit:
                                if tx.toAddr == wallet.address {
                                    newTxList.append(tx)
                                }
                            }
                        }
                    }
                }
            } else { // coin
                if let transactionList = self.tracker.transactionList(address: wallet.address, page: self.pageIndex, txType: .icxTransfer) {
                    if let list = transactionList["data"] as? [[String: Any]] {
                        for i in list {
                            let tx = Tracker.TxList.init(dic: i)
                            switch self.filter {
                            case .all:
                                newTxList.append(tx)
                            case .send:
                                if tx.fromAddr == wallet.address {
                                    newTxList.append(tx)
                                }
                            case .deposit:
                                if tx.toAddr == wallet.address {
                                    newTxList.append(tx)
                                }
                            }
                        }
                    }
                }
            }
            
            if isRefresh {
                self.txList = newTxList
            } else {
                self.txList.append(contentsOf: newTxList)
            }
            
            DispatchQueue.main.async {
                if self.txList.isEmpty {
                    let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: self.tableView.bounds.size.height))
                    messageLabel.size14(text: "Wallet.Detail.NoTxHistory".localized, color: .gray77, align: .center)
                    
                    self.tableView.backgroundView = messageLabel
                    self.tableView.separatorStyle = .none
                    
                } else {
                    self.tableView.backgroundView = nil
                    self.tableView.separatorStyle = .singleLine
                }
                
                self.tableView.reloadData()
            }
        }
        
    }
    
    private func setStakeView() {
        guard let icxWallet = self.walletInfo as? ICXWallet, let staked = Manager.iiss.stake(icx: icxWallet), staked > BigUInt(0), self.tokenInfo == nil else {
            self.headerView.frame.size.height = 140
            self.stakeBoxView.isHidden = true
            
            return
        }
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            self.headerView.frame.size.height = 255
            
        }, completion: nil)
        
        totalBalanceTitle.size12(text: "ICX Balance", color: .white, weight: .light, align: .left)
        liquidTitle.size12(text: "Liquid ICX", color: .white, weight: .light, align: .left)
        stakedTitle.size12(text: "Staked ICX (Voting Power)", color: .white, weight: .light, align: .left)
        
        let liquid = Manager.icon.getBalance(address: icxWallet.address) ?? BigUInt.zero
        
        liquidLabel.size12(text: liquid.toString(decimal: 18, 8).currencySeparated(), color: .white, align: .right)
        stakedLabel.size12(text: staked.toString(decimal: 18, 8).currencySeparated() , color: .white, align: .right)
        
        stakeBoxView.isHidden = false
    }
    
    private func setupUI() {
        guard let wallet = self.walletInfo else { return }
        
        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarBack")) {
            self.navigationController?.popToRootViewController(animated: true)
        }
        navBar.setTitle(wallet.name)
        
        navBar.setRight(image: #imageLiteral(resourceName: "icWalletMoreEnabled")) {
            let manageVC = UIStoryboard(name: "ManageWallet", bundle: nil).instantiateViewController(withIdentifier: "Manage") as! ManageWalletViewController
            manageVC.walletInfo = self.walletInfo
            manageVC.handler = {
                guard let newWallet = Manager.wallet.walletList.filter({ $0.address == wallet.address }).first else { return }
                self.walletInfo = newWallet
                
                self.navBar.setTitle(newWallet.name)
            }
            
            manageVC.show()
        }
        
        totalBalanceLabel.text = "-"
        liquidLabel.text = "-"
        stakedLabel.text = "-"
        
        self.currencyPriceLabel.isHidden = true
        
        stakeBoxView.corner(8)
        stakeBoxView.backgroundColor = UIColor.init(white: 1.0, alpha: 0.1)
        
        
        setStakeView()
    }
    
    private func setupBind() {
        guard let wallet = self.walletInfo else { return }
        
        self.detailViewModel.wallet
            .map {
                if let tokens = $0.tokens, tokens.count > 0 {
                    return true
                } else {
                    return false
                }
            }.bind(to: dropDownButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        dropDownButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let selectVC = self.storyboard?.instantiateViewController(withIdentifier: "SelectCoinToken") as! SelectCoinTokenViewController
                selectVC.walletInfo = self.walletInfo
                selectVC.changedHandler = { (newToken) in
                    self.balanceLabel.isHidden = true
                    self.currencyPriceLabel.isHidden = true
                    self.balanceSpinner.startAnimating()
                    
                    // token or nil
                    self.detailViewModel.token.onNext(newToken)
                    
                    switch self.detailType {
                    case .icx, .irc:
                        if let token = newToken {
                            self.detailType = .irc
                            
                            self.detailViewModel.symbol.onNext(token.symbol)
                            self.detailViewModel.fullName.onNext(token.name)
                            
                        } else {
                            self.detailType = .icx
                            
                            self.detailViewModel.symbol.onNext(CoinType.icx.symbol)
                            self.detailViewModel.fullName.onNext(CoinType.icx.fullName)
                        }
                        
                    case .eth, .erc:
                        self.detailType = newToken == nil ? .eth : .erc
                        
                        if let token = newToken {
                            self.detailType = .erc
                            
                            self.detailViewModel.symbol.onNext(token.symbol)
                            self.detailViewModel.fullName.onNext(token.name)
                            
                        } else {
                            self.detailType = .eth
                            
                            self.detailViewModel.symbol.onNext(CoinType.eth.symbol)
                            self.detailViewModel.fullName.onNext(CoinType.eth.fullName)
                        }
                    }
                    self.tokenInfo = newToken
                    
                    self.fetchTxList()
                    self.detailViewModel.currencyUnit.onNext(.USD)
                    self.currencyPriceLabel.isHidden = true
                    self.fetchBalance()
                    self.setStakeView()
                    
                }
                selectVC.show()
                
        }.disposed(by: disposeBag)
        
        self.detailViewModel.fullName
            .bind(to: self.coinTypeLabel.rx.text)
            .disposed(by: disposeBag)
        
        self.detailViewModel.currencyUnit
            .map { $0.symbol }
            .bind(to: self.currencyLabel.rx.text)
            .disposed(by: disposeBag)
                
        let shareBalance = self.detailViewModel.balance.share(replay: 1)
        
        shareBalance.flatMapLatest { (value) -> Observable<String> in
            self.balanceLabel.isHidden = false
            self.balanceSpinner.stopAnimating()
                
            guard let token = self.tokenInfo else {
                return Observable.just(value.toString(decimal: wallet.decimal, 4).currencySeparated())
            }
            return Observable.just(value.toString(decimal: token.decimal, 4).currencySeparated())
            
        }.bind(to: self.balanceLabel.rx.text)
        .disposed(by: disposeBag)
        
        shareBalance
            .flatMapLatest { (unstake) -> Observable<String> in
                guard let icxWallet = self.walletInfo as? ICXWallet, let staked = Manager.iiss.stake(icx: icxWallet) else { return Observable.just("")}
                
                let totalBalance = unstake + staked
                return Observable.just(totalBalance.toString(decimal: 18, 8).currencySeparated())
                
        }.bind(to: self.totalBalanceLabel.rx.text)
        .disposed(by: disposeBag)
        
        
        Observable.combineLatest(self.detailViewModel.currencyPrice, self.detailViewModel.balance).flatMapLatest { (currency, bal) -> Observable<String> in
            self.currencyPriceLabel.isHidden = false
            
            let currencyPrice = Float(currency) ?? 0
            let balance = Float(bal)
            let price = BigUInt(currencyPrice*balance)
            
            let result: String = {
                if let token = self.tokenInfo {
                    return price.toString(decimal: token.decimal, 4).currencySeparated()
                } else {
                    return price.toString(decimal: wallet.decimal, 4).currencySeparated()
                }
            }()
            
            return Observable.just(result)
        }.bind(to: currencyPriceLabel.rx.text)
        .disposed(by: disposeBag)
        
        toggleButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let currencyUnit = try! self.detailViewModel.currencyUnit.value()
                
                switch self.detailType {
                case .icx, .erc:
                    switch currencyUnit {
                    case .USD: self.detailViewModel.currencyUnit.onNext(.BTC)
                    case .BTC: self.detailViewModel.currencyUnit.onNext(.ETH)
                    case .ETH: self.detailViewModel.currencyUnit.onNext(.USD)
                    default: break
                    }
                
                default:
                    switch currencyUnit {
                    case .USD: self.detailViewModel.currencyUnit.onNext(.BTC)
                    case .BTC: self.detailViewModel.currencyUnit.onNext(.ICX)
                    case .ICX: self.detailViewModel.currencyUnit.onNext(.USD)
                    default: break
                    }
                }
        }.disposed(by: disposeBag)
        
        self.detailViewModel.filter.distinctUntilChanged()
            .subscribe(onNext: { (filter) in
                self.filter = filter
                self.pageIndex = 1
                self.fetchTxList()
                
        }).disposed(by: disposeBag)
        
        tableView.rx.didEndDragging.subscribe { (_) in
            let height = self.tableView.contentSize.height
            let offset = self.tableView.contentOffset.y
            
            let spinner = UIActivityIndicatorView(style: .gray)
            
            if offset + self.tableView.frame.height >= height {
                self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                self.pageIndex += 1
                
                self.fetchTxList(isRefresh: false)
                
            } else {
                self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -76, right: 0)

                spinner.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: self.tableView.bounds.width, height: CGFloat(44))

                self.tableView.tableFooterView = spinner
                self.tableView.tableFooterView?.isHidden = false
                
                self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                spinner.stopAnimating()
            }

        }.disposed(by: disposeBag)
        
    }
}

extension DetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch detailType {
        case .eth, .erc:
            return self.ethTxList.count
        case .icx, .irc:
            return self.txList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell") as! DetailTableViewCell
        
        guard let wallet = self.walletInfo else { return cell }
        
        switch detailType {
        case .eth, .erc:
            let item = self.ethTxList[indexPath.row]
            
            let txHash = item.txHash
            let amount = item.value
            let timeStamp = item.date.toDateString()
            let symbol = try? self.detailViewModel.symbol.value()
            
            cell.txHashLabel.size12(text: txHash, color: .gray128, weight: .light)
            
            cell.statusLabel.size12(text: "Wallet.Detail.TransferCompleted".localized , color: .gray77, weight: .semibold)
            cell.valueLabel.size12(text: "- \(amount)", color: .gray77, weight: .bold, align: .right)
            cell.symbolLabel.size12(text: symbol ?? "ETH", color: .gray77, weight: .bold, align: .right)
            cell.timestampLabel.size12(text: timeStamp, color: .gray128, align: .right)
            
            return cell
        case .icx, .irc:
            let item = self.txList[indexPath.row]
            
            let txHash = item.txHash
            let from = item.fromAddr
            let amount = self.tokenInfo == nil ? item.amount : item.quantity
            let timeStamp = self.tokenInfo == nil ? item.createDate : item.age
            let symbol = try? self.detailViewModel.symbol.value()
            
            cell.txHashLabel.size12(text: txHash, color: .gray128, weight: .light)
            
            //        let status = item.state // 0, 1
            if from == wallet.address {
                cell.statusLabel.size12(text: "Wallet.Detail.TransferCompleted".localized , color: .gray77, weight: .semibold)
                cell.valueLabel.size12(text: "- \(amount)", color: .gray77, weight: .bold, align: .right)
                cell.symbolLabel.size12(text: symbol ?? "", color: .gray77, weight: .bold, align: .right)
            } else {
                cell.statusLabel.size12(text: "Wallet.Detail.DepositCompleted".localized , color: .gray77, weight: .semibold)
                cell.valueLabel.size12(text: "+ \(amount)", color: .mint1, weight: .bold, align: .right)
                cell.symbolLabel.size12(text: symbol ?? "", color: .mint1, weight: .bold, align: .right)
            }
            cell.timestampLabel.size12(text: timeStamp.yymmdd(), color: .gray128, align: .right)
            
            return cell
        }
    }
}

extension DetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        ixSectionHeader.filter = self.filter
        
        switch self.detailType {
        case .eth, .erc:
            ixSectionHeader.infoButton.isHidden = true
        default: break
        }
        
        let description: String = {
            switch self.filter {
            case .all: return "Wallet.Detail.Option.All".localized
            case .send: return "Wallet.Detail.Option.Send".localized
            case .deposit: return "Wallet.Detail.Option.Deposit".localized
            }
        }()
        
        ixSectionHeader.typeLabel.text = description
        
        ixSectionHeader.handler = { newFilter in
            self.detailViewModel.filter.onNext(newFilter)
        }
        
        return ixSectionHeader
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch detailType {
        case .icx, .irc:
            let txHash = self.txList[indexPath.row].txHash
            let provider = tracker.provider
            let txInfo = AlertTxHashInfo(txHash: txHash, trackerURL: "\(provider)/transaction/\(txHash)")
            
            Alert.txHash(txData: txInfo, confirmAction: {
                Toast.toast(message: "Alert.Transaction.Copy.Complete".localized)
            }).show()
            
        default:
            let txHash = self.ethTxList[indexPath.row].txHash
            let provider = Ethereum.etherScanURL.deletingLastPathComponent()
            
            let txInfo = AlertTxHashInfo(txHash: txHash, trackerURL: "\(provider)/tx/\(txHash)")
            
            Alert.txHash(txData: txInfo, confirmAction: {
                Toast.toast(message: "Alert.Transaction.Copy.Complete".localized)
            }).show()
        }
    }
}

// https://stackoverflow.com/a/50670500
class MintRefreshControl: UIRefreshControl {
    override var isHidden: Bool {
        get {
            return super.isHidden
        }
        set(hiding) {
            if hiding {
                guard frame.origin.y >= 0 else { return }
                super.isHidden = hiding
            } else {
                guard frame.origin.y < 0 else { return }
                super.isHidden = hiding
            }
        }
    }
    
    override var frame: CGRect {
        didSet {
            if frame.origin.y < 0 {
                isHidden = false
            } else {
                isHidden = true
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let originalFrame = frame
        frame = originalFrame
    }
}

extension Date {
    func toDateString() -> String {
        let dateformatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:s"
            formatter.timeZone = .autoupdatingCurrent
            return formatter
        }()
        
        let date = dateformatter.string(from: self)
        return date
    }
}
