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
                UIView.animate(withDuration: 0.2, animations: {
                    
                    self.dismiss(animated: true, completion: {
                        guard let wallet = self.walletInfo else { return }
                        
                        Alert.changeWalletName(wallet: wallet, confirmAction: {
                            self.dismiss(animated: true, completion: {
                                if let handler = self.handler {
                                    handler()
                                }
                            })
                        }).show()
                    })
                }, completion: nil)
            }.disposed(by: disposeBag)
        
        addTokenButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                UIView.animate(withDuration: 0.2, animations: {
                    self.dismiss(animated: true, completion: {
                        let tokenVC = UIStoryboard.init(name: "ManageWallet", bundle: nil).instantiateViewController(withIdentifier: "TokenList") as! ManageTokenViewController
                        tokenVC.walletInfo = wallet
                        
                        tokenVC.handler = {
                            if let handler = self.handler {
                                handler()
                            }
                        }
                        let navRootVC = UINavigationController(rootViewController: tokenVC)
                        navRootVC.isNavigationBarHidden = true
                        app.topViewController()?.present(navRootVC, animated: true, completion: nil)
                    })
                    
                }, completion: nil)

                
        }.disposed(by: disposeBag)
        
        backupButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                guard let wallet = self.walletInfo else { return }
                
                UIView.animate(withDuration: 0.2, animations: {
                    self.dismiss(animated: true, completion: {
                        
                        Alert.password(wallet: wallet, returnAction: { (privateKey) in
                            let backUpVC = UIStoryboard(name: "ManageWallet", bundle: nil).instantiateViewController(withIdentifier: "BackUp") as! ManageBackUpViewController
                            backUpVC.wallet = self.walletInfo
                            backUpVC.pk = privateKey
                            app.topViewController()?.present(backUpVC, animated: true, completion: nil)
                        }).show()
                    })
                }, completion: nil)
                
        }.disposed(by: disposeBag)
        
        changePasswordButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                UIView.animate(withDuration: 0.2, animations: {
                    self.dismiss(animated: true, completion: {
                        let changePasswordVC = UIStoryboard(name: "ManageWallet", bundle: nil).instantiateViewController(withIdentifier: "ChangePassword") as! ChangePasswordViewController
                        changePasswordVC.wallet = self.walletInfo
                        
                        app.topViewController()?.present(changePasswordVC, animated: true, completion: nil)
                    })
                }, completion: nil)
            }.disposed(by: disposeBag)
        
        
        // Delete wallet
        removeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                UIView.animate(withDuration: 0.2, animations: {
                    self.dismiss(animated: true, completion: {
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
                            
                        } else {
                            Alert.basic(title: "Manage.Alert.Wallet".localized, isOnlyOneButton: false, confirmAction: {
                                do {
                                    self.dismiss(animated: true, completion: {
                                        Alert.password(wallet: wallet, returnAction: { (_) in
                                            do {
                                                try DB.deleteWallet(wallet: wallet)
                                                
                                                self.dismiss(animated: true, completion: {
                                                    if let handler = self.handler {
                                                        handler()
                                                    }
                                                })
                                            } catch {
                                            }
                                        }).show()
                                    })
                                }
                            }).show()
                        }
                    })
                }, completion: nil)
                
            }.disposed(by: disposeBag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

}
