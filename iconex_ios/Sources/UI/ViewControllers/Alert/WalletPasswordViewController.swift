//
//  WalletPasswordViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class WalletPasswordViewController: UIViewController {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var alertTitle: UILabel!
    @IBOutlet weak var passwordInputBox: IXInputBox!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var walletInfo: WalletInfo?
    
    var confirmHandler: ((_ isSuccess: Bool, _ privKey: String) -> Void)?
    
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
        
        passwordInputBox.textField.becomeFirstResponder()
    }
    
    func initialize() {
        alertView.corner(12)
        alertTitle.text = "Alert.Wallet.RequestPassword".localized
        passwordInputBox.setState(.normal, "")
        passwordInputBox.setType(.password)
        passwordInputBox.textField.placeholder = "Placeholder.InputWalletPassword".localized
        cancelButton.styleDark()
        cancelButton.setTitle("Common.Cancel".localized, for: .normal)
        confirmButton.styleLight()
        confirmButton.setTitle("Common.Confirm".localized, for: .normal)
        confirmButton.isEnabled = false
        
        passwordInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            guard let password = self.passwordInputBox.textField.text, password == "" else { return }
            self.passwordInputBox.setState(.error, "Error.Password".localized)
        }).disposed(by: disposeBag)
        
        cancelButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                self.passwordInputBox.textField.resignFirstResponder()
                if let handler = self.confirmHandler {
                    handler(false, "")
                }
                self.dismiss(animated: true, completion: {
                    
                })
            }).disposed(by: disposeBag)
        
        confirmButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                
                do {
                    var privKey: String = ""
                    if self.walletInfo!.type == .icx {
                        let icx = WManager.loadWalletBy(info: self.walletInfo!) as! ICXWallet
                        privKey = try icx.extractICXPrivateKey(password: self.passwordInputBox.textField.text!)
                        
                        self.passwordInputBox.textField.resignFirstResponder()
                    } else if self.walletInfo!.type == .eth {
                        let eth = WManager.loadWalletBy(info: self.walletInfo!) as! ETHWallet
                        privKey = try eth.extractETHPrivateKey(password: self.passwordInputBox.textField.text!)
                    }
                    
                    self.dismiss(animated: true, completion: {
                        if let handler = self.confirmHandler {
                            handler(true, privKey)
                        }
                    })
                } catch {
                    Log.Debug("error: \(error)")
                    self.passwordInputBox.setState(.error, "Error.Password.Wrong".localized)
                }
            }).disposed(by: disposeBag)
        
        passwordInputBox.textField.rx.text.map { $0!.length > 0 }
            .subscribe(onNext: {
                self.confirmButton.isEnabled = $0
            }).disposed(by: disposeBag)
        
        keyboardHeight().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] (height: CGFloat) in
                
                var center = self.view.center.y
                center = center - ((self.view.frame.height - height + UIApplication.shared.statusBarFrame.height) / 2)
                
                self.bottomConstraint.constant = -center
                UIView.animate(withDuration: 0.25, animations: {
                    self.view.layoutIfNeeded()
                })
            }).disposed(by: disposeBag)
    }

    func addConfirm(completion: ((Bool, String) -> Void)?) {
        confirmHandler = completion
    }
}
