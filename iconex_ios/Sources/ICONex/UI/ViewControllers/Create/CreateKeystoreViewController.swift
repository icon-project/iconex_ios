//
//  CreateKeystoreViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 02/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CreateKeystoreViewController: BaseViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var nameInputBox: IXInputBox!
    @IBOutlet weak var passwordInputBox: IXInputBox!
    @IBOutlet weak var confirmInputBox: IXInputBox!
    
    @IBOutlet weak var footerBox: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    @IBOutlet weak var descLabel: UILabel!
    
    var info: WalletInfo?
    
    var delegate: createWalletSequence! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        headerLabel.size16(text: "Create.Wallet.Step2.Header".localized, color: .gray77, weight: .medium, align: .center)
        
        nameInputBox.set(inputType: .name)
        nameInputBox.set(state: .normal, placeholder: "Create.Wallet.Step2.WalletName.Placeholder".localized)
        
        passwordInputBox.set(inputType: .createPassword)
        passwordInputBox.set(state: .normal, placeholder: "Create.Wallet.Step2.Password.Placeholder".localized)
        
        confirmInputBox.set(inputType: .confirmPassword)
        confirmInputBox.set(state: .normal, placeholder: "Create.Wallet.Step2.Confirm.Placeholder".localized)
        
        footerBox.border(0.5, .mint5)
        footerBox.corner(8)
        footerBox.backgroundColor = .mint4
        
        footerLabel.size12(text: "Create.Wallet.Step2.Footer".localized, color: .mint1, weight: .regular, align: .left)
        descLabel.size12(text: "Create.Wallet.Step2.Desc".localized, color: .mint1, weight: .light, align: .left)
        
        
        // validator
        nameInputBox.set { (inputValue) -> String? in
            guard !DB.canSaveWallet(name: inputValue) else { return nil }
            return "Error.Wallet.Duplicated.Name".localized
        }
        
        passwordInputBox.set { (value) -> String? in
            guard value.count != 0 else { return nil }
            guard value.count >= 8 else {
                return "Error.Password.Length".localized
            }
            guard Validator.validateSequenceNumber(password: value) else {
                return "Error.Password.Serialize".localized
            }
            guard Validator.validateCharacterSet(password: value) else {
                return "Error.Password.CharacterSet".localized
            }
            guard Validator.validateSpecialCharacter(password: value) else {
                return "Error.Password.Invaild.SpecialCharacter".localized
            }
            return nil
        }
        
        confirmInputBox.set { (confirm) -> String? in
            guard let password = self.passwordInputBox.textField.text else { return nil }
            guard confirm.count > 0 else { return nil }
            guard password == confirm else {
                return "Error.Password.Mismatch".localized
            }
            return nil
        }
        
        Observable.combineLatest(nameInputBox.textField.rx.text.orEmpty, passwordInputBox.textField.rx.text.orEmpty, confirmInputBox.textField.rx.text.orEmpty)
            .subscribe(onNext: { (name, password, confirm) in
                guard (self.delegate != nil) else { return }
                guard !name.isEmpty && !password.isEmpty && !confirm.isEmpty else {
                    self.delegate.invalidated()
                    return
                }
                guard DB.canSaveWallet(name: name) else {
                    self.delegate.invalidated()
                    return
                }
                guard password.count >= 8 else {
                    self.delegate.invalidated()
                    return
                }
                guard Validator.validateSequenceNumber(password: password) else {
                    self.delegate.invalidated()
                    return
                }
                guard Validator.validateCharacterSet(password: password) else {
                    self.delegate.invalidated()
                    return
                }
                guard Validator.validateSpecialCharacter(password: password) else {
                    self.delegate.invalidated()
                    return
                }
                if password != confirm {
//                    self.confirmInputBox.setError(message: "Error.Password.Mismatch".localized)
                    self.delegate.invalidated()
                    return
                }
                
                self.nameInputBox.setError(message: nil)
                self.passwordInputBox.setError(message: nil)
                self.confirmInputBox.setError(message: nil)
                self.delegate.validated()
                
                self.delegate.walletInfo = WalletInfo(name: name.removeContinuosSuffix(string: " "), password: password)
            }).disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        
        self.nameInputBox.setError(message: nil)
        self.passwordInputBox.setError(message: nil)
        self.confirmInputBox.setError(message: nil)
        
        self.nameInputBox.textField.text = ""
        self.passwordInputBox.textField.text = ""
        self.confirmInputBox.textField.text = ""
        self.info = nil
    }
}
