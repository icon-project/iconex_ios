//
//  ChangePasswordViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 28/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ChangePasswordViewController: BaseViewController {

    @IBOutlet weak var navBar: IXNavigationView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var currentBox: IXInputBox!
    @IBOutlet weak var newBox: IXInputBox!
    @IBOutlet weak var confirmBox: IXInputBox!
    @IBOutlet weak var attentionView: UIView!
    @IBOutlet weak var attentionLabel: UILabel!
    @IBOutlet weak var footerDescLabel: UILabel!
    @IBOutlet weak var changeButton: UIButton!
    
    var wallet: BaseWalletConvertible? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBind()
    }
    
    private func setupUI() {
        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarCloseW")) {
            self.view.endEditing(true)
            self.dismiss(animated: true, completion: nil)
        }
        navBar.setTitle("ChangePassword.NavBar.Title".localized)
        
        titleLabel.size16(text: "ChangePassword.Title".localized, color: .gray77, weight: .medium, align: .center)
        
        currentBox.set(inputType: .confirmPassword)
        newBox.set(inputType: .createPassword)
        confirmBox.set(inputType: .confirmPassword)
        
        currentBox.set(state: .normal, placeholder: "ChangePassword.Password.Current".localized)
        newBox.set(state: .normal, placeholder: "ChangePassword.Password.New".localized)
        confirmBox.set(state: .normal, placeholder: "ChangePassword.Password.Confirm".localized)
        
        attentionView.mintBox()
        attentionLabel.size12(text: "ChangePassword.Desc1".localized, color: .mint1)
        footerDescLabel.size12(text: "ChangePassword.Desc1".localized, color: .mint1, weight: .light)
        
        changeButton.isEnabled = false
        changeButton.setTitle("Common.Change".localized, for: .normal)
        changeButton.lightMintRounded()
    }
    
    private func setupBind() {
        guard let wallet = self.wallet else { return }
        
        currentBox.set { (password) -> String? in
            guard !password.isEmpty else { return nil }
            do {
                if let icx = wallet as? ICXWallet {
                    let _ = try icx.extractICXPrivateKey(password: password)
                } else if let eth = wallet as? ETHWallet {
                    let _ = try eth.extractETHPrivateKey(password: password)
                }
                return nil
            } catch {
                return "Error.Password.Wrong".localized
            }
        }
        
        newBox.set { (password) -> String? in
            guard !password.isEmpty else { return nil }
            guard password.count >= 8 else {
                return "Error.Password.Length".localized
            }
            guard Validator.validateSequenceNumber(password: password) else {
                return "Error.Password.Serialize".localized
            }
            guard Validator.validateCharacterSet(password: password) else {
                return "Error.Password.CharacterSet".localized
            }
            
            let currentPassword = self.currentBox.text
            do {
                if let icx = wallet as? ICXWallet {
                    let _ = try icx.extractICXPrivateKey(password: currentPassword)
                } else if let eth = wallet as? ETHWallet {
                    let _ = try eth.extractETHPrivateKey(password: currentPassword)
                } else {
                    return nil
                }
                
                guard currentPassword != password else {
                    return "ChangePassword.Password.Error.SamePassword".localized
                }
                return nil
                
            } catch {
                return nil
            }
        }
        
        confirmBox.set { (password) -> String? in
            guard !password.isEmpty else { return nil }
            guard password == self.newBox.text else {
                return "Error.Password.Mismatch".localized
            }
            return nil
        }
        
        
        Observable.combineLatest(self.currentBox.textField.rx.text.orEmpty, self.newBox.textField.rx.text.orEmpty, self.confirmBox.textField.rx.text.orEmpty).flatMapLatest { (current, new, confirm) -> Observable<Bool> in
            guard !current.isEmpty && !new.isEmpty && !confirm.isEmpty else { return Observable.just(false) }
            
            do {
                if let icx = wallet as? ICXWallet {
                    let _ = try icx.extractICXPrivateKey(password: current)
                } else if let eth = wallet as? ETHWallet {
                    let _ = try eth.extractETHPrivateKey(password: current)
                }
            } catch {
                return Observable.just(false)
            }
            
            // same
            guard current != new else { return Observable.just(false) }
            
            // minimum length
            guard new.count >= 8 else { return Observable.just(false) }
            
            // correct
            guard Validator.validateCharacterSet(password: new) && Validator.validateSequenceNumber(password: new) else {
                return Observable.just(false)
            }
            guard new == confirm else { return Observable.just(false) }
            
            return Observable.just(true)
            
        }.bind(to: self.changeButton.rx.isEnabled)
        .disposed(by: disposeBag)
        
        
        changeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let currentPassword = self.currentBox.text
                let newPassword = self.confirmBox.text
                
                do {
                    if let icx = wallet as? ICXWallet {
                        print(icx.keystore)
                        try DB.changeWalletPassword(wallet: wallet, oldPassword: currentPassword, newPassword: newPassword)
                    } else if let eth = wallet as? ETHWallet {
                        try eth.changePassword(oldPassword: currentPassword, newPassword: newPassword)
                    }
                    
                    Alert.basic(title: "Alert.Password.Changed".localized, leftButtonTitle: "Common.Confirm".localized, confirmAction: {
                        self.dismiss(animated: true, completion: nil)
                    }).show()
                    
                } catch let err {
                    Log(err)
                }
        }.disposed(by: disposeBag)
        
        keyboardHeight().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] (height: CGFloat) in
                if height == 0 {
                    self.scrollView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                } else {
                    var keyboardHeight: CGFloat = height
                    if #available(iOS 11.0, *) {
                        keyboardHeight = keyboardHeight - self.view.safeAreaInsets.bottom
                    }
                    self.scrollView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
                }
            }).disposed(by: disposeBag)
    }
}
