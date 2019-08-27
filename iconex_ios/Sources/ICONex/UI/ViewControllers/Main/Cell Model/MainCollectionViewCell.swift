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
    var contractAddress: String = ""
    
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
                guard let address = self.info?.address else { return }
                
                Alert.password(address: address, confirmAction: {
                    let scanVC = UIStoryboard.init(name: "Camera", bundle: nil).instantiateInitialViewController() as! QRReaderViewController
                    app.topViewController()?.present(scanVC, animated: true, completion: nil)
                }).show()
                
            }.disposed(by: disposeBag)
        
        qrcodeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let qrVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QRCode") as! MainQRCodeViewController
                qrVC.wallet = self.info
                qrVC.modalPresentationStyle = .overFullScreen
                qrVC.modalTransitionStyle = .flipHorizontal
                
                app.topViewController()?.present(qrVC, animated: true, completion: nil)

                
            }.disposed(by: disposeBag)
        
        infoButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let manageVC = UIStoryboard(name: "ManageWallet", bundle: nil).instantiateViewController(withIdentifier: "Manage") as! ManageWalletViewController
                manageVC.walletInfo = self.info
                manageVC.modalPresentationStyle = .overFullScreen
                manageVC.modalTransitionStyle = .crossDissolve
                manageVC.handler = self.handler
                app.topViewController()?.present(manageVC, animated: true, completion: nil)

            }.disposed(by: disposeBag)
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
        print("symbol \(symbol)")
        // cell
        let coinCell: CoinTableViewCell = {
            let cell = tableView.dequeueReusableCell(withIdentifier: "coinCell") as! CoinTableViewCell
            cell.corner(8)
            cell.border(0.5, .gray230)
            cell.basicView.backgroundColor = .gray252
//            cell.selectionStyle = .none
            return cell
        }()
        
        let tokenCell: TokenTableViewCell = {
            let cell = tableView.dequeueReusableCell(withIdentifier: "tokenCell") as! TokenTableViewCell
            cell.corner(8)
//            cell.selectionStyle = .none
            return cell
        }()
        
        let walletCell: WalletTableViewCell = {
            let cell = tableView.dequeueReusableCell(withIdentifier: "walletCell") as! WalletTableViewCell
            cell.corner(8)
//            cell.selectionStyle = .none
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
                    coinCell.balanceLabel.size16(text: "\(icx.balance ?? 0)", color: .gray77, weight: .bold, align: .right)
                    
                    let price = calculatePrice(currency: currencySymbol, balance: icx.balance ?? 0)
                    coinCell.unitBalanceLabel.size12(text: price, color: .gray179, align: .right)
                    
                } else if let eth = info as? ETHWallet {
                    let currencySymbol = "eth\(currency.symbol.lowercased())"
                    coinCell.logoImageView.image = #imageLiteral(resourceName: "imgLogoEthereumNor")
                    coinCell.symbolLabel.size16(text: CoinType.eth.symbol, color: .gray77, weight: .semibold)
                    coinCell.fullNameLabel.size12(text: CoinType.eth.fullName, color: .gray179, weight: .light)
                    coinCell.balanceLabel.size16(text: "\(eth.balance ?? 0)", color: .gray77, weight: .bold, align: .right)
                    
                    let price = calculatePrice(currency: currencySymbol, balance: eth.balance ?? 0)
                    coinCell.unitBalanceLabel.size12(text: price, color: .gray179, align: .right)
                }
                return coinCell
                
            } else { // total coin token info
                let currencySymbol = "\(symbol.lowercased())\(currency.symbol.lowercased())"
                print(currencySymbol)
                switch symbol {
                case "icx":
                    coinCell.unitLabel.size12(text: currency.symbol, color: .gray179, align: .right)
                    
                    coinCell.logoImageView.image = #imageLiteral(resourceName: "imgLogoIconSel")
                    coinCell.symbolLabel.size16(text: CoinType.icx.symbol, color: .gray77, weight: .semibold)
                    coinCell.fullNameLabel.size12(text: CoinType.icx.fullName, color: .gray179, weight: .light)
                    
                    guard let list = self.coinTokens else { return coinCell }
                    
                    var totalBalance: BigUInt = 0
                    for i in list {
                        totalBalance += i.balance ?? 0
                    }
                    
                    coinCell.balanceLabel.size16(text: String(totalBalance), color: .gray77, weight: .bold, align: .right)
                    
                    let price = calculatePrice(currency: currencySymbol , balance: totalBalance)
                    coinCell.unitBalanceLabel.size12(text: price, color: .gray179, weight: .light)
                    
                    return coinCell
                    
                case "eth":
                    coinCell.unitLabel.size12(text: currency.symbol, color: .gray179, align: .right)
                    
                    coinCell.logoImageView.image = #imageLiteral(resourceName: "imgLogoEthereumNor")
                    coinCell.symbolLabel.size16(text: CoinType.eth.symbol, color: .gray77, weight: .semibold)
                    coinCell.fullNameLabel.size12(text: CoinType.eth.fullName, color: .gray179, weight: .light)
                    
                    guard let list = self.coinTokens else { return coinCell }
                    
                    var totalBalance: BigUInt = 0
                    for i in list {
                        totalBalance += i.balance ?? 0
                    }
                    
                    coinCell.balanceLabel.size16(text: String(totalBalance), color: .gray77, weight: .bold, align: .right)
                    
                    let price = calculatePrice(currency: currencySymbol , balance: totalBalance)
                    coinCell.unitBalanceLabel.size12(text: price, color: .gray179, weight: .light)
                    
                    return coinCell
                    
                default:
                    tokenCell.corner(8)
                    tokenCell.border(0.5, .gray230)
                    tokenCell.contentView.backgroundColor = .gray252
                    
                    guard let list = self.coinTokens else { return tokenCell }
                    
                    var totalBalance: BigUInt = 0
                    
                    for i in list {
                        totalBalance += Manager.balance.getTokenBalance(address: i.address, contract: contractAddress)
                    }
                    
                    guard let nickName = symbol.first?.uppercased() else { return tokenCell }
                    tokenCell.symbolNicknameLabel.size16(text: nickName , color: .white, weight: .medium, align: .center)
                    tokenCell.symbolView.backgroundColor = colorList[indexPath.row%12].background // 임시
                    tokenCell.symbolLabel.size16(text: symbol, color: .gray77, weight: .semibold)
                    tokenCell.fullnameLabel.size12(text: fullName, color: .gray179, weight: .light)
                    
                    tokenCell.balanceLabel.size16(text: String(totalBalance) , color: .gray77, weight: .bold, align: .right)
                    
                    let price = calculatePrice(currency: currencySymbol, balance: totalBalance)
                    tokenCell.unitBalanceLabel.size12(text: price, color: .gray179, align: .right)
                    
                    tokenCell.unitLabel.size12(text: currency.symbol, color: .gray179, align: .right)
                    return tokenCell
                }
            }
            
        } else {
            if isWalletMode { // token token~~~
                guard let token = info?.tokens?[indexPath.row] else { return tokenCell }
                
                let currencySymbol = "\(symbol.lowercased())\(currency.symbol.lowercased())"
                
                tokenCell.symbolNicknameLabel.size16(text: "\(token.name.first?.uppercased() ?? "")" , color: .white, weight: .medium, align: .center)
                tokenCell.symbolView.backgroundColor = colorList[indexPath.row%12].background
                tokenCell.symbolLabel.size16(text: token.symbol, color: .gray77, weight: .semibold)
                tokenCell.fullnameLabel.size12(text: token.name, color: .gray179, weight: .light)
                
                let tokenBalance = Manager.balance.getTokenBalance(address: token.parent, contract: token.contract)
                tokenCell.balanceLabel.size16(text: "\(tokenBalance)", color: .gray77, weight: .bold, align: .right)
                let price = calculatePrice(currency: currencySymbol, balance: tokenBalance)
                tokenCell.unitBalanceLabel.size12(text: price, color: .gray179, weight: .light, align: .right)
                
                tokenCell.unitLabel.size12(text: currency.symbol, color: .gray179, weight: .light, align: .right)
                
                return tokenCell
                
            } else {
                guard let val = self.coinTokens?[indexPath.row] else { return walletCell }
                let currenySymbol = "\(symbol.lowercased())\(currency.symbol.lowercased())"
                walletCell.nicknameLabel.size16(text: val.name, color: .gray77, weight: .semibold)
                walletCell.addressLabel.size12(text: val.address, color: .gray179, weight: .light)
                walletCell.balanceLabel.size16(text: String(val.balance ?? 0), color: .gray77, weight: .bold, align: .right)
                
                let price = calculatePrice(currency: currenySymbol, balance: val.balance ?? 0)
                walletCell.currencyLabel.size12(text: price, color: .gray179, weight: .light, align: .right)
                walletCell.currencyUnitLabel.size12(text: currency.symbol, color: .gray179, align: .right)
                return walletCell
            }
        }
    }
}

extension MainCollectionViewCell: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 82
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableview.deselectRow(at: indexPath, animated: true)
        
        if isWalletMode {
//            guard let address = self.info?.address else { return }
            
//            let detailVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Detail")
        }
        
    }
}

extension MainCollectionViewCell {
    func calculatePrice(currency: String, balance: BigUInt) -> String { // icxusd, icxeth.....
        guard let exchange = Manager.exchange.exchangeInfoList[currency]?.price else { return "-" }
        let price = Float(exchange) ?? 0
        let exchanged = Float(balance)*price
        return String(exchanged)
    }
}
