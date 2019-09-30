//
//  AddTokenInfoViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 27/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AddTokenInfoViewController: BaseViewController {
    
    @IBOutlet weak var navBar: IXNavigationView!
    
    @IBOutlet weak var addressBox: IXInputBox!
    @IBOutlet weak var qrCodeButton: UIButton!
    @IBOutlet weak var nameBox: IXInputBox!
    @IBOutlet weak var symbolBox: IXInputBox!
    @IBOutlet weak var decimalBox: IXInputBox!
    
    @IBOutlet weak var addButton: UIButton!
    
    var walletInfo: BaseWalletConvertible? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarBack")) {
            if !self.addressBox.text.isEmpty || !self.nameBox.text.isEmpty {
                Alert.basic(title: "Token.Add.Cancel".localized, isOnlyOneButton: false, confirmAction: {
                    self.navigationController?.popViewController(animated: true)
                }).show()
                
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
        navBar.setTitle("ManageToken.Add".localized)
        
        // box init
        self.addressBox.set(state: .normal, placeholder: "TokenDetail.Placeholder.Address".localized)
        self.nameBox.set(state: .normal, placeholder: "TokenDetail.Placeholder.Name".localized)
        self.symbolBox.set(state: .readOnly, placeholder: "TokenDetail.Placeholder.Symbol".localized)
        self.decimalBox.set(state: .readOnly, placeholder: "TokenDetail.Placeholder.Decimal".localized)
        
        self.addressBox.set(inputType: .normal)
        
        qrCodeButton.roundGray230()
        
        addButton.setTitle("Common.Add".localized, for: .normal)
        addButton.lightMintRounded()
        addButton.isEnabled = false
        
        setupBind()
    }
    
    private func setupBind() {
        guard let wallet = self.walletInfo else { return }
        
        if let _ = wallet as? ICXWallet {
            addressBox.set { (address) -> String? in
                guard !address.isEmpty else { return nil }
                if !Validator.validateIRCAddress(address: address) {
                    return "Token.Info.Error.Address".localized
                }
                return nil
            }
        } else {
            addressBox.set { (address) -> String? in
                guard !address.isEmpty else { return nil }
                if !Validator.validateETHAddress(address: address) {
                    return "Token.Info.Error.Address".localized
                }
                return nil
            }
        }
        
        nameBox.set { (name) -> String? in
            guard !name.isEmpty else { return nil }
            if !Validator.validateTokenName(name: name) {
                return "Token.Info.Error.Symbol".localized
            }
            return nil
        }
        
        let addressObservable = addressBox.textField.rx.controlEvent(.editingDidEndOnExit)
        
        addressObservable.subscribe { (_) in
            let contract = self.addressBox.text
            
            if Validator.validateIRCAddress(address: contract) {
                DispatchQueue.global().async {
                    guard let request = Manager.icon.getIRCTokenInfo(walletAddress: wallet.address, contractAddress: contract) else {
                        self.resetInputBox()
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.nameBox.text = request.name
                        self.symbolBox.text = request.symbol
                        self.decimalBox.text = String(request.decimal.hexToBigUInt() ?? 0)
                        
                        self.sendActions()
                    }
                }
                
            } else if Validator.validateETHAddress(address: contract) {
                DispatchQueue.global().async {
                    guard let ercInfo = Ethereum.requestTokenInformation(tokenContractAddress: contract, myAddress: wallet.address) else {
                        self.resetInputBox()
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.nameBox.text = ercInfo.name
                        self.symbolBox.text = ercInfo.symbol
                        self.decimalBox.text = String(ercInfo.decimal)
                        
                        self.sendActions()
                    }
                }
                
            } else {
                self.resetInputBox()
            }
        }.disposed(by: disposeBag)
        
        
        qrCodeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let qrVC = UIStoryboard.init(name: "Camera", bundle: nil).instantiateInitialViewController() as! QRReaderViewController
                qrVC.modalPresentationStyle = .fullScreen
                if let _ = self.walletInfo as? ICXWallet {
                    qrVC.set(mode: .irc, handler: { (contract) in
                        self.addressBox.textField.text = contract
                        self.addressBox.textField.sendActions(for: .editingDidEndOnExit)
                    })
                } else {
                    qrVC.set(mode: .eth, handler: { (contract) in
                        self.addressBox.textField.text = contract
                        self.addressBox.textField.sendActions(for: .editingDidEndOnExit)
                    })
                }
                self.present(qrVC, animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
        Observable.combineLatest(addressBox.textField.rx.text.orEmpty, nameBox.textField.rx.text.orEmpty, symbolBox.textField.rx.text.orEmpty, decimalBox.textField.rx.text.orEmpty)
            .flatMapLatest { (address, name, symbol, decimal) -> Observable<Bool> in
                return Observable.just(!address.isEmpty && !name.isEmpty && !symbol.isEmpty && !decimal.isEmpty)
                
            }.bind(to: addButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        addButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let name = self.nameBox.text
                let address = self.addressBox.text
                let symbol = self.symbolBox.text
                let decimal = Int(self.decimalBox.text) ?? 0
                
                let token = TokenFile(name: name, address: address, symbol: symbol, decimal: decimal)
                let newToken = NewToken(token: token, parent: wallet)
                
                guard DB.canSaveToken(depended: wallet.address, contract: address) else {
                    self.navigationController?.popToRootViewController(animated: true)
                    return
                }
                
                do {
                    try DB.addToken(tokenInfo: newToken)
                    self.navigationController?.popToRootViewController(animated: true)
                    
                } catch {
                    self.view.showToast(message: "Common.Error".localized)
                }
                
        }.disposed(by: disposeBag)
    }
    
    private func resetInputBox() {
        DispatchQueue.main.async {
            Alert.basic(title: "Token.Info.Error.ConnectionRefused".localized, leftButtonTitle: "Common.Confirm".localized).show()
            
            self.addressBox.text.removeAll()
            self.nameBox.text.removeAll()
            self.symbolBox.text.removeAll()
            self.decimalBox.text.removeAll()
            
            self.sendActions()
        }
    }
    
    private func sendActions() {
        self.addressBox.textField.sendActions(for: .valueChanged)
        self.nameBox.textField.sendActions(for: .valueChanged)
        self.symbolBox.textField.sendActions(for: .valueChanged)
        self.decimalBox.textField.sendActions(for: .valueChanged)
    }
}
