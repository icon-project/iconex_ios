//
//  TokenDetailViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 26/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TokenDetailViewController: BaseViewController {
    
    @IBOutlet weak var navBar: IXNavigationView!
    
    @IBOutlet weak var addressInputBox: IXInputBox!
    @IBOutlet weak var nameInputBox: IXInputBox!
    @IBOutlet weak var symbolInputBox: IXInputBox!
    @IBOutlet weak var decimalInputBox: IXInputBox!
    
    @IBOutlet weak var buttonView: UIView!
    
    @IBOutlet weak var modifyCompleteButton: UIButton!
    
    var tokenInfo: Token? = nil
    
    var isEditMode: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let token = self.tokenInfo else { return }
        
        modifyCompleteButton.darkRounded()
        modifyCompleteButton.setTitle("Common.Complete".localized, for: .normal)
        
        // nameInputBox share
        let nameBox = nameInputBox.textField.rx.text.orEmpty.share(replay: 1)
        
        nameBox
            .map { $0.count > 0 }
            .bind(to: modifyCompleteButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        nameBox
            .subscribe(onNext: { (value) in
                guard let tokenName = self.tokenInfo?.name else { return }
                print("Now \(tokenName == value)")
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = value == tokenName
            }).disposed(by: disposeBag)
        
        modifyCompleteButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                var newToken = token
                newToken.name = self.nameInputBox.text
                do {
                    try DB.modifyToken(tokenInfo: newToken)
                    self.tokenInfo = newToken
                    self.isEditMode = false
                    self.refresh()
                } catch {
                    
                }
            }.disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        
        guard let token = self.tokenInfo else { return }
        
        self.buttonView.isHidden = true
        
        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarBack")) {
            if self.nameInputBox.text == token.name {
                self.navigationController?.popViewController(animated: true)
            } else {
                Alert.basic(title: "TokenDetail.Alert.Cancel".localized, isOnlyOneButton: false, leftButtonTitle: "Common.No".localized, rightButtonTitle: "Common.Yes".localized, confirmAction: {
                    self.navigationController?.popViewController(animated: true)
                }).show()
            }
        }
        
        navBar.setRight(title: "Common.Modify".localized) {
            if self.isEditMode {
                Alert.basic(title: String(format: NSLocalizedString("TokenDetail.Alert.Delete", comment: ""), token.name),
                            isOnlyOneButton: false, leftButtonTitle: "Common.No".localized, rightButtonTitle: "Common.Yes".localized, confirmAction: {
                                try? DB.removeToken(tokenInfo: token)
                                self.navigationController?.popViewController(animated: true)
                                
                }).show()
            } else {
                self.navBar.setRight(title: "Common.Remove".localized)
                self.isEditMode = true
                self.nameInputBox.set(state: .normal)
                self.nameInputBox.textField.isEnabled = true
                self.buttonView.isHidden = false
            }
        }
        
        navBar.setTitle(token.name)
        
        addressInputBox.textField.text = token.contract
        nameInputBox.textField.text = token.name
        symbolInputBox.textField.text = token.symbol
        decimalInputBox.textField.text = "\(token.decimal)"
        
        nameInputBox.textField.sendActions(for: .valueChanged)
        
        addressInputBox.set(state: .readOnly, placeholder: "TokenDetail.Placeholder.Address".localized)
        nameInputBox.set(state: .readOnly, placeholder: "TokenDetail.Placeholder.Name".localized)
        symbolInputBox.set(state: .readOnly, placeholder: "TokenDetail.Placeholder.Symbol".localized)
        decimalInputBox.set(state: .readOnly, placeholder: "TokenDetail.Placeholder.Decimal".localized)
    }
}
