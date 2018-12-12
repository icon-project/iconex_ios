//
//  EditingAddressViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class EditingAddressViewController: UIViewController {
    @IBOutlet weak var alertContainer: UIView!
    @IBOutlet weak var alertTitle: UILabel!
    @IBOutlet weak var nameInputBox: IXInputBox!
    @IBOutlet weak var addressInputBox: IXInputBox!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var qrButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var mode: Alert.EditingMode = .add
    var type: COINTYPE = .unknown
    
    var name: String?
    var address: String?
    var handler: (() -> Void)?
    
    let disposeBag = DisposeBag()
    
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
        alertContainer.corner(12)
        if mode == .add {
            alertTitle.text = "AddressBook.Add".localized
            addressInputBox.textField.isEnabled = true
            addressInputBox.setState(.normal, "")
            confirmButton.isEnabled = false
        } else {
            alertTitle.text = "Alert.AddressBook.Edit".localized
            addressInputBox.textField.isEnabled = false
            addressInputBox.setState(.readOnly, "")
            confirmButton.isEnabled = true
        }
        
        if let name = self.name {
            nameInputBox.textField.text = name
        }
        
        if let address = self.address {
            addressInputBox.textField.text = address
        }
        
        nameInputBox.setState(.normal, nil)
        nameInputBox.setType(.name)
        nameInputBox.textField.placeholder = "AddressBook.InputName".localized
        addressInputBox.setType(.address)
        addressInputBox.textField.placeholder = type == .icx ? "Alert.AddressBook.ICX".localized : "Alert.AddressBook.ETH".localized
        
        cancelButton.styleDark()
        cancelButton.setTitle("Common.Cancel".localized, for: .normal)
        confirmButton.styleLight()
        confirmButton.setTitle("Common.Confirm".localized, for: .normal)
        
        qrButton.cornered()
        
        qrButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                let reader = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "QRReaderView") as! QRReaderViewController
                reader.mode = .address(.add)
                reader.type = self.type
                reader.handler = { code in
                    self.addressInputBox.textField.text = code
                    self.confirmButton.isEnabled = self.validateNameField() && self.validateAddressField()
                }
                
                reader.show(self)
            }).disposed(by: disposeBag)
 
        keyboardHeight().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] (height: CGFloat) in
                self.bottomConstraint.constant = height
            }).disposed(by: disposeBag)
        
        cancelButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                self.dismiss(animated: true, completion: nil)
                self.view.endEditing(true)
            }).disposed(by: disposeBag)
        
        nameInputBox.textField.rx.controlEvent(UIControl.Event.editingDidEnd)
            .subscribe(onNext: { [unowned self] in
                self.confirmButton.isEnabled = self.validateNameField() && self.validateAddressField()
            }).disposed(by: disposeBag)
        nameInputBox.textField.rx.controlEvent(UIControl.Event.editingDidEndOnExit)
            .subscribe(onNext: {
            }).disposed(by: disposeBag)
        nameInputBox.textField.rx.controlEvent(UIControl.Event.editingChanged)
            .subscribe(onNext: { [unowned self] in
                self.confirmButton.isEnabled = self.validateNameField(false) && self.validateAddressField(false)
            }).disposed(by: disposeBag)
        nameInputBox.textField.rx.controlEvent(UIControl.Event.editingDidBegin)
            .subscribe(onNext: { [unowned self] in
                self.confirmButton.isEnabled = self.validateNameField(false) && self.validateAddressField(false)
            }).disposed(by: disposeBag)
        
        addressInputBox.textField.rx.controlEvent(UIControl.Event.editingDidEnd)
            .subscribe(onNext: { [unowned self] in
                self.confirmButton.isEnabled = self.validateNameField() && self.validateAddressField()
            }).disposed(by: disposeBag)
        addressInputBox.textField.rx.controlEvent(UIControl.Event.editingDidEndOnExit)
            .subscribe(onNext: {
            }).disposed(by: disposeBag)
        addressInputBox.textField.rx.controlEvent(UIControl.Event.editingChanged)
            .subscribe(onNext: { [unowned self] in
                self.confirmButton.isEnabled = self.validateNameField(false) && self.validateAddressField(false)
            }).disposed(by: disposeBag)
        addressInputBox.textField.rx.controlEvent(UIControl.Event.editingDidBegin)
            .subscribe(onNext: { [unowned self] in
                self.confirmButton.isEnabled = self.validateNameField(false) && self.validateAddressField(false)
            }).disposed(by: disposeBag)
        
        confirmButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                if self.validateNameField() && self.validateAddressField() {
                    do {
                        
                        if self.mode == .add {
                            try AddressBook.addAddressBook(name: self.nameInputBox.textField.text!, address: self.addressInputBox.textField.text!, type: self.type)
                        } else {
                            try AddressBook.modifyAddressBook(oldName: self.name!, newName: self.nameInputBox.textField.text!)
                        }
                        self.view.endEditing(true)
                        self.dismiss(animated: true, completion: {
                            if let handler = self.handler {
                                handler()
                            }
                        })
                    } catch {
                        Log.Debug("error: \(error)")
                        self.dismiss(animated: true, completion: {
                            let app = UIApplication.shared.delegate as! AppDelegate
                            guard let root = app.window?.rootViewController else {
                                return
                            }
                            
                            if self.mode == .add {
                                Alert.Basic(message: "주소록 생성 중 오류가 발생했습니다.").show(root)
                            } else {
                                Alert.Basic(message: "주소록 수정 중 오류가 발생했습니다.").show(root)
                            }
                        })
                    }
                }
            }).disposed(by: disposeBag)
    }
    
    @discardableResult
    func validateNameField(_ show: Bool = true) -> Bool {
        guard let name = self.nameInputBox.textField.text else {
            if show { self.nameInputBox.setState(.error, "Error.AddressBook.InputName".localized) }
            return false
        }
        
        guard name != "" else { return false }
        
        if !AddressBook.canSaveAddressBook(name: name) {
            if show { self.nameInputBox.setState(.error, "Error.AddressBook.DuplicatedName".localized) }
            return false
        }
        
        return true
    }
    
    @discardableResult
    func validateAddressField(_ show: Bool = true) -> Bool {
        if mode == .edit { return true }
        
        guard let address = self.addressInputBox.textField.text else {
            if show { self.addressInputBox.setState(.error, "Error.Address".localized) }
            return false
        }
        
        guard address != "" else { return false }
        
        if !AddressBook.canSaveAddressBook(address: address) {
            if show { self.addressInputBox.setState(.error, "Error.AddressBook.DuplicatedAddress".localized) }
            return false
        }
        
        if self.type == .icx {
            if !Validator.validateICXAddress(address: address) && !Validator.validateIRCAddress(address: address) {
                if show { self.addressInputBox.setState(.error, "Error.Address.IRC.Invalid".localized) }
                return false
            }
            self.addressInputBox.setState(.normal, nil)
        } else if self.type == .eth {
            if !Validator.validateETHAddress(address: address) {
                if show { self.addressInputBox.setState(.error, "Error.Address.ETH.Invalid".localized) }
                return false
            }
            if show { self.addressInputBox.setState(.normal, nil) }
        }
        
        return true
    }
}
