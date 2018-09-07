//
//  StepTwoViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Toaster

class StepTwoViewController: UIViewController {
    @IBOutlet weak var headerLabel1: UILabel!
    @IBOutlet weak var descLabel1: UILabel!
    @IBOutlet weak var headerLabel2: UILabel!
    @IBOutlet weak var walletNameBox: IXInputBox!
    @IBOutlet weak var password1: IXInputBox!
    @IBOutlet weak var password2: IXInputBox!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    var delegate: CreateStepDelegate?
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initializeUI() {
        headerLabel1.text = "Create.Wallet.Step2.Header1".localized
        descLabel1.text = "Create.Wallet.Step2.Desc1".localized
        headerLabel2.text = "Create.Wallet.Step2.Header2".localized
        prevButton.setTitle(Localized(key: "Common.Back"), for: .normal)
        prevButton.styleDark()
        prevButton.rounded()
        nextButton.setTitle(Localized(key: "Common.Next"), for: .normal)
        nextButton.styleLight()
        nextButton.rounded()
        
        walletNameBox.setType()
        walletNameBox.setState()
        walletNameBox.textField.returnKeyType = .next
        walletNameBox.textField.placeholder = Localized(key: "Placeholder.InputWalletName")
        
        password1.setType(.newPassword)
        password1.setState()
        password1.textField.returnKeyType = .next
        password1.textField.placeholder = Localized(key: "Placeholder.InputWalletPassword")
        
        password2.setType(.newPassword)
        password2.setState()
        password2.textField.returnKeyType = .done
        password2.textField.placeholder = Localized(key: "Placeholder.ConfirmWalletPassword")
        
        nextButton.isEnabled = false
        
        walletNameBox.textField.rx.controlEvent([UIControlEvents.editingDidBegin]).subscribe(onNext: { [unowned self] in
            self.walletNameBox.setState(.focus)
        }).disposed(by: disposeBag)
        walletNameBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.validateWalletName()
        }).disposed(by: disposeBag)
        walletNameBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            self.password1.textField.becomeFirstResponder()
        }).disposed(by: disposeBag)

        password1.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.password1.setState(.focus)
        }).disposed(by: disposeBag)
        password1.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.validatePassword1()
        }).disposed(by: disposeBag)
        password1.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            self.password2.textField.becomeFirstResponder()
        }).disposed(by: disposeBag)

        password2.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.password2.setState(.focus)
        }).disposed(by: disposeBag)
        password2.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.validatePassword2()
        }).disposed(by: disposeBag)
        password2.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            self.allValidation()
        }).disposed(by: disposeBag)
        
        keyboardHeight().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] (height: CGFloat) in
                if height == 0 {
                    self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                } else {
                    var keyboardHeight: CGFloat = height
                    if #available(iOS 11.0, *) {
                        keyboardHeight = keyboardHeight - self.view.safeAreaInsets.bottom
                    }
                    self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
                }
            }).disposed(by: disposeBag)
        
        scrollView.rx.didEndDragging.observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] _ in
            self.view.endEditing(false)
        }).disposed(by: disposeBag)
        
        let observeName = walletNameBox.textField.rx.text
            .map { _ in
                return self.validateWalletName(false)
        }
        let observePassword1 = password1.textField.rx.text
            .map { _ in
                return self.validatePassword1(false)
        }
        let observePassword2 = password2.textField.rx.text
            .map { _ in
                return self.validatePassword2(false)
        }
        
        Observable.combineLatest([observeName, observePassword1, observePassword2]) { iterator -> Bool in
            return iterator.reduce(true, { $0 && $1 })
        }.bind(to: self.nextButton.rx.isEnabled).disposed(by: disposeBag)
        
        
    }

    func didShow() {
        walletNameBox.textField.becomeFirstResponder()
    }
    
    func resignAllResponder() {
//        walletNameBox.textField.resignFirstResponder()
//        password1.textField.resignFirstResponder()
//        password2.textField.resignFirstResponder()
        self.view.endEditing(true)
    }
    
    @IBAction func clickedPrev(_ sender: Any) {
        guard let delegate = delegate else {
            return
        }
        resignAllResponder()
        walletNameBox.textField.text = nil
        walletNameBox.setState(.normal, "")
        password1.textField.text = nil
        password1.setState(.normal, "")
        password2.textField.text = nil
        password2.setState(.normal, "")
        nextButton.isEnabled = false
        
        delegate.prevStep(currentStep: .two)
    }
    
    @IBAction func clickedNext(_ sender: Any) {
        guard let delegate = delegate else {
            return
        }
        nextButton.isEnabled = false
        do {
            let alias = walletNameBox.textField.text!
            let password = password1.textField.text!
            try WCreator.createWallet(alias: alias, password: password, completion: {
                WManager.loadWalletList()
                
                delegate.nextStep(currentStep: .two)
            })
        } catch {
            Log.Error(error)
            
            Toast(text: "Error.Wallet.CreateFailed".localized).show()
        }
    }
    
    func allValidation() {
        validateWalletName()
        validatePassword1()
        validatePassword2()
    }
    
    @discardableResult
    func validateWalletName(_ showError: Bool = true) -> Bool {
        if self.walletNameBox.textField.text == "" {
            if showError { self.walletNameBox.setState(.error, Localized(key: "Error.WalletName")) }
            return false
        }
        
        if WManager.canSaveWallet(alias: self.walletNameBox.textField.text!) == false {
            if showError { self.walletNameBox.setState(.error, Localized(key: "Error.Wallet.Duplicated.Name")) }
            return false
        }
        
        if showError { self.walletNameBox.setState(.normal) }
        return true
    }
    @discardableResult
    func validatePassword1(_ showError: Bool = true) -> Bool {
        guard let password = self.password1.textField.text, password != "" else {
            if showError { self.password1.setState(.error, "Error.Password".localized) }
            return false
        }
        
        if password.length < 8 {
            if showError { self.password1.setState(.error, Localized(key: "Error.Password.Length")) }
            return false
        }
        
        guard Validator.validateCharacterSet(password: password) else {
            if showError { self.password1.setState(.error, Localized(key: "Error.Password.CharacterSet")) }
            return false
        }
        guard Validator.validateSequenceNumber(password: password) else {
            if showError { self.password1.setState(.error, Localized(key: "Error.Password.Serialize")) }
            return false
        }
        
        if showError { self.password1.setState(.normal) }
        return true
    }
    @discardableResult
    func validatePassword2(_ showError: Bool = true) -> Bool {
        if self.password2.textField.text! == "" {
            if showError { self.password2.setState(.error, Localized(key: "Error.Password.Mismatch")) }
            return false
        }
        
        if self.password2.textField.text != self.password1.textField.text {
            if showError { self.password2.setState(.error, Localized(key: "Error.Password.Mismatch")) }
            return false
        }
        
        if showError { self.password2.setState(.normal) }
        return true
    }
}
