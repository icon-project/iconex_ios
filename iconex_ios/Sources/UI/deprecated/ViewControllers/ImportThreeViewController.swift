//
//  ImportThreeViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ImportThreeViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var fileContainer: UIView!
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var inputBox: IXInputBox!
    @IBOutlet weak var privContainer: UIView!
    @IBOutlet weak var privHeaderLabel: UILabel!
    @IBOutlet weak var privContent1: UILabel!
    @IBOutlet weak var privContent2: UILabel!
    @IBOutlet weak var privNameBox: IXInputBox!
    @IBOutlet weak var privPassword1: IXInputBox!
    @IBOutlet weak var privPassword2: IXInputBox!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var doneButton: UIButton!
    
    let disposeBag = DisposeBag()
    
    var delegate: ImportStepDelegate?
    
    var mode: Int = 0 {
        willSet {
            if newValue == 0 {
                self.fileContainer.isHidden = false
                self.scrollView.isHidden = true
                self.privContainer.isHidden = true
            } else {
                self.fileContainer.isHidden = true
                self.scrollView.isHidden = false
                self.privContainer.isHidden = false
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initialize() {
        inputBox.textField.rx.controlEvent(UIControl.Event.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            self.inputBox.textField.resignFirstResponder()
            self.doneButton.isEnabled = self.validateWalletName()
        }).disposed(by: disposeBag)
        
        privNameBox.textField.rx.controlEvent(UIControl.Event.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.validateWalletName()
        }).disposed(by: disposeBag)
        privNameBox.textField.rx.controlEvent(UIControl.Event.editingDidEndOnExit).subscribe(onNext: {
            self.privPassword1.textField.becomeFirstResponder()
        }).disposed(by: disposeBag)
        
        privPassword1.textField.rx.controlEvent(UIControl.Event.editingDidEnd).subscribe(onNext: {[unowned self] in
            self.validatePassword()
        }).disposed(by: disposeBag)
        privPassword1.textField.rx.controlEvent(UIControl.Event.editingDidEndOnExit).subscribe(onNext: {
            self.privPassword2.textField.becomeFirstResponder()
        }).disposed(by: disposeBag)
        
        privPassword2.textField.rx.controlEvent(UIControl.Event.editingDidEnd).subscribe(onNext: {[unowned self] in
            self.validateConfirmPassword()
        }).disposed(by: disposeBag)
        privPassword2.textField.rx.controlEvent(UIControl.Event.editingDidEndOnExit).subscribe(onNext: {
            
        }).disposed(by: disposeBag)
        
        let observeName = privNameBox.textField.rx.text
            .map { _ in
                return self.validateWalletName(false)
        }
        let observeFirst = privPassword1.textField.rx.text
            .map { _ in
                return self.validatePassword(false)
        }
        let observeSecond = privPassword2.textField.rx.text
            .map { _ in
                return self.validateConfirmPassword(false)
        }
        Observable.combineLatest([observeName, observeFirst, observeSecond]) { iterator -> Bool in
            return iterator.reduce(true, { $0 && $1 })
        }.bind(to: doneButton.rx.isEnabled).disposed(by: disposeBag)
        
        keyboardHeight().observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] (height: CGFloat) in
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
    }
    
    func initializeUI() {
        headerTitleLabel.text = "Import.Step3.Header_1".localized
        
        inputBox.setType(.name)
        inputBox.setState(.normal, nil)
        inputBox.textField.placeholder = "Import.Step3.Placeholder_1".localized
        
        privHeaderLabel.text = "Import.Step3.Header_2_1".localized
        privContent1.text = "Import.Step3.Desc_2_1".localized
        privContent2.text = "Import.Step3.Desc_2_2".localized
        
        privNameBox.setState(.normal, nil)
        privNameBox.setType(.name)
        privNameBox.textField.returnKeyType = .next
        privNameBox.textField.placeholder = "Import.Step3.Placeholder_1".localized
        privPassword1.setState(.normal, nil)
        privPassword1.setType(.newPassword)
        privPassword1.textField.returnKeyType = .next
        privPassword1.textField.placeholder = "Create.Wallet.Step2.Password.Placeholder".localized
        privPassword2.setState(.normal, nil)
        privPassword2.setType(.newPassword)
        privPassword2.textField.placeholder = "Create.Wallet.Step2.Confirm.Placeholder".localized
        doneButton.styleDark()
        doneButton.setTitle("Common.Complete".localized, for: .normal)
        doneButton.rounded()
        doneButton.isEnabled = false
    }
    
    @discardableResult
    func validateWalletName(_ showError: Bool = true) -> Bool {
        
        if mode == 0 {
            let name = self.inputBox.textField.text!.removeContinuosSuffix(string: " ")
            
            if name == "" {
                return false
            }
            
            if !WManager.canSaveWallet(alias: name) {
                self.inputBox.setState(.error, "Error.Wallet.Duplicated.Name".localized)
                return false
            }
            self.inputBox.setState(.normal, nil)
        } else {
            let name = self.privNameBox.textField.text!.removeContinuosSuffix(string: " ")
            
            if name == "" {
                return false
            }
            
            if !WManager.canSaveWallet(alias: name) {
                if showError { self.privNameBox.setState(.error, "Error.Wallet.Duplicated.Name".localized) }
                return false
            }
            if showError { self.privNameBox.setState(.normal, nil) }
        }
        
        return true
    }
    
    @discardableResult
    func validatePassword(_ showError: Bool = true) -> Bool {
        
        guard let password = self.privPassword1.textField.text, password != "" else {
            return false
        }
        
        if password.length < 8 {
            if showError { self.privPassword1.setState(.error, "Error.Password.Length".localized) }
            return false
        }
        
        guard Validator.validateCharacterSet(password: password) else {
            if showError { self.privPassword1.setState(.error, "Error.Password.CharacterSet".localized) }
            return false
        }
        guard Validator.validateSequenceNumber(password: password) else {
            if showError { self.privPassword1.setState(.error, "Error.Password.Serialize".localized) }
            return false
        }
        if showError { self.privPassword1.setState(.normal, nil) }
        
        return true
    }
    
    @discardableResult
    func validateConfirmPassword(_ showError: Bool = true) -> Bool {
        guard let confirm = self.privPassword2.textField.text, let password = self.privPassword1.textField.text, password == confirm, password != "" else {
            if showError { self.privPassword2.setState(.error, "Error.Password.Mismatch".localized) }
            return false
        }
        if showError { self.privPassword2.setState(.normal, nil) }
        return true
    }
    
    func validation() {
        self.validateWalletName()
        self.validatePassword()
        self.validateConfirmPassword()
    }
    
    func refreshItem() {
        self.mode = WCreator.importStyle
        
        inputBox.textField.text = ""
        inputBox.setState(.normal, nil)
        privNameBox.textField.text = ""
        privNameBox.setState(.normal, nil)
        privPassword1.textField.text = ""
        privPassword1.setState(.normal, nil)
        privPassword2.textField.text = ""
        privPassword2.setState(.normal, nil)
        doneButton.isEnabled = false
    }
    
    @IBAction func clickedDone(_ sender: Any) {
        if mode == 0 {
            do {
                guard let name = self.inputBox.textField.text else { return }
                
                try WCreator.saveWallet(alias: name.removeContinuosSuffix(string: " "))
                
                WManager.loadWalletList()
                let app = UIApplication.shared.delegate as! AppDelegate
                if let nav = app.window?.rootViewController as? UINavigationController {
                    let main = nav.viewControllers[0] as! MainViewController
                    main.currentIndex = 0
                    main.loadWallets()
                    self.dismiss(animated: true, completion: nil)
                } else {
                    let main = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                    app.window?.rootViewController = main
                    self.dismiss(animated: true, completion: nil)
                }
            } catch {
                Alert.Basic(message: "Error.Wallet.CreateFailed".localized).show(self)
            }
        } else {
            do {
                guard let name = privNameBox.textField.text else { return }
                try WCreator.importWallet(alias: name.removeContinuosSuffix(string: " "), password: privPassword1.textField.text!, completion: {
                    WManager.loadWalletList()
                    let app = UIApplication.shared.delegate as! AppDelegate
                    if let nav = app.window?.rootViewController as? UINavigationController {
                        let main = nav.viewControllers[0] as! MainViewController
                        main.currentIndex = 0
                        main.loadWallets()
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        let main = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                        app.window?.rootViewController = main
                        self.dismiss(animated: true, completion: nil)
                    }
                })
            } catch {
                Log("\(error)")
                Alert.Basic(message: "Error.Wallet.CreateFailed".localized).show(self)
            }
        }
    }
}
