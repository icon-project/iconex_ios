//
//  ChangeNameViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ChangeNameViewController: UIViewController {
    @IBOutlet private weak var alertView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var nameInputBox: IXInputBox!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var completionHandler: ((_ newName: String) -> Void)?
    
    var formerName: String!
    
    private let disposeBag = DisposeBag()
    
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
        
        nameInputBox.textField.becomeFirstResponder()
    }
    
    func initialize() {
        alertView.corner(12)
        titleLabel.text = "Alert.Wallet.EditName".localized
        nameInputBox.textField.placeholder = "Placeholder.InputWalletName".localized
        nameInputBox.setState(.normal, "")
        nameInputBox.setType(.name)
        nameInputBox.textField.text = formerName
        
        cancelButton.styleDark()
        cancelButton.setTitle("Common.Cancel".localized, for: .normal)
        confirmButton.styleLight()
        confirmButton.setTitle("Common.Confirm".localized, for: .normal)
        
        nameInputBox.textField.rx.text.map { $0!.length > 0 }
            .subscribe(onNext: { [unowned self] in
                self.confirmButton.isEnabled = $0
            }).disposed(by: disposeBag)
        
        nameInputBox.textField.rx.controlEvent(UIControl.Event.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            self.validateName()
        }).disposed(by: disposeBag)
        
        cancelButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [weak self] in
                self?.nameInputBox.textField.resignFirstResponder()
                self?.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
        
        confirmButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                if self.validateName() {
                    self.nameInputBox.textField.resignFirstResponder()
                    self.dismiss(animated: true, completion: {
                        if let handler = self.completionHandler {
                            let name = self.nameInputBox.textField.text!
                            let stripName = name.removeContinuosSuffix(string: " ")
                            handler(stripName)
                        }
                    })
                }
            }).disposed(by: disposeBag)
        
        keyboardHeight().observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] (height: CGFloat) in
            self.bottomConstraint.constant = height
            UIView.animate(withDuration: 0.15, animations: {
                self.view.layoutIfNeeded()
            })
        }).disposed(by: disposeBag)
    }

    @discardableResult
    private func validateName() -> Bool {
        guard let walletName = nameInputBox.textField.text, walletName != "" else {
            nameInputBox.setState(.error, "Error.WalletName".localized)
            return false
        }
        
        let stripName = walletName.removeContinuosSuffix(string: " ")
        
        if WManager.canSaveWallet(alias: stripName) == false {
            nameInputBox.setState(.error, "Error.Wallet.Duplicated.Name".localized)
            return false
        }
        
        return true
    }
}
