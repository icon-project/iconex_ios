//
//  MainWalletView.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import BigInt

protocol MainWalletDelegate {
    func showWalletDetail(info: WalletInfo, snapshot: UIImage, view: UIView)
}

class MainWalletView: UIView, UIScrollViewDelegate {

    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var addressButton: UIButton!
    @IBOutlet weak var detailButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var walletsTotalView: UIView!
    @IBOutlet weak var walletNameLabel: UILabel!
    @IBOutlet weak var totalBalanceLabel: UILabel!
    @IBOutlet weak var indexLabel: UILabel!
    
    @IBOutlet weak var coinsTotalView: UIView!
    @IBOutlet weak var coinsTotalBalance: UILabel!
    @IBOutlet weak var coinsTotalSymbol: UILabel!
    @IBOutlet weak var coinsTotalExchange: UILabel!
    @IBOutlet weak var coinsTotalExchangeSymbol: UILabel!
    
    @IBOutlet weak var indicator: IXIndicator!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var delegate: MainWalletDelegate?
    
    private var walletInfo: WalletInfo?
    private var coin: CoinInfo?
    private var token: Token?
    
    private let disposeBag = DisposeBag()
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        totalBalanceLabel.text = "-"
        
        containerView.layer.shadowOffset = CGSize(width: 0, height: 20)
        containerView.layer.shadowColor = UIColor(0, 38, 38).cgColor
        containerView.layer.shadowOpacity = 0.18
        containerView.layer.shadowRadius = 25 / 2
        
        shadowView.corner(5)
        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "MainWalletCell", bundle: nil), forCellReuseIdentifier: "MainWalletCell")
        tableView.isScrollEnabled = false
        
        addressButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            guard let delegate = self.delegate, let info = self.walletInfo else { return }
            
            let image = self.containerView.asImage()
            delegate.showWalletDetail(info: info,snapshot: image, view: self.containerView)
        }).disposed(by: disposeBag)
        
        detailButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            let app = UIApplication.shared.delegate as! AppDelegate
            guard let root = app.window?.rootViewController as? UINavigationController, let main = root.viewControllers[0] as? MainViewController else {
                return
            }
            
            let detail = UIStoryboard(name: "Menu", bundle: nil).instantiateViewController(withIdentifier: "WalletDetailMenu") as! WalletDetailMenuController
            
            detail.present(from: root, walletInfo: self.walletInfo!)
            detail.handler = { index in
                
                switch index {
                case 0:
                    // 지갑 이름 변경
                    let wallet = WManager.loadWalletBy(info: self.walletInfo!)!
                    let change = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "ChangeNameView") as! ChangeNameViewController
                    change.formerName = wallet.alias!
                    change.completionHandler = { (newName) in
                        do {
                            let result = try WManager.changeWalletName(former: wallet.alias!, newName: newName)
                            
                            if result {
                                WManager.loadWalletList()
                                main.loadWallets(animate: false)
                            } else {
                                let basic = Alert.Basic(message: "Error.CommonError".localized)
                                root.present(basic, animated: true, completion: nil)
                            }
                        } catch {
                            Log("error: \(error)")
                            let message = "Error.CommonError".localized
                            let basic = Alert.Basic(message: message)
                            root.present(basic, animated: true, completion: nil)
                        }
                    }
                    root.present(change, animated: true, completion: nil)
                    break
                    
                case 1:
                    // 토큰 관리
                    Alert.TokenManage(walletInfo: self.walletInfo!).show(root)
                    break
                    
                case 2:
                    // 지갑 백업
                    let auth = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "WalletPasswordView") as! WalletPasswordViewController
                    auth.walletInfo = self.walletInfo
                    auth.addConfirm(completion: { (isSuccess, privKey) in
                        if isSuccess {
                            let backup = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WalletBackupView") as! WalletBackupViewController
                            backup.privKey = privKey
                            backup.walletInfo = self.walletInfo
                            
                            root.present(backup, animated: true, completion: nil)
                        }
                    })
                    root.present(auth, animated: true, completion: nil)
                    
                case 3:
                    // 지갑 비밀번호 변경
                    let change = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChangePasswordView") as! ChangePasswordViewController
                    change.walletInfo = self.walletInfo
                    root.present(change, animated: true, completion: nil)
                    break
                    
                case 4:
                    // 지갑 삭제
                    guard let walletInfo = self.walletInfo else { return }
                    let wallet = WManager.loadWalletBy(info: walletInfo)!
                    guard let balance = Balance.walletBalanceList[walletInfo.address] else {
                        Alert.Confirm(message: "Alert.Wallet.Remove.UnknownBalance".localized, cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: {
                            Alert.checkPassword(walletInfo: walletInfo, action: { (isSuccess, _) in
                                if !WManager.deleteWallet(wallet: wallet) {
                                    Alert.Basic(message: "Error.CommonError".localized).show(root)
                                    return
                                }
                                
                                let app = UIApplication.shared.delegate as! AppDelegate
                                
                                if WManager.walletInfoList.count == 0 {
                                    let welcome = UIStoryboard(name: "Loading", bundle: nil).instantiateViewController(withIdentifier: "WelcomeView")
                                    app.window?.rootViewController = welcome
                                } else {
                                    guard let root = app.window?.rootViewController as? UINavigationController, let main = root.viewControllers[0] as? MainViewController else {
                                        return
                                    }
                                    main.currentIndex = 0
                                    main.loadWallets()
                                    main.showBalance()
                                }
                                
                            }).show(root)
                        }).show(root)
                        return
                    }
                    if balance == BigUInt(0) && Balance.tokenBalanceList[walletInfo.address]?.filter({ $0.value != BigUInt(0) }).first == nil {
                        
                        Alert.Confirm(message: "Alert.Wallet.Remove".localized, cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: {
                            if !WManager.deleteWallet(wallet: wallet) {
                                Alert.Basic(message: "Error.CommonError".localized).show(root)
                                return
                            }
                            
                            let app = UIApplication.shared.delegate as! AppDelegate
                            
                            if WManager.walletInfoList.count == 0 {
                                let welcome = UIStoryboard(name: "Loading", bundle: nil).instantiateViewController(withIdentifier: "WelcomeView")
                                app.window?.rootViewController = welcome
                            } else {
                                guard let root = app.window?.rootViewController as? UINavigationController, let main = root.viewControllers[0] as? MainViewController else {
                                    return
                                }
                                main.currentIndex = 0
                                main.loadWallets()
                                main.showBalance()
                            }
                        }).show(root)
                        return
                    } else {
                        Alert.Confirm(message: "Alert.Wallet.RemainBalance".localized, cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: {
                            Alert.checkPassword(walletInfo: walletInfo, action: { (isSuccess, _) in
                                if isSuccess {
                                    if !WManager.deleteWallet(wallet: wallet) {
                                        Alert.Basic(message: "Error.CommonError".localized).show(root)
                                        return
                                    }
                                    
                                    let app = UIApplication.shared.delegate as! AppDelegate
                                    
                                    if WManager.walletInfoList.count == 0 {
                                        let welcome = UIStoryboard(name: "Loading", bundle: nil).instantiateViewController(withIdentifier: "WelcomeView")
                                        app.window?.rootViewController = welcome
                                    } else {
                                        guard let root = app.window?.rootViewController as? UINavigationController, let main = root.viewControllers[0] as? MainViewController else {
                                            return
                                        }
                                        main.currentIndex = 0
                                        main.loadWallets()
                                        main.showBalance()
                                    }
                                }
                            }).show(root)
                        }).show(root)
                    }
                    
                    break
                    
                default:
                    break
                }
            }
        }).disposed(by: disposeBag)
        
        exchangeListDidChanged().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.setWalletBalance()
            }).disposed(by: disposeBag)
        
        balanceListDidChanged().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.setWalletBalance()
            }).disposed(by: disposeBag)
        
        exchangeIndicatorChanged().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.setWalletBalance()
            }).disposed(by: disposeBag)
    }
    
    func mainConstraintChanged(value: CGFloat) {
        if value >= 0 {
            tableView.isScrollEnabled = false
            bottomConstraint.constant = 0
        } else {
            tableView.isScrollEnabled = true
            bottomConstraint.constant = 24
        }
    }
    
    func setWalletBalance() {
        self.indexLabel.text = Exchange.currentExchange.uppercased()
        
        let below = Exchange.currentExchange == "usd" ? 2 : 4
        
        if let walletInfo = self.walletInfo {
            guard let wallet = WManager.loadWalletBy(info: walletInfo) else { return }
            walletsTotalView.isHidden = false
            coinsTotalView.isHidden = true
            if let address = wallet.address, let value = Balance.walletBalanceList[address], let vExchanged = Tool.balanceToExchange(value, from: wallet.type.rawValue.lowercased(), to: Exchange.currentExchange, belowDecimal: below, decimal: wallet.decimal) {
                indicator.isHidden = true
                totalBalanceLabel.isHidden = false
                
                var total = Tool.stringToBigUInt(inputText: vExchanged, decimal: wallet.decimal)!
                if let tokens = wallet.tokens {
                    for token in tokens {
                        guard let tokenBalances = Balance.tokenBalanceList[token.dependedAddress.add0xPrefix()], let balance = tokenBalances[token.contractAddress], let exchanged = Tool.balanceToExchange(balance, from: token.symbol.lowercased(), to: Exchange.currentExchange, belowDecimal: below, decimal: token.decimal) else { continue }
                        total += Tool.stringToBigUInt(inputText: exchanged, decimal: token.decimal)!
                    }
                }
                totalBalanceLabel.text = Tool.bigToString(value: total, decimal: wallet.decimal, Exchange.currentExchange == "usd" ? 2 : 4, false).currencySeparated()
            } else {
                if Balance.isBalanceLoadCompleted {
                    indicator.isHidden = true
                    totalBalanceLabel.isHidden = false
                } else {
                    indicator.isHidden = false
                    totalBalanceLabel.isHidden = true
                }
            }
        } else if let coin = self.coin {
            guard let wallets = coin.wallets else { return }
            walletsTotalView.isHidden = true
            coinsTotalView.isHidden = false
            var exchangeTotal: BigUInt? = nil
            var total = BigUInt(0)
            var decimal = 0
            for walletInfo in wallets {
                guard let wallet = WManager.loadWalletBy(info: walletInfo), let balance = Balance.walletBalanceList[walletInfo.address] else  { continue }
                decimal = wallet.decimal
                
                let trimming = Tool.bigToString(value: balance, decimal: decimal, 4, false).currencySeparated()
                let trimmed = Tool.stringToBigUInt(inputText: trimming, decimal: decimal)!
                total += trimmed
                
                guard let exchanged = Tool.balanceToExchange(trimmed, from: wallet.type.rawValue.lowercased(), to: Exchange.currentExchange, belowDecimal: below, decimal: wallet.decimal), let exc = Tool.stringToBigUInt(inputText: exchanged, decimal: wallet.decimal) else { continue }
                if let totalValue = exchangeTotal {
                    exchangeTotal = totalValue + exc
                } else {
                    exchangeTotal = exc
                }
            }
            coinsTotalBalance.text = Tool.bigToString(value: total, decimal: decimal, 4, false).currencySeparated()
            if let value = exchangeTotal {
                coinsTotalExchange.text = Tool.bigToString(value: value, decimal: decimal, below, false).currencySeparated()
            } else {
                coinsTotalExchange.text = "-"
            }
            
            coinsTotalSymbol.text = coin.symbol.uppercased()
            coinsTotalExchangeSymbol.text = Exchange.currentExchange.uppercased()
        } else if let token = self.token {
            guard let info = WManager.coinInfoListBy(token: token) else { return }
            guard let wallets = info.wallets else { return }
            walletsTotalView.isHidden = true
            coinsTotalView.isHidden = false
            
            var total = BigUInt(0)
            var exchangeTotal: BigUInt? = nil
            for walletInfo in wallets {
                guard let wallet = WManager.loadWalletBy(info: walletInfo), let item = wallet.tokens?.filter({ $0.symbol == token.symbol }).first, let tokenBalances = Balance.tokenBalanceList[item.dependedAddress.add0xPrefix()], let balance = tokenBalances[item.contractAddress] else { continue }
                let trimming = Tool.bigToString(value: balance, decimal: token.decimal, 4, false)
                let trimmed = Tool.stringToBigUInt(inputText: trimming, decimal: token.decimal)!
                
                total += trimmed
                
                guard let exchanged = Tool.balanceToExchange(trimmed, from: token.symbol.lowercased(), to: Exchange.currentExchange, belowDecimal: below, decimal: token.decimal), let exc = Tool.stringToBigUInt(inputText: exchanged, decimal: token.decimal) else { continue }
                if let totalValue = exchangeTotal {
                    exchangeTotal = totalValue + exc
                } else {
                    exchangeTotal = exc
                }
            }
            coinsTotalBalance.text = Tool.bigToString(value: total, decimal: token.decimal, 4, false).currencySeparated()
            if let value = exchangeTotal {
                coinsTotalExchange.text = Tool.bigToString(value: value, decimal: token.decimal, below, false).currencySeparated()
            } else {
                coinsTotalExchange.text = "-"
            }
            
            coinsTotalSymbol.text = token.symbol.uppercased()
            coinsTotalExchangeSymbol.text = Exchange.currentExchange.uppercased()
        }
        
        tableView.reloadData()
    }
    
    func setWalletInfo(walletInfo: WalletInfo) {
        self.coin = nil
        self.token = nil
        self.addressButton.isHidden = false
        self.detailButton.isHidden = false
        self.walletInfo = walletInfo
        
        if let wallet = WManager.loadWalletBy(info: walletInfo) {
            walletNameLabel.text = wallet.alias
        }
        self.setWalletBalance()
    }
    
    func setWalletInfo(coin: CoinInfo) {
        self.walletInfo = nil
        self.token = nil
        self.addressButton.isHidden = true
        self.detailButton.isHidden = true
        self.indicator.isHidden = true
        self.coin = coin
        self.walletNameLabel.text = coin.name
        self.setWalletBalance()
    }
    
    func setWalletInfo(token: Token) {
        self.walletInfo = nil
        self.coin = nil
        self.addressButton.isHidden = true
        self.detailButton.isHidden = true
        self.indicator.isHidden = true
        self.token = token
        if token.symbol.lowercased() == "icx" {
            self.walletNameLabel.text = "ICON Token"
        } else{
            self.walletNameLabel.text = token.symbol.uppercased() + " Token"
        }
        self.setWalletBalance()
    }
}

extension MainWalletView: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let info = self.coin {
            return info.wallets!.count
        } else if let token = self.token {
            guard let info = WManager.coinInfoListBy(token: token) else {
                return 0
            }
            guard let wallets = info.wallets else {
                return 0
            }
            
            return wallets.count
        } else {
            guard let walletInfo = self.walletInfo else {
                return 0
            }
            guard let wallet = WManager.loadWalletBy(info: walletInfo), let tokens = wallet.tokens, tokens.count > 0 else {
                return 1
            }
            
            return tokens.count + 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainWalletCell", for: indexPath) as! MainWalletCell
        
        cell.exchangeTypeLabel.text = Exchange.currentExchange.uppercased()
        cell.exchangeValueLabel.text = "-"
        cell.coinValueLabel.text = "-"
        cell.exchangeValueLabel.text = "-"
        
        if let coin = self.coin {
            let walletInfo = coin.wallets![indexPath.row]
            cell.coinTypeLabel.text = coin.symbol.uppercased()
            cell.exchangeTypeLabel.text = Exchange.currentExchange.uppercased()
            
            cell.coinNameLabel.text = walletInfo.name
            if let value = Balance.walletBalanceList[walletInfo.address], let wallet = WManager.loadWalletBy(info: walletInfo) {
                let valueString = Tool.bigToString(value: value, decimal: 18, 4)
                cell.coinValueLabel.text = valueString.currencySeparated()
                
                let trimmed = Tool.stringToBigUInt(inputText: valueString, decimal: wallet.decimal)!
                
                guard let exchanged = Tool.balanceToExchange(trimmed, from: coin.symbol.lowercased(), to: Exchange.currentExchange, belowDecimal: Exchange.currentExchange == "usd" ? 2 : 4, decimal: wallet.decimal) else {
                    cell.isLoading = !Balance.isBalanceLoadCompleted
                    Tool.rotateAnimation(inView: cell.indicator)
                    
                    return cell
                }
                cell.exchangeValueLabel.text = exchanged.currencySeparated()
                cell.isLoading = false
            } else {
                cell.isLoading = !Balance.isBalanceLoadCompleted
                Tool.rotateAnimation(inView: cell.indicator)
            }
        } else if let token = self.token {
            cell.coinTypeLabel.text = token.symbol.uppercased()
            guard let info = WManager.coinInfoListBy(token: token) else {
                return cell
            }
            guard let wallets = info.wallets else {
                return cell
            }
            let walletInfo = wallets[indexPath.row]
            cell.coinNameLabel.text = walletInfo.name
            
            guard let wallet = WManager.loadWalletBy(info: walletInfo) else { return cell }
            guard let item = wallet.tokens?.filter({ $0.symbol == token.symbol }).first else { return cell }
            guard let tokenBalances = Balance.tokenBalanceList[item.dependedAddress.add0xPrefix()] else { return cell }
            guard let balance = tokenBalances[item.contractAddress] else {
                cell.isLoading = !Balance.isBalanceLoadCompleted
                Tool.rotateAnimation(inView: cell.indicator)
                return cell
            }
            let trimming = Tool.bigToString(value: balance, decimal: token.decimal, 4)
            cell.coinValueLabel.text = trimming.currencySeparated()
            let trimmed = Tool.stringToBigUInt(inputText: trimming, decimal: token.decimal)!
            cell.exchangeValueLabel.text = Tool.balanceToExchange(trimmed, from: token.symbol.lowercased(), to: Exchange.currentExchange, belowDecimal: Exchange.currentExchange == "usd" ? 2 : 4, decimal: token.decimal)?.currencySeparated() ?? "-"
            
        } else {
            guard let walletInfo = self.walletInfo, let wallet = WManager.loadWalletBy(info: walletInfo) else {
                cell.coinNameLabel.text = "-"
                cell.coinTypeLabel.text = "-"
                cell.coinValueLabel.text = "-"
                cell.exchangeTypeLabel.text = "-"
                cell.exchangeValueLabel.text = "-"
                
                return cell
            }
            
            if indexPath.row == 0 {
                cell.coinNameLabel.text = self.walletInfo!.type == .eth ? "Ethereum" : "ICON"
                cell.coinTypeLabel.text = self.walletInfo!.type == .eth ? "ETH" : "ICX"
                if let value = Balance.walletBalanceList[wallet.address!] {
                    let valueString = Tool.bigToString(value: value, decimal: 18, 4)
                    cell.coinValueLabel.text = valueString.currencySeparated()
                    
                    let type = self.walletInfo!.type == .eth ? "eth" : "icx"
                    
                    guard let exchanged = Tool.balanceToExchange(value, from: type, to: Exchange.currentExchange, belowDecimal: Exchange.currentExchange == "usd" ? 2 : 4) else {
                        cell.isLoading = !Balance.isBalanceLoadCompleted
                        Tool.rotateAnimation(inView: cell.indicator)
                        return cell
                    }
                    cell.exchangeValueLabel.text = exchanged.currencySeparated()
                    cell.isLoading = false
                } else {
                    cell.isLoading = !Balance.isBalanceLoadCompleted
                    Tool.rotateAnimation(inView: cell.indicator)
                }
                
            } else {
                let token = wallet.tokens![indexPath.row - 1]
                cell.coinNameLabel.text = token.name
                cell.coinTypeLabel.text = token.symbol
                guard let tokenBalances = Balance.tokenBalanceList[token.dependedAddress.lowercased().add0xPrefix()], let balance = tokenBalances[token.contractAddress.lowercased()] else {
                    cell.isLoading = !Balance.isBalanceLoadCompleted
                    Tool.rotateAnimation(inView: cell.indicator)
                    return cell
                }
                
                cell.coinValueLabel.text = Tool.bigToString(value: balance, decimal: token.decimal, 4).currencySeparated()
                let tag = token.symbol.lowercased()
                cell.exchangeValueLabel.text = Tool.balanceToExchange(balance, from: tag, to: Exchange.currentExchange, belowDecimal: Exchange.currentExchange == "usd" ? 2 : 4, decimal: token.decimal)?.currencySeparated() ?? "-"
                cell.isLoading = false
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let app = UIApplication.shared.delegate as! AppDelegate
        guard let root = app.window?.rootViewController as? UINavigationController else {
            return
        }
        if Preference.shared.navSelected == 0 {
            if indexPath.row != 0 {
                if let walletInfo = self.walletInfo {
                    guard let wallet = WManager.loadWalletBy(info: walletInfo) else { return }
                    
                    let token = wallet.tokens![indexPath.row - 1]
                    
                    let detail = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WalletDetailView") as! WalletDetailViewController
                    detail.walletInfo = walletInfo
                    detail.token = token
                    root.pushViewController(detail, animated: true)
                } else if let coinInfo = self.coin {
                    let walletInfo = coinInfo.wallets![indexPath.row]
                    
                    let detail = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WalletDetailView") as! WalletDetailViewController
                    detail.walletInfo = walletInfo
                    root.pushViewController(detail, animated: true)
                } else if let token = self.token {
                    let detail = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WalletDetailView") as! WalletDetailViewController
                    guard let info = WManager.coinInfoListBy(token: token) else {
                        return
                    }
                    guard let wallets = info.wallets else {
                        return
                    }
                    let walletInfo = wallets[indexPath.row]
                    detail.walletInfo = walletInfo
                    detail.token = token
                    root.pushViewController(detail, animated: true)
                }
            } else {
                
                let detail = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WalletDetailView") as! WalletDetailViewController
                if let walletInfo = self.walletInfo {
                    detail.walletInfo = walletInfo
                } else if let coin = self.coin {
                    let walletInfo = coin.wallets![indexPath.row]
                    detail.walletInfo = walletInfo
                } else if let token = self.token {
                    guard let info = WManager.coinInfoListBy(token: token) else {
                        return
                    }
                    guard let wallets = info.wallets else {
                        return
                    }
                    let walletInfo = wallets[indexPath.row]
                    detail.walletInfo = walletInfo
                    detail.token = token
                }
                root.pushViewController(detail, animated: true)
            }
        } else {
            let detail = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WalletDetailView") as! WalletDetailViewController
            if let walletInfo = self.walletInfo {
                detail.walletInfo = walletInfo
            } else if let coin = self.coin {
                let walletInfo = coin.wallets![indexPath.row]
                detail.walletInfo = walletInfo
            } else if let token = self.token {
                guard let info = WManager.coinInfoListBy(token: token) else {
                    return
                }
                guard let wallets = info.wallets else {
                    return
                }
                let walletInfo = wallets[indexPath.row]
                token.dependedAddress = walletInfo.address.add0xPrefix().lowercased()
                detail.walletInfo = walletInfo
                detail.token = token
            }
            root.pushViewController(detail, animated: true)
        }
    }
}

extension MainWalletView {
    func heightShrink() {
        
    }
    
    func heightExpand() {
//        if let coin = self.coin {
//            
//        } else if let token = self.token {
//            
//        } else if let walletInfo = self.walletInfo {
//            let wallet = WManager.loadWalletBy(info: walletInfo)
//        }
    }
}
