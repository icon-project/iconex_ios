//
//  WalletExportPasswordViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class WalletExportPasswordViewController: UIViewController {
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var navLabel: UILabel!
    @IBOutlet weak var titleLabel1: UILabel!
    @IBOutlet weak var contentLabel1: UILabel!
    @IBOutlet weak var contentLabel2: UILabel!
    @IBOutlet weak var titleLabel2: UILabel!
    @IBOutlet weak var passwordInputBox: IXInputBox!
    @IBOutlet weak var confirmInputBox: IXInputBox!
    @IBOutlet weak var makeButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var items: [WalletBundleItem]?
    
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
    
    func initialize() {
        navLabel.text = "BundleExport.Step1.NavTitle".localized
        titleLabel1.text = "BundleExport.Step2.Header".localized
        contentLabel1.text = "BundleExport.Step2.Desc1".localized
        contentLabel2.text = "BundleExport.Step2.Desc2".localized
        titleLabel2.text = "BundleExport.BundlePassword".localized
        passwordInputBox.textField.placeholder = "Placeholder.InputWalletPassword".localized
        passwordInputBox.setState(.normal, nil)
        passwordInputBox.setType(.newPassword)
        passwordInputBox.textField.returnKeyType = .next
        confirmInputBox.textField.placeholder = "Placeholder.ConfirmWalletPassword".localized
        confirmInputBox.setState(.normal, nil)
        confirmInputBox.setType(.newPassword)
        makeButton.setTitle("BundleExport.Step2.Download".localized, for: .normal)
        makeButton.styleDark()
        makeButton.rounded()
        
        passwordInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.passwordInputBox.setState(.focus)
        }).disposed(by: disposeBag)
        passwordInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.validatePassword()
        }).disposed(by: disposeBag)
        passwordInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            self.confirmInputBox.textField.becomeFirstResponder()
        }).disposed(by: disposeBag)
        
        confirmInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.confirmInputBox.setState(.focus)
        }).disposed(by: disposeBag)
        confirmInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.validateConfirm()
        }).disposed(by: disposeBag)
        confirmInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            
        }).disposed(by: disposeBag)
        
        let observePassword = passwordInputBox.textField.rx.text
            .map { _ in
                return self.validatePassword(false)
        }
        
        let observeConfirm = confirmInputBox.textField.rx.text
            .map { _ in
                return self.validateConfirm(false)
        }
        
        Observable.combineLatest([observePassword, observeConfirm]) { iterator -> Bool in
            return iterator.reduce(true, { $0 && $1 })
        }.bind(to: makeButton.rx.isEnabled).disposed(by: disposeBag)
        
        backButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                self.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
        
        makeButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                Alert.Confirm(message: "Alert.DownloadKeystore".localized, cancel: "Common.Cancel".localized, confirm: "Common.Confirm".localized, handler: {
                    self.createBundleList()
                }).show(self)
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
        
        makeButton.isEnabled = false
    }
    @discardableResult
    func validatePassword(_ showError: Bool = true) -> Bool {
        guard let password = passwordInputBox.textField.text, password.length != 0 else {
            if showError { passwordInputBox.setState(.error, "Error.Password".localized) }
            return false
        }
        
        if password.length < 8 {
            if showError { self.passwordInputBox.setState(.error, "Error.Password.Length".localized) }
            return false
        }
        guard Validator.validateCharacterSet(password: password) else {
            if showError { self.passwordInputBox.setState(.error, "Error.Password.CharacterSet".localized) }
            return false
        }
        guard Validator.validateSequenceNumber(password: password) else {
            if showError { self.passwordInputBox.setState(.error, "Error.Password.Serialize".localized) }
            return false
        }
        
        passwordInputBox.setState(.normal, "")
        
        return true
    }
    @discardableResult
    func validateConfirm(_ showError: Bool = true) -> Bool {
        guard let confirm = confirmInputBox.textField.text else {
            if showError { confirmInputBox.setState(.error, "Error.Password.Mismatch".localized) }
            return false
        }
        guard let password = passwordInputBox.textField.text, password.length != 0 else {
            return false
        }
        
        if password != confirm {
            if showError { confirmInputBox.setState(.error, "Error.Password.Mismatch".localized) }
            return false
        }
        
        confirmInputBox.setState(.normal, "")
        
        return true
    }
    
    func createBundleList() {
        guard let items = self.items else {
            return
        }
        let creator = BundleCreator(items: items)
        creator.createBundle(newPassword: self.passwordInputBox.textField.text!, completion: { (isSuccess, filePath) in
            if isSuccess {
                guard let filepath = filePath else {
                    return
                }
                
                let app = UIApplication.shared.delegate as! AppDelegate
                
                app.fileShare(filepath: filepath, self.makeButton)
                
            } else {
                Log.Debug("Error: export bundle")
            }
        })
    }
}
