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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarBack")) {
            self.navigationController?.popViewController(animated: true)
        }
        navBar.setTitle("ManageToken.Add".localized)
        
        // box init
        self.addressBox.set(state: .normal, placeholder: "TokenDetail.Placeholder.Address".localized)
        self.nameBox.set(state: .normal, placeholder: "TokenDetail.Placeholder.Name".localized)
        self.symbolBox.set(state: .readOnly, placeholder: "TokenDetail.Placeholder.Symbol".localized)
        self.decimalBox.set(state: .readOnly, placeholder: "TokenDetail.Placeholder.Decimal".localized)
        
        self.addressBox.set(inputType: .normal)
        
        qrCodeButton.roundGray230()
        addButton.lightMintRounded()
        addButton.isEnabled = false
        
        setupBind()
    }
    
    private func setupBind() {
        addressBox.set { (address) -> String? in
            guard !address.isEmpty else { return nil }
            if !Validator.validateIRCAddress(address: address) {
                return "Token.Info.Error.Address".localized
            }
            return nil
        }
        
        nameBox.set { (name) -> String? in
            guard !name.isEmpty else { return nil }
            if !Validator.validateTokenSymbol(symbol: name) {
                return "Token.Info.Error.Symbol".localized
            }
            return nil
        }
        
//        addressBox.textField.rx.
        
        qrCodeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let qrVC = UIStoryboard.init(name: "Camera", bundle: nil).instantiateInitialViewController() as! QRReaderViewController
                self.present(qrVC, animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
        Observable.combineLatest(addressBox.textField.rx.text.orEmpty, nameBox.textField.rx.text.orEmpty)
            .flatMapLatest { (address, name) -> Observable<Bool> in
                let result = Validator.validateIRCAddress(address: address) && Validator.validateTokenSymbol(symbol: name)
                return Observable.just(result)
            }.bind(to: addButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        addButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                print("tap tap")
        }.disposed(by: disposeBag)
    }
}
