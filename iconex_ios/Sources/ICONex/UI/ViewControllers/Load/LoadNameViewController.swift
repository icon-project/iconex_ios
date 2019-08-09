//
//  LoadNameViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 05/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class LoadNameViewController: BaseViewController {
    @IBOutlet weak var loadNameHeader: UILabel!
    @IBOutlet weak var inputBox1: IXInputBox!
    @IBOutlet weak var inputBox2: IXInputBox!
    @IBOutlet weak var inputBox3: IXInputBox!
    @IBOutlet weak var descContainer: UIView!
    @IBOutlet weak var bottomDesc1: UILabel!
    @IBOutlet weak var bottomDesc2: UILabel!
    
    var delegate: loadWalletSequence! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
    }
    
    override func refresh() {
        super.refresh()
        
        guard let loader = delegate.loader else { return }
        
        inputBox1.set(state: .normal, placeholder: "Placeholder.WalletName".localized)
        inputBox1.set(inputType: .name)
        inputBox2.set(state: .normal, placeholder: "Placeholder.InputPassword".localized)
        inputBox2.set(inputType: .createPassword)
        inputBox3.set(state: .normal, placeholder: "Placeholder.ConfirmPassword".localized)
        inputBox3.set(inputType: .confirmPassword)
        
        switch delegate.selectedMode() {
        case .loadFile:
            if loader.type == .wallet {
                loadNameHeader.size16(text: "LoadName.Wallet.Header".localized, color: .gray77, weight: .medium, align: .center)
                inputBox1.set(validator: { text in
                    if let nameError = self.validateName() {
                        return nameError
                    }
                    self.delegate.validated()
                    return nil
                })
                inputBox2.isHidden = true
                inputBox3.isHidden = true
                descContainer.isHidden = true
            } else {
                loadNameHeader.size16(text: "LoadName.Bundle.Header".localized, color: .gray77, weight: .medium, align: .center)
                inputBox2.isHidden = false
                inputBox2.isHidden = false
                descContainer.isHidden = false
            }
            
        case .loadPK:
            loadNameHeader.size16(text: "LoadName.PK.Header".localized, color: .gray77, weight: .medium, align: .center)
            
            inputBox2.isHidden = false
            inputBox3.isHidden = false
            descContainer.isHidden = false
            bottomDesc1.size12(text: "LoadName.PK.Desc1".localized, color: .mint1, weight: .light, align: .left)
            bottomDesc2.size12(text: "LoadName.PK.Desc2".localized, color: .mint1, weight: .light, align: .left)
            
            inputBox1.set(validator: { text in
                if let error = self.validateName() {
                    return error
                }
                if self.delegate.selectedMode() == .loadFile {
                    self.delegate.validated()
                } else {
                    if self.validatePassword() == nil, self.validateConfirm() == nil {
                        self.delegate.validated()
                    }
                }
                return nil
            })
            inputBox2.set(validator: { text in
                if let error = self.validatePassword() {
                    return error
                }
                if self.validateName() == nil, self.validateConfirm() == nil {
                    self.delegate.validated()
                }
                return nil
            })
            inputBox3.set(validator: { text in
                if let error = self.validateConfirm() {
                    return error
                }
                if self.validateName() == nil, self.validatePassword() == nil {
                    self.delegate.validated()
                }
                return nil
            })
        }
    }
}

extension LoadNameViewController {
    func validateName() -> String? {
        let text = inputBox1.text
        guard text.count > 0 else {
            self.delegate.invalidated()
            return text
        }
        guard DB.canSaveWallet(name: text.removeContinuosSuffix(string: " ")) else {
            self.delegate.invalidated()
            return "Error.Wallet.Duplicated.Name".localized
        }
        delegate.loader?.name = text
        return nil
    }
    
    func validatePassword() -> String? {
        let text = inputBox2.text
        guard text.count > 0 else {
            self.delegate.invalidated()
            return text
        }
        guard text.count >= 8 else {
            delegate.invalidated()
            return "Error.Password.Length".localized
        }
        guard Validator.validateCharacterSet(password: text) else {
            delegate.invalidated()
            return "Error.Password.CharacterSet".localized
        }
        guard Validator.validateSequenceNumber(password: text) else {
            delegate.invalidated()
            return "Error.Password.Serialize".localized
        }
        return nil
    }
    
    func validateConfirm() -> String? {
        let text1 = inputBox2.text, text2 = inputBox3.text
        guard text1 == text2 else {
            delegate.invalidated()
            return "Error.Password.Mismatch".localized
        }
        delegate.loader?.password = text1
        return nil
    }
}
