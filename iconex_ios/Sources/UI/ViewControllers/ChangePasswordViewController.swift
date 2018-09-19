//
//  ChangePasswordViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ChangePasswordViewController: UIViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var topTitle: UILabel!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var descTitle: UILabel!
    @IBOutlet weak var current: IXInputBox!
    @IBOutlet weak var first: IXInputBox!
    @IBOutlet weak var second: IXInputBox!
    @IBOutlet weak var confirmButton: UIButton!
    
    var walletInfo: WalletInfo?
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        current.textField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initialize() {
        navTitle.text = "Change.PWD.NavTitle".localized
        topTitle.text = "Change.PWD.Header1".localized
        topLabel.text = "Change.PWD.Desc1_1".localized
        descTitle.text = "Change.PWD.Header2".localized
        
        current.setState(.normal, "")
        current.setType(.password)
        current.textField.returnKeyType = .next
        current.textField.placeholder = "Placeholder.CurrentPassword".localized
        first.setState(.normal, nil)
        first.setType(.newPassword)
        first.textField.returnKeyType = .next
        first.textField.placeholder = "Placeholder.InputNewPassword".localized
        second.setState(.normal, nil)
        second.setType(.newPassword)
        second.textField.placeholder = "Placeholder.ConfirmNewPassword".localized
        
        confirmButton.styleLight()
        confirmButton.rounded()
        confirmButton.setTitle("Common.Change".localized, for: .normal)
        confirmButton.isEnabled = false
        
        current.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.current.setState(.focus)
        }).disposed(by: disposeBag)
        current.textField.rx.controlEvent(UIControlEvents.editingDidEnd)
            .subscribe(onNext: { [unowned self] in
                self.validateCurrent()
            }).disposed(by: disposeBag)
        current.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit)
            .subscribe(onNext: { [unowned self] in
                self.first.textField.becomeFirstResponder()
            }).disposed(by: disposeBag)
        
        first.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.first.setState(.focus)
        }).disposed(by: disposeBag)
        first.textField.rx.controlEvent(UIControlEvents.editingDidEnd)
            .subscribe(onNext: { [unowned self] in
                self.validatePassword1()
            }).disposed(by: disposeBag)
        first.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit)
            .subscribe(onNext: { [unowned self] in
                self.second.textField.becomeFirstResponder()
            }).disposed(by: disposeBag)
        
        second.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.second.setState(.focus)
        }).disposed(by: disposeBag)
        second.textField.rx.controlEvent(UIControlEvents.editingDidEnd)
            .subscribe(onNext: { [unowned self] in
                self.validatePassword2()
            }).disposed(by: disposeBag)
        second.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit)
            .subscribe(onNext: { [unowned self] in
                self.validation()
            }).disposed(by: disposeBag)
        
        confirmButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                self.changePassword()
            }).disposed(by: disposeBag)
        
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [weak self] in
                self?.view.endEditing(true)
                self?.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
        
        keyboardHeight().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] (height: CGFloat) in
                var fixed: CGFloat = height
                
                if height > 0 {
                    if #available(iOS 11.0, *) {
                        fixed = fixed - self.view.safeAreaInsets.bottom
                    }
                }
                
                self.scrollView.contentInset.bottom = height + 72
                
                UIView.animate(withDuration: 0.25, animations: {
                    self.view.layoutIfNeeded()
                })
            }).disposed(by: disposeBag)
        
        scrollView.rx.didEndDragging.observeOn(MainScheduler.instance).subscribe(onNext: { _ in
            self.view.endEditing(false)
        }).disposed(by: disposeBag)
        
        let observeCurrent = current.textField.rx.text
            .map { _ in
                return self.validateCurrent(false)
        }
        let observeFirst = first.textField.rx.text
            .map { _ in
                return self.validatePassword1(false)
        }
        let observeSecond = second.textField.rx.text
            .map { _ in
                return self.validatePassword2(false)
        }
        
        Observable.combineLatest([observeCurrent, observeFirst, observeSecond]) { iterator -> Bool in
            return iterator.reduce(true, { $0 && $1 })
        }.bind(to: confirmButton.rx.isEnabled).disposed(by: disposeBag)
    }
    
    private func changePassword() {
        
        self.current.setState(.normal, nil)
        
        self.confirmButton.isEnabled = false
        let oldValue = self.current.textField.text!
        let newValue = self.first.textField.text!
        
        do {
            let wallet = WManager.loadWalletBy(info: self.walletInfo!)!
            let result = try WManager.changeWalletPassword(wallet: wallet, old: oldValue, new: newValue)
            Log.Debug("changing: \(result)")
            if result {
                WManager.loadWalletList()
            } else {
                self.confirmButton.isEnabled = true
                Alert.Basic(message: "Error.CommonError".localized).show(self)
                return
            }
        } catch {
            self.confirmButton.isEnabled = true
            Log.Debug("error: \(error)")
            let message = "Error.CommonError".localized + "\n\(error.localizedDescription)"
            Alert.Basic(message: message).show(self)
            return
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    private func validation() {
        validateCurrent()
        validatePassword1()
        validatePassword2()
    }
    
    @discardableResult
    private func validateCurrent(_ showError: Bool = true) -> Bool {
        guard let current = self.current.textField.text, current != "" else {
            if showError { self.current.setState(.error, "Error.Password".localized) }
            return false
        }
        
        do {
            if self.walletInfo!.type == .icx {
                let icx = WManager.loadWalletBy(info: self.walletInfo!) as! ICXWallet
                _ = try icx.extractICXPrivateKey(password: current)
            } else if self.walletInfo!.type == .eth {
                let eth = WManager.loadWalletBy(info: self.walletInfo!) as! ETHWallet
                _ = try eth.extractETHPrivateKey(password: current)
            }
        } catch {
            if showError { self.current.setState(.error, "Error.Password.Wrong".localized) }
            return false
        }
        
        if showError { self.current.setState(.normal, "") }
        
        return true
    }
    
    @discardableResult
    private func validatePassword1(_ showError: Bool = true) -> Bool {
        guard let password = self.first.textField.text, password != "" else {
            if showError { self.first.setState(.error, "Error.Password".localized) }
            return false
        }
        
        if password.length < 8 {
            if showError { self.first.setState(.error, "Error.Password.Length".localized) }
            return false
        }
        guard Validator.validateCharacterSet(password: password) else {
            if showError { self.first.setState(.error, "Error.Password.CharacterSet".localized) }
            return false
        }
        guard Validator.validateSequenceNumber(password: password) else {
            if showError { self.first.setState(.error, "Error.Password.Serialize".localized) }
            return false
        }
        
        if showError { self.first.setState(.normal, "") }
        return true
    }
    
    @discardableResult
    func validatePassword2(_ showError: Bool = true) -> Bool {
        guard let password = first.textField.text, let confirm = second.textField.text, confirm != "" else {
            if showError { self.second.setState(.error, "Error.Password".localized) }
            return false
        }
        
        guard password == confirm else {
            if showError { self.second.setState(.error, "Error.Password.Mismatch".localized) }
            return false
        }
        
        if showError { self.second.setState(.normal, "") }
        return true
    }
}
