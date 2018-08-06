//
//  ForgotViewController.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ForgotViewCell: UITableViewCell {
    @IBOutlet weak var walletName: UILabel!
    
}

class ForgotViewController: BaseViewController {
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }
    
    func initialize() {
        tableView.tableFooterView = UIView()
        
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        navTitle.text = "Passcode.Reset".localized
        headerLabel.text = "Passcode.Reset.withWallet".localized
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ForgotViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return WManager.walletInfoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ForgotViewCell", for: indexPath) as! ForgotViewCell
        
        let walletInfo = WManager.walletInfoList[indexPath.row]
        if let wallet = WManager.loadWalletBy(info: walletInfo) {
            cell.walletName.text = wallet.alias
            
        }
        
        return cell
    }
}

extension ForgotViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let walletInfo = WManager.walletInfoList[indexPath.row]
        Alert.checkPassword(walletInfo: walletInfo) { [weak self] (isSuccess, _ ) in
            if isSuccess {
                let createLock = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "CreateLockView") as! CreateLockViewController
                createLock.mode = CreateLockViewController.CreateLockMode.recreate
                self?.navigationController?.pushViewController(createLock, animated: true)
            }
        }.show(self)
    }
}
