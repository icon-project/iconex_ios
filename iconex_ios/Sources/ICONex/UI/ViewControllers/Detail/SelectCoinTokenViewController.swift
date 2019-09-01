//
//  SelectCoinTokenViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 29/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import BigInt

class SelectCoinTokenViewController: UIViewController {

    @IBOutlet weak var dimmView: UIView!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    var disposeBag = DisposeBag()
    
    var walletInfo: BaseWalletConvertible? = nil
    
    var changedHandler: ((_ token: Token?) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBind()
        
        self.tableView.tableFooterView = UIView()
    }
    
    private func setupUI() {
        titleLabel.size18(text: "Wallet.Detail.SelectCoinToken.Title".localized, color: .gray77, weight: .medium, align: .center)
    }
    
    private func setupBind() {
        dismissButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
    }
}

extension SelectCoinTokenViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        guard let wallet = self.walletInfo else { return }
        
        if indexPath.row == 0 {
            detailViewModel.token.onNext(nil)
            if let _ = wallet as? ICXWallet {
                detailViewModel.symbol.onNext(CoinType.icx.symbol)
                detailViewModel.fullName.onNext(CoinType.icx.fullName)
            } else {
                detailViewModel.symbol.onNext(CoinType.eth.symbol)
                detailViewModel.fullName.onNext(CoinType.eth.fullName)
            }
            if let handler = self.changedHandler {
                handler(nil)
            }
            
        } else {
            guard let tokenList = wallet.tokens else { return }
            let token = tokenList[indexPath.row-1]
            
            detailViewModel.token.onNext(token)
            detailViewModel.symbol.onNext(token.symbol)
            detailViewModel.fullName.onNext(token.name)
            
            if let handler = self.changedHandler {
                handler(token)
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

extension SelectCoinTokenViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let tokens = self.walletInfo?.tokens?.count ?? 0
        return tokens + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "selectCell") as! SelectCoinTokenTableViewCell
        
        guard let wallet = self.walletInfo else { return cell }
        
        var price: String = "-"
        var balance: BigUInt = 0
        
        if indexPath.row == 0 {
            if let _ = wallet as? ICXWallet {
                cell.symbolLabel.size14(text: CoinType.icx.symbol, color: .gray77, weight: .bold)
                cell.fullNameLabel.size12(text: CoinType.icx.fullName, color: .gray179)
                balance = wallet.balance ?? 0
                price = Tool.calculatePrice(decimal: 18, currency: "\(CoinType.icx.symbol.lowercased())usd", balance: balance)
            } else {
                cell.symbolLabel.size14(text: CoinType.eth.symbol, color: .gray77, weight: .bold)
                cell.fullNameLabel.size12(text: CoinType.eth.fullName, color: .gray179)
                balance = wallet.balance ?? 0
                price = Tool.calculatePrice(decimal: 18, currency: "\(CoinType.eth.symbol.lowercased())usd", balance: balance)
            }
            
            let balance = wallet.balance ?? 0
            cell.balanceLabel.size14(text: balance.toString(decimal: 18, 18, true), color: .gray77, weight: .bold, align: .right)
            cell.usdPriceLabel.size12(text: price, color: .gray179, align: .right)
            
        } else {
            guard let token = wallet.tokens?[indexPath.row-1] else { return cell }
            cell.symbolLabel.size14(text: token.symbol, color: .gray77, weight: .bold)
            cell.fullNameLabel.size12(text: token.name, color: .gray179)
            
            let tokenBalance = Manager.balance.getTokenBalance(address: wallet.address, contract: token.contract)
            price = Tool.calculatePrice(decimal: token.decimal, currency: "\(token.symbol.lowercased())usd", balance: tokenBalance)
            let decimal = token.decimal
            cell.balanceLabel.size14(text: tokenBalance.toString(decimal: decimal, decimal, true), color: .gray77, weight: .bold, align: .right)
            
            cell.usdPriceLabel.size12(text: price, color: .gray179, align: .right)
        }
        
        cell.dollarLabel.isHidden = price == "-"
        
        return cell
    }

}