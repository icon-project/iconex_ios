//
//  MainCollectionViewCell.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 20/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import BigInt
import ICONKit

class MainCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cardView: UIView!
    
    @IBOutlet weak var nicknameLabel: UILabel!
    
    @IBOutlet weak var buttonStack: UIStackView!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var qrcodeButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    
    @IBOutlet weak var tableview: UITableView!
    
    var handler: (() -> Void)?
    
    var info: BaseWalletConvertible? = nil {
        willSet {
            isWalletMode = true
        }
        didSet {
            tableview.reloadData()
        }
    }
    
    var coinTokenIndex: Int?
    var symbol: String = ""
    var fullName: String = ""
    var coinTokens: [BaseWalletConvertible]? = nil {
        willSet {
            isWalletMode = false
        }
        didSet {
            tableview.reloadData()
        }
    }
    
    var contractAddress: String?
    var tokenDecimal: Int?
    
    var isWalletMode: Bool = true
    
    let colorList: [SymbolColor] = [.A, .B, .C, .D, .E, .F, .G, .H, .I, .J, .K, .L]
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let nibName = UINib(nibName: "WalletTableViewCell", bundle: nil)
        self.tableview.register(nibName, forCellReuseIdentifier: "walletCell")
        
        cardView.corner(18)
        
        mainViewModel.isBigCard.subscribe(onNext: { (value) in
            self.tableview.isScrollEnabled = value
        }).disposed(by: disposeBag)
        
        mainViewModel.currencyUnit.subscribe { (_) in
            self.tableview.reloadData()
        }.disposed(by: disposeBag)
        
        scanButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                guard let wallet = self.info else { return }
                
                Alert.password(wallet: wallet, returnAction: { (privateKey) in
                    let scanVC = UIStoryboard.init(name: "Camera", bundle: nil).instantiateInitialViewController() as! QRReaderViewController
                    scanVC.modalPresentationStyle = .fullScreen
                    scanVC.set(mode: .connect, handler: { address, amount in
                        let send = UIStoryboard(name: "Send", bundle: nil).instantiateViewController(withIdentifier: "SendICX") as! SendICXViewController
                        send.walletInfo = self.info
                        send.privateKey = PrivateKey(hex: Data(hex: privateKey))
                        send.toAddress = address
                        send.toAmount = amount?.hexToBigUInt()?.toString(decimal: 18, 18, true)
                        send.modalPresentationStyle = .fullScreen

                        app.topViewController()?.present(send, animated: true, completion: nil)
                    })
                    app.topViewController()?.present(scanVC, animated: true, completion: nil)
                }).show()
                
            }.disposed(by: disposeBag)
        
        qrcodeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let qrVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QRCode") as! MainQRCodeViewController
                qrVC.wallet = self.info
                qrVC.modalPresentationStyle = .overFullScreen
                qrVC.dismissAction = {
                    self.isHidden = false
                }
                let snapshot = self.cardView.asImage()
                qrVC.fakeImage = snapshot
                qrVC.startHeight = self.tableview.isScrollEnabled ? 56 : 148 + 56
                
                app.topViewController()?.present(qrVC, animated: false, completion: {
                    self.isHidden = true
                })

                
            }.disposed(by: disposeBag)
        
        infoButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let manageVC = UIStoryboard(name: "ManageWallet", bundle: nil).instantiateViewController(withIdentifier: "Manage") as! ManageWalletViewController
                manageVC.walletInfo = self.info
                manageVC.handler = self.handler
                manageVC.show()

            }.disposed(by: disposeBag)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.info = nil
        self.symbol = ""
        self.contractAddress = nil
        self.tokenDecimal = nil
    }
    
}

extension MainCollectionViewCell: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            if isWalletMode {
                return self.info?.tokens?.count ?? 0
            } else {
                return self.coinTokens?.count ?? 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // cell
        let coinCell: CoinTableViewCell = {
            let cell = tableView.dequeueReusableCell(withIdentifier: "coinCell") as! CoinTableViewCell
            cell.corner(8)
            cell.border(0.5, .gray230)
            cell.basicView.backgroundColor = .gray252
            return cell
        }()
        
        let tokenCell: TokenTableViewCell = {
            let cell = tableView.dequeueReusableCell(withIdentifier: "tokenCell") as! TokenTableViewCell
            cell.corner(8)
            return cell
        }()
        
        let walletCell: WalletTableViewCell = {
            let cell = tableView.dequeueReusableCell(withIdentifier: "walletCell") as! WalletTableViewCell
            cell.corner(8)
            return cell
        }()
        
        let currency = try! mainViewModel.currencyUnit.value()
        
        if indexPath.section == 0 {
            if isWalletMode {
                coinCell.unitLabel.size12(text: currency.symbol, color: .gray179, align: .right)
                
                if let icx = info as? ICXWallet {
                    let currencySymbol = "icx\(currency.symbol.lowercased())"
                    coinCell.logoImageView.image = #imageLiteral(resourceName: "imgLogoIconSel")
                    coinCell.symbolLabel.size16(text: CoinType.icx.symbol, color: .gray77, weight: .semibold)
                    coinCell.fullNameLabel.size12(text: CoinType.icx.fullName, color: .gray179, weight: .light)
                    
                    coinCell.balanceLabel.size16(text: icx.balance?.toString(decimal: 18, 4).currencySeparated() ?? "-", color: .gray77, weight: .bold, align: .right)
                    
                    let price = Tool.calculatePrice(decimal: 18, currency: currencySymbol, balance: icx.balance)
                    coinCell.unitBalanceLabel.size12(text: price, color: .gray179, align: .right)
                    
                    // STAKE INFO
                    guard let stakeInfo = Manager.iiss.stake(icx: icx), stakeInfo > 0, let balance = icx.balance else {
                        coinCell.basicView.backgroundColor = .gray252
                        coinCell.backgroundColor = .gray252
                        coinCell.basicView.corner(8)
                        coinCell.basicView.border(0.5, .gray230)
                        coinCell.stakeLabel.text = "-"
                        coinCell.stakedPercentLabel.text = "( -%)"
                        coinCell.iscoreLabel.text = "-"
                        
                        return coinCell
                    }
                    
                    // set background color
                    coinCell.basicView.backgroundColor = .white
                    coinCell.backgroundColor = .gray252
                    coinCell.basicView.corner(8)
                    coinCell.basicView.border(0.5, .gray230)
                    
                    let staked = stakeInfo.toString(decimal: 18, 4).currencySeparated()
                    coinCell.stakeLabel.text = staked
                    
                    guard let stakedDecimal = stakeInfo.decimalNumber, let balanceDecimal = balance.decimalNumber else { return coinCell }
                    
                    let totalBalance = stakedDecimal + balanceDecimal

                    let stakedPercent: Float = {
                        if stakedDecimal == 0 {
                            return 0
                        } else {
                            return (stakedDecimal / totalBalance).floatValue * 100
                        }
                    }()
                    
                    coinCell.stakedPercentLabel.text = "(" + String(format: "%.1f", stakedPercent) + "%)"
                    
                    // I-SCORE
                    DispatchQueue.global().async {
                        let response = Manager.icon.queryIScore(from: icx)
                        
                        let iscore = response?.iscore.toString(decimal: 18, 4).currencySeparated()
                        
                        DispatchQueue.main.async {
                            coinCell.iscoreLabel.text = iscore ?? "-"
                            
                        }
                    }
                    
                } else if let eth = info as? ETHWallet {
                    let currencySymbol = "eth\(currency.symbol.lowercased())"
                    coinCell.logoImageView.image = #imageLiteral(resourceName: "imgLogoEthereumNor")
                    coinCell.symbolLabel.size16(text: CoinType.eth.symbol, color: .gray77, weight: .semibold)
                    coinCell.fullNameLabel.size12(text: CoinType.eth.fullName, color: .gray179, weight: .light)
                    
                    let balance = eth.balance?.toString(decimal: 18, 4).currencySeparated()
                    coinCell.balanceLabel.size16(text: balance ?? "-", color: .gray77, weight: .bold, align: .right)
                    
                    let price = Tool.calculatePrice(decimal: 18, currency: currencySymbol, balance: eth.balance)
                    coinCell.unitBalanceLabel.size12(text: price, color: .gray179, align: .right)
                }
                return coinCell
                
            } else { // total coin token info
                let currencySymbol = "\(symbol.lowercased())\(currency.symbol.lowercased())"
                switch symbol {
                case "icx":
                    coinCell.unitLabel.size12(text: currency.symbol, color: .gray179, align: .right)
                    
                    coinCell.logoImageView.image = #imageLiteral(resourceName: "imgLogoIconSel")
                    coinCell.symbolLabel.size16(text: CoinType.icx.symbol, color: .gray77, weight: .semibold)
                    coinCell.fullNameLabel.size12(text: CoinType.icx.fullName, color: .gray179, weight: .light)
                    
                    guard let list = self.coinTokens else { return coinCell }
                    
                    var totalBalance: BigUInt? = nil
                    for i in list {
                        if let balance = i.balance {
                            if let t = totalBalance {
                                totalBalance = t + balance
                            } else {
                                totalBalance = balance
                            }
                        }
                    }
                    let balance = totalBalance?.toString(decimal: 18, 4).currencySeparated()
                    
                    coinCell.balanceLabel.size16(text: balance ?? "-", color: .gray77, weight: .bold, align: .right)
                    
                    let price = Tool.calculatePrice(decimal: 18, currency: currencySymbol , balance: totalBalance)
                    coinCell.unitBalanceLabel.size12(text: price, color: .gray179, weight: .light, align: .right)
                    
                    return coinCell
                    
                case "eth":
                    coinCell.unitLabel.size12(text: currency.symbol, color: .gray179, align: .right)
                    
                    coinCell.logoImageView.image = #imageLiteral(resourceName: "imgLogoEthereumNor")
                    coinCell.symbolLabel.size16(text: CoinType.eth.symbol, color: .gray77, weight: .semibold)
                    coinCell.fullNameLabel.size12(text: CoinType.eth.fullName, color: .gray179, weight: .light)
                    
                    guard let list = self.coinTokens else { return coinCell }
                    
                    var totalBalance: BigUInt? = nil
                    for i in list {
                        if let balance = i.balance {
                            if let t = totalBalance {
                                totalBalance = t + balance
                            } else {
                                totalBalance = balance
                            }
                        }
                    }
                    
                    let balance = totalBalance?.toString(decimal: 18, 4).currencySeparated()
                    coinCell.balanceLabel.size16(text: balance ?? "-", color: .gray77, weight: .bold, align: .right)
                    
                    let price = Tool.calculatePrice(decimal: 18, currency: currencySymbol , balance: totalBalance)
                    coinCell.unitBalanceLabel.size12(text: price, color: .gray179, weight: .light, align: .right)
                    
                    return coinCell
                    
                default:
                    tokenCell.corner(8)
                    tokenCell.border(0.5, .gray230)
                    tokenCell.contentView.backgroundColor = .gray252
                    
                    guard let list = self.coinTokens, let contract = self.contractAddress else { return tokenCell }
                    
                    var totalBalance: BigUInt? = nil
                    for i in list {
                        if let balance = Manager.balance.getTokenBalance(address: i.address, contract: contract) {
                            if let t = totalBalance {
                                totalBalance = t + balance
                            } else {
                                totalBalance = balance
                            }
                        }
                    }
                    
                    guard let nickName = symbol.first?.uppercased() else { return tokenCell }
                    tokenCell.symbolNicknameLabel.size16(text: nickName , color: .white, weight: .medium, align: .center)
                    tokenCell.symbolView.backgroundColor = colorList[(self.coinTokenIndex ?? 0)%12].background
                    tokenCell.symbolLabel.size16(text: symbol, color: .gray77, weight: .semibold)
                    tokenCell.fullnameLabel.size12(text: fullName, color: .gray179, weight: .light)
                    
                    let balance = totalBalance?.toString(decimal: 18, 4).currencySeparated()
                    tokenCell.balanceLabel.size16(text: balance ?? "-" , color: .gray77, weight: .bold, align: .right)
                    
                    let decimal = DB.tokenListBy(symbol: symbol).first?.decimal ?? 0
                    let price = Tool.calculatePrice(decimal: decimal, currency: currencySymbol, balance: totalBalance)
                    tokenCell.unitBalanceLabel.size12(text: price, color: .gray179, align: .right)
                    
                    tokenCell.unitLabel.size12(text: currency.symbol, color: .gray179, align: .right)
                    return tokenCell
                }
            }
            
        } else {
            if isWalletMode {
                guard let token = info?.tokens?.sorted(by: { (lhs, rhs) -> Bool in
                    return lhs.created < rhs.created
                })[indexPath.row] else { return tokenCell }
                
                let currencySymbol = "\(symbol.lowercased())\(currency.symbol.lowercased())"

                tokenCell.symbolNicknameLabel.size16(text: "\(token.name.first?.uppercased() ?? "")" , color: .white, weight: .medium, align: .center)
                tokenCell.symbolView.backgroundColor = colorList[indexPath.row%12].background
                tokenCell.symbolLabel.size16(text: token.symbol, color: .gray77, weight: .semibold)
                tokenCell.fullnameLabel.size12(text: token.name, color: .gray179, weight: .light)
                
                let tokenBalance = Manager.balance.getTokenBalance(address: symbol == "icx" ? token.parent : token.parent.add0xPrefix(), contract: token.contract)
                tokenCell.balanceLabel.size16(text: tokenBalance?.toString(decimal: token.decimal, 4).currencySeparated() ?? "-", color: .gray77, weight: .bold, align: .right)
                
                let price = Tool.calculatePrice(decimal: token.decimal, currency: currencySymbol, balance: tokenBalance)
                tokenCell.unitBalanceLabel.size12(text: price, color: .gray179, weight: .light, align: .right)

                tokenCell.unitLabel.size12(text: currency.symbol, color: .gray179, weight: .light, align: .right)

                return tokenCell

            } else {
                guard let wallet = self.coinTokens?[indexPath.row] else { return walletCell }

                // token
                if let contractAddress = self.contractAddress, let decimal = self.tokenDecimal {

                    let currenySymbol = "\(symbol.lowercased())\(currency.symbol.lowercased())"
                    walletCell.nicknameLabel.size16(text: wallet.name, color: .gray77, weight: .semibold)
                    walletCell.addressLabel.size12(text: wallet.address, color: .gray179, weight: .light)

                    let tokenBalance = Manager.balance.getTokenBalance(address: wallet.address, contract: contractAddress)
                    walletCell.balanceLabel.size16(text: tokenBalance?.toString(decimal: decimal, 4).currencySeparated() ?? "-", color: .gray77, weight: .bold, align: .right)

                    let price = Tool.calculatePrice(decimal: decimal, currency: currenySymbol, balance: tokenBalance)
                    walletCell.currencyLabel.size12(text: price, color: .gray179, weight: .light, align: .right)
                    walletCell.currencyUnitLabel.size12(text: currency.symbol, color: .gray179, align: .right)

                } else { // coin
                    let currenySymbol = "\(symbol.lowercased())\(currency.symbol.lowercased())"

                    walletCell.nicknameLabel.size16(text: wallet.name, color: .gray77, weight: .semibold)
                    walletCell.addressLabel.size12(text: wallet.address, color: .gray179, weight: .light)

                    let balance = Manager.balance.getBalance(wallet: wallet)
                    walletCell.balanceLabel.size16(text: balance?.toString(decimal: 18, 4).currencySeparated() ?? "-", color: .gray77, weight: .bold, align: .right)

                    let price = Tool.calculatePrice(decimal: 18, currency: currenySymbol, balance: balance)
                    walletCell.currencyLabel.size12(text: price, color: .gray179, weight: .light, align: .right)
                    walletCell.currencyUnitLabel.size12(text: currency.symbol, color: .gray179, align: .right)
                }

                return walletCell
            }
        }
    }
}

extension MainCollectionViewCell: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let icxWallet = self.info as? ICXWallet else { return 82 }
        guard let staked = Manager.iiss.stake(icx: icxWallet), staked > 0 else { return 82 }
        
        if indexPath.section == 0 {
            return 162
        } else {
            return 82
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableview.deselectRow(at: indexPath, animated: true)
        
        let detailVC = UIStoryboard.init(name: "Detail", bundle: nil).instantiateInitialViewController() as! DetailViewController
        
        if indexPath.section == 0 {
            guard let wallet = self.info else { return }
            guard isWalletMode else { return }
            
            detailVC.walletInfo = wallet
            
            if let _ = wallet as? ICXWallet {
                detailVC.detailType = .icx
            } else {
                detailVC.detailType = .eth
            }
            
            
        } else {
            if isWalletMode {
                guard let wallet = self.info else { return }
                guard let token = wallet.tokens?.sorted(by: { (lhs, rhs) -> Bool in
                    return lhs.created < rhs.created
                })[indexPath.row] else { return }
                
                detailVC.tokenInfo = token
                detailVC.walletInfo = wallet
                
                if let _ = wallet as? ICXWallet {
                    detailVC.detailType = .irc
                } else {
                    detailVC.detailType = .erc
                }
            } else { // coin token
                guard let selectedWallet = self.coinTokens?[indexPath.row] else { return }
                detailVC.walletInfo = selectedWallet
                
                switch symbol {
                case "icx":
                    detailVC.detailType = .icx
                case "eth":
                    detailVC.detailType = .eth
                default:
                    guard let tokenList = selectedWallet.tokens else { return }
                    guard let tokenInfo = tokenList.filter({ $0.symbol == symbol }).first else { return }
                    detailVC.tokenInfo = tokenInfo
                    
                    if let _ = selectedWallet as? ICXWallet {
                        detailVC.detailType = .irc
                    } else {
                        detailVC.detailType = .erc
                    }
                }
            }
        }
        if let navVC: UINavigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            navVC.pushViewController(detailVC, animated: true)
        }
    }
}
