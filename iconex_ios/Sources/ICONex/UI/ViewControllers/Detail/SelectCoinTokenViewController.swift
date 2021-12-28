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

class SelectCoinTokenViewController: BaseViewController {

    @IBOutlet weak var dimmView: UIView!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    var walletInfo: BaseWalletConvertible? = nil {
        willSet {
            self.tokenList = newValue?.tokens?.sorted(by: { (lhs, rhs) -> Bool in
                return lhs.created > rhs.created
            })
        }
    }
    
    var tokenList: [Token]?
    
    var changedHandler: ((_ token: Token?) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBind()
        
        self.tableView.tableFooterView = UIView()
        
        dimmView.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        contentView.alpha = 0.0
        contentView.transform = CGAffineTransform(translationX: 0, y: 50)
    }
    
    private func setupUI() {
        titleLabel.size18(text: "Wallet.Detail.SelectCoinToken.Title".localized, color: .gray77, weight: .medium, align: .center)
    }
    
    private func setupBind() {
        dismissButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.beginClose()
        }.disposed(by: disposeBag)
        
        let tapGesture = UITapGestureRecognizer()
        
        dimmView.addGestureRecognizer(tapGesture)
        
        tapGesture.rx.event.bind { _ in
            self.beginClose()
        }.disposed(by: disposeBag)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        beginShow()
    }
}

extension SelectCoinTokenViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            if let handler = self.changedHandler {
                handler(nil)
            }
            
        } else {
            guard let tokenList = self.tokenList else { return }
            let token = tokenList[indexPath.row-1]
            
            if let handler = self.changedHandler {
                handler(token)
            }
        }
        
        self.beginClose()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

extension SelectCoinTokenViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let tokens = self.tokenList?.count ?? 0
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
            cell.balanceLabel.size14(text: balance.toString(decimal: 18, 4, true), color: .gray77, weight: .bold, align: .right)
            cell.usdPriceLabel.size12(text: price, color: .gray179, align: .right)
            
        } else {
            guard let token = self.tokenList?[indexPath.row - 1] else { return cell }
            cell.symbolLabel.size14(text: token.symbol, color: .gray77, weight: .bold)
            cell.fullNameLabel.size12(text: token.name, color: .gray179)
            
            let tokenBalance = Manager.balance.getTokenBalance(address: wallet.address, contract: token.contract)
            price = Tool.calculatePrice(decimal: token.decimal, currency: "\(token.symbol.lowercased())usd", balance: tokenBalance)
            let decimal = token.decimal
            cell.balanceLabel.size14(text: tokenBalance?.toString(decimal: decimal, 4, true) ?? "-", color: .gray77, weight: .bold, align: .right)
            
            cell.usdPriceLabel.size12(text: price, color: .gray179, align: .right)
        }
        
        cell.dollarLabel.isHidden = price == "-"
        
        return cell
    }

}

extension SelectCoinTokenViewController {
    func show() {
        app.topViewController()?.present(self, animated: false, completion: nil)
    }
    
    private func beginShow() {
        UIView.animateKeyframes(withDuration: 0.5, delay: 0.0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25, animations: {
                self.view.backgroundColor = UIColor(white: 0.0, alpha: 0.4)
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25, animations: {
                self.contentView.alpha = 1.0
                self.contentView.transform = .identity
            })
        }, completion: nil)
    }
    
    private func beginClose(_ completion: (() -> Void)? = nil) {
        UIView.animateKeyframes(withDuration: 0.5, delay: 0.0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25, animations: {
                self.contentView.alpha = 0.0
                self.contentView.transform = CGAffineTransform(translationX: 0, y: 50)
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25, animations: {
                self.view.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
            })
        }, completion: { _ in
            self.dismiss(animated: false, completion: {
                completion?()
            })
        })
    }
}
