//
//  ManageWalletViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 26/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class ManageWalletViewController: BaseViewController {

    @IBOutlet weak var titleBar: UIView!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var addTokenButton: UIButton!
    @IBOutlet weak var backupButton: UIButton!
    @IBOutlet weak var changePasswordButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    
    var walletInfo: BaseWalletConvertible? = nil
    var handler: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.size18(text: "Manage.Title".localized, color: .gray77, weight: .medium, align: .center)
        
        dismissButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
        guard let wallet = self.walletInfo else { return }
        
        editButton.setTitle(wallet.name, for: .normal)
        addTokenButton.setTitle("Manage.Token".localized, for: .normal)
        backupButton.setTitle("Manage.Backup".localized, for: .normal)
        changePasswordButton.setTitle("Manage.Change".localized, for: .normal)
        removeButton.setTitle("Manage.Delete".localized, for: .normal)
        
        editButton.setTitleColor(.gray77, for: .normal)
        addTokenButton.setTitleColor(.gray77, for: .normal)
        backupButton.setTitleColor(.gray77, for: .normal)
        changePasswordButton.setTitleColor(.gray77, for: .normal)
        removeButton.setTitleColor(.gray77, for: .normal)
        
        
        editButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        addTokenButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        backupButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        changePasswordButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        removeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        
        
        editButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                Alert.changeWalletName(walletName: wallet.name, confirmAction: {
                    self.dismiss(animated: true, completion: {
                        if let handler = self.handler {
                            handler()
                        }
                    })
                }).show()
            }.disposed(by: disposeBag)
        
        addTokenButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let tokenVC = UIStoryboard.init(name: "ManageWallet", bundle: nil).instantiateViewController(withIdentifier: "TokenList") as! ManageTokenViewController
                tokenVC.walletInfo = wallet
                
                tokenVC.handler = {
                    if let handler = self.handler {
                        handler()
                    }
                }

                let navRootVC = UINavigationController(rootViewController: tokenVC)
                navRootVC.isNavigationBarHidden = true
                self.present(navRootVC, animated: true, completion: nil)

                
        }.disposed(by: disposeBag)
        
        changePasswordButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                
            }.disposed(by: disposeBag)
        
        
        // Delete wallet
        removeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
//                print("잔액 \(wallet.balance)") // 아무것도 없는 경우 nil이 들어가있음 주의~~~
                // 삭제하시겠습니까?
                if wallet.balance == 0 || wallet.balance == nil {
                    Alert.basic(title: "Manage.Alert.Wallet.Empty".localized, isOnlyOneButton: false, confirmAction: {
                        do {
                            try DB.deleteWallet(wallet: wallet)
                            self.dismiss(animated: true, completion: {
                                if let handler = self.handler {
                                    handler()
                                }
                            })
                        } catch {
                            print("err")
                        }
                    }).show()
                    
                } else { // 잔액이 있는데 삭제하시겠습니까?
                    Alert.basic(title: "Manage.Alert.Wallet".localized, isOnlyOneButton: false, confirmAction: {
                        do {
                            self.dismiss(animated: true, completion: {
                                Alert.password(address: wallet.address, confirmAction: {
                                    do {
                                        try DB.deleteWallet(wallet: wallet)
                                        
                                        self.dismiss(animated: true, completion: {
                                            if let handler = self.handler {
                                                handler()
                                            }
                                        })
                                    } catch {
                                        print("err")
                                    }
                                }).show()
                            })
                        }
                    }).show()
                }
            }.disposed(by: disposeBag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

}
