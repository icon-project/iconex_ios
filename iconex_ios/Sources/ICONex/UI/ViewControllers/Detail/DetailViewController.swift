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
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var walletInfo: BaseWalletConvertible? = nil {
        willSet {
            guard let wallet = newValue else { return }
            if let icx = wallet as? ICXWallet {
                selectedWallet = icx
            }
        }
    }
    
    var tokenInfo: Token? = nil {
        willSet {
            guard let token = newValue else { return }
            detailViewModel.symbol.onNext(token.symbol)
        }
    }
    
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
    
    var txList = [Tracker.TxList]()
    
    var pageIndex: Int = 1
    var detailType: DetailType = .icx
    var filter: TxFilter = .all
    
    let ixSectionHeader = IXSectionHeader(frame: CGRect.init(x: 0, y: 0, width: .max, height: 36))
    
    var etherscanButton = UIButton()
    
    var floater: Floater = Floater(type: .wallet)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBind()
        setupUI()
        
        // refresh control
        let refreshControl = MintRefreshControl()
        refreshControl.tintColor = .white
        refreshControl.backgroundColor = .mint1
        refreshControl.rx.controlEvent(.valueChanged)
            .subscribe { (_) in
                self.txList.removeAll()
                self.pageIndex = 1
                self.fetchBalance()
                self.fetchTxList()
                
                DispatchQueue.main.async {
                    refreshControl.endRefreshing()
                }
            }.disposed(by: disposeBag)
        
        self.tableView.refreshControl = refreshControl
        self.tableView.tableFooterView = UIView()
        
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
        
        // balance
        fetchBalance()
        detailViewModel.currencyUnit.onNext(.USD)
        
        // eth button
        let attr = NSAttributedString(string: "Etherscan", attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .regular), .underlineStyle: NSUnderlineStyle.single.rawValue])
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
                    self.floater.showMenu(wallet: wallet, token: self.tokenInfo, self)
                }
                if let eth = wallet as? ETHWallet {
                    self.floater.showMenu(ethWallet: eth, self)
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
                        return Manager.icon.getIRCTokenBalance(tokenInfo: token) ?? 0
                        
                    } else if let _ = wallet as? ETHWallet {
                        return Ethereum.requestTokenBalance(token: token) ?? 0
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
                detailViewModel.balance.onNext(balance)
            }
        }
    }
    
    private func fetchTxList() {
        guard let wallet = self.walletInfo else { return }
        
        switch self.detailType {
        case .eth, .erc:
//            let messageLabel = UILabel()
//            messageLabel.size14(text: "Wallet.Detail.ETHTransactions".localized, color: .gray77, align: .center)
//            messageLabel.sizeToFit()
            
//            let ethStack = UIStackView(arrangedSubviews: [messageLabel, etherscanButton])
//            ethStack.axis = .vertical
//            ethStack.frame.size = CGSize(width: self.view.frame.width, height: self.tableView.frame.height)
//            ethStack.alignment = .center
//            ethStack.distribution = .fill
//
            self.tableView.backgroundView = etherscanButton
            self.tableView.separatorStyle = .none
            
            return
        default: break
        }
        
        activityIndicator.startAnimating()
        
        DispatchQueue.global().async {
            if let token = self.tokenInfo { //token
                if let transactionList = self.tracker.tokenTxList(address: wallet.address, contractAddress: token.contract, page: self.pageIndex) {
                    if let list = transactionList["data"] as? [[String: Any]] {
                        for i in list {
                            let tx = Tracker.TxList.init(dic: i)
                            switch self.filter {
                            case .all:
                                self.txList.append(tx)
                            case .send:
                                if tx.fromAddr == wallet.address {
                                    self.txList.append(tx)
                                }
                            case .deposit:
                                if tx.toAddr == wallet.address {
                                    self.txList.append(tx)
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
                                self.txList.append(tx)
                            case .send:
                                if tx.fromAddr == wallet.address {
                                    self.txList.append(tx)
                                }
                            case .deposit:
                                if tx.toAddr == wallet.address {
                                    self.txList.append(tx)
                                }
                            }
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                
                if self.txList.isEmpty {
                    let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: self.tableView.bounds.size.height))
                    messageLabel.size14(text: "Wallet.Detail.NoTxHistory".localized, color: .gray77, align: .center)
                    
                    self.tableView.backgroundView = messageLabel
                    self.tableView.separatorStyle = .none
                    
                } else {
                    self.tableView.backgroundView = nil
                    self.tableView.separatorStyle = .singleLine
                }
            }
        }
        
        activityIndicator.stopAnimating()
    }
    
    private func setStakeView() {
        guard let icxWallet = self.walletInfo as? ICXWallet, let staked = Manager.iiss.stake(icx: icxWallet), staked > BigUInt(0), self.tokenInfo == nil else {
            headerView.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 140)
            stakeBoxView.isHidden = true
            return
        }
        headerView.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 255)
        stakeBoxView.isHidden = false
        totalBalanceTitle.size12(text: "ICX Balance", color: .white, weight: .light, align: .left)
        liquidTitle.size12(text: "Liquid ICX", color: .white, weight: .light, align: .left)
        stakedTitle.size12(text: "Staked ICX (Voting Power)", color: .white, weight: .light, align: .left)
        
        guard let stake = Manager.iiss.stake(icx: icxWallet), let liquid = Manager.iiss.votingPower(icx: icxWallet) else { return }
        
        liquidLabel.size12(text: liquid.toString(decimal: 18, 8).currencySeparated(), color: .white, align: .right)
        stakedLabel.size12(text: stake.toString(decimal: 18, 8).currencySeparated() , color: .white, align: .right)
    }
    
    private func setupUI() {
        guard let wallet = self.walletInfo else { return }
        
        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarBack")) {
             detailViewModel.filter.onNext(.all)
            self.navigationController?.popToRootViewController(animated: true)
        }
        navBar.setTitle(wallet.name)
        
        navBar.setRight(image: #imageLiteral(resourceName: "icWalletMoreEnabled")) {
            let manageVC = UIStoryboard(name: "ManageWallet", bundle: nil).instantiateViewController(withIdentifier: "Manage") as! ManageWalletViewController
            manageVC.walletInfo = wallet
            manageVC.show()
        }
        
        stakeBoxView.corner(8)
        stakeBoxView.backgroundColor = UIColor.init(white: 1.0, alpha: 0.1)
        setStakeView()
    }
    
    private func setupBind() {
        guard let wallet = self.walletInfo else { return }
        
        detailViewModel.wallet
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
                    self.tokenInfo = newToken
                    self.txList.removeAll()
                    self.fetchTxList()
                    self.fetchBalance()
                    self.setStakeView()
                    self.tableView.reloadData()
                }
                selectVC.show()
                
        }.disposed(by: disposeBag)
        
        detailViewModel.fullName
            .bind(to: self.coinTypeLabel.rx.text)
            .disposed(by: disposeBag)
        
        detailViewModel.currencyUnit
            .map { $0.symbol }
            .bind(to: self.currencyLabel.rx.text)
            .disposed(by: disposeBag)
                
        let shareBalance = detailViewModel.balance.share(replay: 1)
        
        shareBalance
            .flatMapLatest { (value) -> Observable<String> in
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
        
        
        Observable.combineLatest(detailViewModel.currencyPrice, detailViewModel.balance).flatMapLatest { (currency, bal) -> Observable<String> in
            
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
                let currencyUnit = try! detailViewModel.currencyUnit.value()
                
                switch self.detailType {
                case .icx, .erc:
                    switch currencyUnit {
                    case .USD: detailViewModel.currencyUnit.onNext(.BTC)
                    case .BTC: detailViewModel.currencyUnit.onNext(.ETH)
                    case .ETH: detailViewModel.currencyUnit.onNext(.USD)
                    default: break
                    }
                
                default:
                    switch currencyUnit {
                    case .USD: detailViewModel.currencyUnit.onNext(.BTC)
                    case .BTC: detailViewModel.currencyUnit.onNext(.ICX)
                    case .ICX: detailViewModel.currencyUnit.onNext(.USD)
                    default: break
                    }
                }
        }.disposed(by: disposeBag)
        
        detailViewModel.filter.observeOn(MainScheduler.instance)
            .subscribe(onNext: { (filter) in
                self.txList.removeAll()
                self.filter = filter
                self.fetchTxList()
                self.tableView.reloadData()
        }).disposed(by: disposeBag)
        
        tableView.rx.didEndDragging.subscribe { (_) in
            let height = self.tableView.contentSize.height
            let offset = self.tableView.contentOffset.y
            
            let spinner = UIActivityIndicatorView(style: .gray)
            
            if offset + self.tableView.frame.height >= height {
                self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                self.pageIndex += 1
                
                self.fetchTxList()
                self.tableView.reloadData()
            } else {
                self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -76, right: 0)

                spinner.startAnimating()
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
        return self.txList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell") as! DetailTableViewCell
        
        guard let wallet = self.walletInfo else { return cell }
        let item = txList[indexPath.row]
        
        let txHash = item.txHash
        let from = item.fromAddr
        let amount = self.tokenInfo == nil ? item.amount : item.quantity
        let timeStamp = self.tokenInfo == nil ? item.createDate : item.age
        let symbol = try? detailViewModel.symbol.value()
        
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

extension DetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch self.detailType {
        case .eth, .erc:
            ixSectionHeader.infoButton.isHidden = true
        default: break
        }
        return ixSectionHeader
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let txHash = txList[indexPath.row].txHash
        let provider = tracker.provider
        let txInfo = AlertTxHashInfo(txHash: txHash, trackerURL: "\(provider)/transaction/\(txHash)")
        
        Alert.txHash(txData: txInfo, confirmAction: {
            Tool.toast(message: "Alert.Transaction.Copy.Complete".localized)
        }).show()
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
