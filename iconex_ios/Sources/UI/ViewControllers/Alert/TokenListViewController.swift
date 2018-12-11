//
//  TokenListViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TokenListCell: UITableViewCell {
    @IBOutlet weak var tokenLabel: UILabel!
}

class TokenListViewController: UIViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noItemContainer: UIView!
    @IBOutlet weak var noItemLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    var walletInfo: WalletInfo?
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let wallet = WManager.loadWalletBy(info: walletInfo!)!
        noItemContainer.isHidden = wallet.tokens!.count != 0
        tableView.reloadData()
    }
    
    func initialize() {
        navTitle.text = "Token.Management".localized
        noItemLabel.text = "Token.Empty".localized
        addButton.styleDark()
        addButton.cornered()
        addButton.setTitle("Token.Add".localized, for: .normal)
        
        tableView.tableFooterView = UIView()
        
        addButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                let manage = UIStoryboard(name: "Menu", bundle: nil).instantiateViewController(withIdentifier: "TokenManageView") as! TokenManageViewController
                manage.walletInfo = self.walletInfo
                manage.manageMode = .add
                self.navigationController?.pushViewController(manage, animated: true)
            }).disposed(by: disposeBag)
        
        closeButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                self.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }
}

extension TokenListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let wallet = WManager.loadWalletBy(info: self.walletInfo!)
        return wallet!.tokens!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TokenListCell", for: indexPath) as! TokenListCell
        
        let wallet = WManager.loadWalletBy(info: self.walletInfo!)
        let tokenInfo = wallet!.tokens![indexPath.row]
        cell.tokenLabel.text = tokenInfo.name
        
        return cell
    }
}

extension TokenListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let wallet = WManager.loadWalletBy(info: self.walletInfo!)
        
        guard let tokens = wallet?.tokens else {
            return
        }
        
        let token = tokens[indexPath.row]
        
        let manage = UIStoryboard(name: "Menu", bundle: nil).instantiateViewController(withIdentifier: "TokenManageView") as! TokenManageViewController
        manage.selectedToken = token
        manage.walletInfo = self.walletInfo
        manage.manageMode = .modify
        self.navigationController?.pushViewController(manage, animated: true)
    }
}
