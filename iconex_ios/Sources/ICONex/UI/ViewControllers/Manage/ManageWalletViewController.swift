//
//  ManageWalletViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 26/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class ManageWalletViewController: BaseViewController {

    @IBOutlet weak var dismissView: UIView!
    @IBOutlet weak var menuContainer: UIView!
    @IBOutlet weak var bottomView: UIView!
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
                self.beginClose(nil)
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
        
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        menuContainer.alpha = 0.0
        menuContainer.transform = CGAffineTransform(translationX: 0, y: 50)
        bottomView.alpha = 0.0
        bottomView.transform = CGAffineTransform(translationX: 0, y: 50)
        
        editButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.beginClose {
                    guard let wallet = self.walletInfo else { return }
                    
                    Alert.changeWalletName(wallet: wallet, confirmAction: {
                        mainViewModel.reload.onNext(true)
                        self.handler?()
                    }).show()
                }
            }.disposed(by: disposeBag)
        
        addTokenButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.beginClose {
                    let tokenVC = UIStoryboard.init(name: "ManageWallet", bundle: nil).instantiateViewController(withIdentifier: "TokenList") as! ManageTokenViewController
                    tokenVC.walletInfo = wallet
                    
                    tokenVC.handler = {
                        if let handler = self.handler {
                            handler()
                        }
                    }
                    let navRootVC = UINavigationController(rootViewController: tokenVC)
                    navRootVC.isNavigationBarHidden = true
                    navRootVC.modalPresentationStyle = .fullScreen
                    app.topViewController()?.present(navRootVC, animated: true, completion: nil)
                }
        }.disposed(by: disposeBag)
        
        backupButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                guard let wallet = self.walletInfo else { return }
                self.beginClose {
                    Alert.password(wallet: wallet, returnAction: { (privateKey) in
                        let backUpVC = UIStoryboard(name: "ManageWallet", bundle: nil).instantiateViewController(withIdentifier: "BackUp") as! ManageBackUpViewController
                        backUpVC.wallet = self.walletInfo
                        backUpVC.pk = privateKey
                        backUpVC.modalPresentationStyle = .fullScreen
                        app.topViewController()?.present(backUpVC, animated: true, completion: nil)
                    }).show()
                }
                
        }.disposed(by: disposeBag)
        
        changePasswordButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.beginClose {
                    let changePasswordVC = UIStoryboard(name: "ManageWallet", bundle: nil).instantiateViewController(withIdentifier: "ChangePassword") as! ChangePasswordViewController
                    changePasswordVC.wallet = self.walletInfo
                    changePasswordVC.modalPresentationStyle = .fullScreen
                    app.topViewController()?.present(changePasswordVC, animated: true, completion: nil)
                }
            }.disposed(by: disposeBag)
        
        
        // Delete wallet
        removeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.beginClose {
                    if wallet.balance == 0 || wallet.balance == nil {
                        Alert.basic(title: "Manage.Alert.Wallet.Empty".localized, isOnlyOneButton: false, confirmAction: {
                            do {
                                try DB.deleteWallet(wallet: wallet)
                                mainViewModel.reload.onNext(true)
                                mainViewModel.noti.onNext(true)
                                if Manager.wallet.walletList.count > 0 {
                                    self.handler?()
                                } else {
                                    let start = UIStoryboard(name: "Intro", bundle: nil).instantiateViewController(withIdentifier: "StartView")
                                    app.change(root: start)
                                }
                            } catch let error {
                                Log(error, .error)
                            }
                        }).show()
                        
                    } else {
                        Alert.basic(title: "Manage.Alert.Wallet".localized, isOnlyOneButton: false, confirmAction: {
                            do {
                                if Manager.wallet.walletList.count > 0 {
                                    Alert.password(wallet: wallet, returnAction: { (_) in
                                        do {
                                            try DB.deleteWallet(wallet: wallet)
                                            mainViewModel.reload.onNext(true)
                                            mainViewModel.noti.onNext(true)
                                            self.handler?()
                                        } catch let error {
                                            Log(error, .error)
                                        }
                                    }).show()
                                } else {
                                    let start = UIStoryboard(name: "Intro", bundle: nil).instantiateViewController(withIdentifier: "StartView")
                                    app.change(root: start)
                                }
                            }
                        }).show()
                    }
                }
                
            }.disposed(by: disposeBag)
        
        let tapGesture = UITapGestureRecognizer()
        
        self.dismissView.addGestureRecognizer(tapGesture)
        
        tapGesture.rx.event.bind { (recognizer) in
            self.beginClose(nil)
        }.disposed(by: disposeBag)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        beginShow()
    }
}

extension ManageWalletViewController {
    private func beginShow() {
        UIView.animateKeyframes(withDuration: 0.5, delay: 0.0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25, animations: {
                self.view.backgroundColor = UIColor(white: 0.0, alpha: 0.4)
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25, animations: {
                self.menuContainer.alpha = 1.0
                self.menuContainer.transform = .identity
                self.bottomView.alpha = 1.0
                self.bottomView.transform = .identity
            })
        }, completion: nil)
    }
    
    private func beginClose(_ completion: (() -> Void)?) {
        UIView.animateKeyframes(withDuration: 0.5, delay: 0.0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25, animations: {
                self.menuContainer.transform = CGAffineTransform(translationX: 0, y: 50)
                self.menuContainer.alpha = 0.0
                self.bottomView.transform = CGAffineTransform(translationX: 0, y: 50)
                self.bottomView.alpha = 0.0
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
    
    func show() {
        app.topViewController()?.present(self, animated: false, completion: nil)
    }
}
