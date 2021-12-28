//
//  ManageTokenViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 26/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ManageTokenViewController: BaseViewController {

    @IBOutlet weak var navBar: IXNavigationView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var addButton: UIButton!
    
    var handler: (() -> Void)?
    
    var walletInfo: BaseWalletConvertible? = nil
    var tokenList = PublishSubject<[Token]>()
    var isICX: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let wallet = self.walletInfo else { return }
        let list = try! DB.tokenList(dependedAddress: wallet.address)
        
        tokenList.onNext(list)
        
        self.tableView.estimatedRowHeight = 60
        self.tableView.rowHeight = 60
        
        setupBind()
        
        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarCloseW")) {
            self.dismiss(animated: true, completion: {
                if let handler = self.handler {
                    handler()
                }
            })
        }
        
        navBar.setTitle("ManageToken.Title".localized)
        addButton.setTitle("ManageToken.Add".localized, for: .normal)
        addButton.round02()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let address = walletInfo?.address else { return }
        if let list = try? DB.tokenList(dependedAddress: address) {
            self.tokenList.onNext(list)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    private func setupBind() {
        addButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                if let _ = self.walletInfo as? ICXWallet {
                    let addTokenVC = self.storyboard?.instantiateViewController(withIdentifier: "AddTokenList") as! AddTokenViewController
                    addTokenVC.walletInfo = self.walletInfo
                    self.navigationController?.pushViewController(addTokenVC, animated: true)
                } else {
                    let addTokenInfoVC =  self.storyboard?.instantiateViewController(withIdentifier: "AddTokenInfo") as! AddTokenInfoViewController
                    addTokenInfoVC.walletInfo = self.walletInfo
                    self.navigationController?.pushViewController(addTokenInfoVC, animated: true)
                }
                
            }.disposed(by: disposeBag)
        
        // empty
        tokenList.subscribe(onNext: { (list) in
            if list.count == 0 {
                let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
                messageLabel.size14(text: "ManageToken.Empty".localized, color: .gray77, align: .center)
                
                self.tableView.backgroundView = messageLabel
                self.tableView.separatorStyle = .none
            } else {
                self.tableView.backgroundView = nil
            }
        }).disposed(by: disposeBag)
        
        tokenList.observeOn(MainScheduler.instance)
            .bind(to: tableView.rx.items(cellIdentifier: "manageCell", cellType: ManageTokenTableViewCell.self)) {
            (_, item, cell) in
                
            cell.nameLabel.size14(text: item.name, color: .gray77)
        }.disposed(by: disposeBag)
        
        tableView.rx.modelSelected(Token.self).asControlEvent()
            .subscribe(onNext: { (token) in
                let tokenDetailVC = self.storyboard?.instantiateViewController(withIdentifier: "TokenDetail") as! TokenDetailViewController
                tokenDetailVC.tokenInfo = token
                self.navigationController?.pushViewController(tokenDetailVC, animated: true)
                
            }).disposed(by: disposeBag)
    }
}

extension ManageWalletViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
