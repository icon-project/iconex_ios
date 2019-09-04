//
//  ExportPasswordViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 03/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ExportPasswordViewController: BaseViewController {
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var passwordBox: IXInputBox!
    @IBOutlet weak var confirmBox: IXInputBox!
    @IBOutlet weak var descContainer: UIView!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var postscriptLabel: UILabel!
    
    var delegate: ExportWalletSequence!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        headerLabel.size16(text: "ExportPassword.Header".localized, color: .gray77, weight: .medium, align: .center, lineBreakMode: .byWordWrapping)
        headerLabel.numberOfLines = 0
        
        passwordBox.set(state: .normal, placeholder: "Placeholder.InputPassword".localized)
        passwordBox.set(inputType: .createPassword)
        confirmBox.set(state: .normal, placeholder: "Placeholder.ConfirmPassword".localized)
        confirmBox.set(inputType: .confirmPassword)
        
        descContainer.corner(8)
        descContainer.backgroundColor = .mint4
        descContainer.border(0.5, .mint3)
        
        descLabel.size12(text: "ExportPassword.Desc".localized, color: .mint1, lineBreakMode: .byWordWrapping)
        descLabel.numberOfLines = 0
        
        postscriptLabel.size12(text: "ExportPassword.PostScript".localized, color: .mint1, weight: .light, lineBreakMode: .byWordWrapping)
        postscriptLabel.numberOfLines = 0
        
        passwordBox.set(validator: { value in
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
            return nil
        })
        
        confirmBox.set(validator: { confirm in
            guard let password = self.passwordBox.textField.text else { return nil }
            guard confirm.count > 0 else { return nil }
            guard password == confirm else {
                return "Error.Password.Mismatch".localized
            }
            return nil
        })
        
        Observable.combineLatest(passwordBox.textField.rx.text.orEmpty, confirmBox.textField.rx.text.orEmpty)
            .subscribe(onNext: { password, confirm in
                guard self.delegate != nil else { return }
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
                if password != confirm {
                    self.delegate.invalidated()
                    return
                }
                self.delegate.set(password: self.passwordBox.text)
                self.delegate.validated()
            }).disposed(by: disposeBag)
    }
    
    func resetData() {
        passwordBox.set(state: .normal)
        passwordBox.text = ""
        confirmBox.set(state: .normal)
        confirmBox.text = ""
    }
}

extension ExportPasswordViewController {
    
}
