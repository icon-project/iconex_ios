//
//  SwapStepTwoViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SwapStepTwoViewController: BaseViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var step2Header: UILabel!
    @IBOutlet var step2Desc: UILabel!
    @IBOutlet var step2Header2: UILabel!
    @IBOutlet var nameInputBox: IXInputBox!
    @IBOutlet var firstInputBox: IXInputBox!
    @IBOutlet var secondInputBox: IXInputBox!
    @IBOutlet var prevButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    
    var delegate: SwapStepDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }
    
    func initialize() {
        nameInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.nameInputBox.setState(.focus, nil)
        }).disposed(by: disposeBag)
        nameInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.validateName()
        }).disposed(by: disposeBag)
        nameInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            self.firstInputBox.textField.becomeFirstResponder()
        }).disposed(by: disposeBag)
        
        firstInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.firstInputBox.setState(.focus, nil)
        }).disposed(by: disposeBag)
        firstInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.validateFirst()
        }).disposed(by: disposeBag)
        firstInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            self.secondInputBox.textField.becomeFirstResponder()
        }).disposed(by: disposeBag)
        
        secondInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.secondInputBox.setState(.focus, nil)
        }).disposed(by: disposeBag)
        secondInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.validateSecond()
        }).disposed(by: disposeBag)
        secondInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            self.validation()
        }).disposed(by: disposeBag)
        
        scrollView.rx.didEndDragging.observeOn(MainScheduler.instance).subscribe(onNext: { _ in
            self.view.endEditing(false)
        }).disposed(by: disposeBag)
        
        prevButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.nameInputBox.textField.text = nil
            self.nameInputBox.setState(.normal, "")
            self.firstInputBox.textField.text = nil
            self.firstInputBox.setState(.normal, "")
            self.secondInputBox.textField.text = nil
            self.secondInputBox.setState(.normal, "")
            guard let delegate = self.delegate else { return }
            delegate.changeStep(to: SwapStepView.SwapStep.step1_1)
        }).disposed(by: disposeBag)
        
        nextButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            guard let delegate = self.delegate else { return }
            
            guard let name = self.nameInputBox.textField.text else { return }
            guard let password = self.firstInputBox.textField.text else { return }
            
            WCreator.newType = .icx
            do {
                let privKey = SwapManager.sharedInstance.privateKey!
                try WCreator.createSwapWallet(alias: name, password: password, privateKey: privKey)
                WManager.loadWalletList()
            } catch {
                Log.Error("\(error)")
                return
            }
            
            delegate.changeStep(to: SwapStepView.SwapStep.step3)
        }).disposed(by: disposeBag)
        
        keyboardHeight().observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] (height: CGFloat) in
            if height == 0 {
                self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            } else {
                var keyboardHeight: CGFloat = height - 72
                if #available(iOS 11.0, *) {
                    keyboardHeight = keyboardHeight - self.view.safeAreaInsets.bottom
                }
                self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
            }
        }).disposed(by: disposeBag)
        
        let observeName = nameInputBox.textField.rx.text
            .map { _ in
                return self.validateName(false)
        }
        
        let observeFirst = firstInputBox.textField.rx.text
            .map { _ in
                return self.validateFirst(false)
        }
        
        let observeSecond = secondInputBox.textField.rx.text
            .map { _ in
                return self.validateSecond(false)
        }
        
        Observable.combineLatest([observeName, observeFirst, observeSecond]) { iterator -> Bool in
            return iterator.reduce(true, { $0 && $1 })
        }.bind(to: nextButton.rx.isEnabled).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        step2Header.text = "Swap.Step2.Header1".localized
        step2Desc.text = "Swap.Step2.Desc1".localized
        step2Header2.text = "Swap.Step2.Header2".localized
        nameInputBox.setState(.normal, nil)
        nameInputBox.setType(.normal)
        nameInputBox.textField.returnKeyType = .next
        nameInputBox.textField.placeholder = "Placeholder.InputWalletName".localized
        firstInputBox.setState(.normal, nil)
        firstInputBox.setType(.newPassword)
        firstInputBox.textField.returnKeyType = .next
        firstInputBox.textField.placeholder = "Placeholder.InputWalletPassword".localized
        secondInputBox.setState(.normal, nil)
        secondInputBox.setType(.newPassword)
        secondInputBox.textField.placeholder = "Placeholder.ConfirmWalletPassword".localized
        prevButton.styleDark()
        prevButton.rounded()
        prevButton.setTitle("Common.Back".localized, for: .normal)
        nextButton.styleLight()
        nextButton.rounded()
        nextButton.setTitle("Common.Next".localized, for: .normal)
        nextButton.isEnabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @discardableResult
    func validateName(_ showError: Bool = true) -> Bool {
        guard let name = nameInputBox.textField.text, name != "" else {
            if showError { nameInputBox.setState(.error, "Error.WalletName".localized) }
            return false
        }
        
        guard name.rangeOfCharacter(from: CharacterSet.whitespacesAndNewlines) == nil else {
            if showError { self.nameInputBox.setState(.error, "Error.Password.Blank".localized) }
            return false
        }
        
        guard WManager.canSaveWallet(alias: name) else {
            if showError { nameInputBox.setState(.error, "Error.Wallet.Duplicated.Name".localized) }
            return false
        }
        
        if showError { nameInputBox.setState(.normal, "") }
        return true
    }
    
    @discardableResult
    func validateFirst(_ showError: Bool = true) -> Bool {
        guard let password = firstInputBox.textField.text, password != "" else {
            if showError { firstInputBox.setState(.error, "Error.Password".localized) }
            return false
        }
        
        guard Validator.validateCharacterSet(password: password) else {
            if showError { firstInputBox.setState(.error, "Error.Password.CharacterSet".localized) }
            return false
        }
        
        guard Validator.validateSequenceNumber(password: password) else {
            if showError { firstInputBox.setState(.error, "Error.Password.Serialize".localized) }
            return false
        }
        
        if showError { firstInputBox.setState(.normal, "") }
        return true
    }
    
    @discardableResult
    func validateSecond(_ showError: Bool = true) -> Bool {
        let password = firstInputBox.textField.text!
        guard let second = secondInputBox.textField.text, second != "" else {
            if showError { secondInputBox.setState(.error, "Error.Password".localized) }
            return false
        }
        
        guard password == second else {
            if showError { secondInputBox.setState(.error, "Error.Password.Mismatch".localized) }
            return false
        }
        
        if showError { secondInputBox.setState(.normal, "") }
        return true
    }
    
    func validation() {
        validateName()
        validateFirst()
        validateSecond()
    }
}
