//
//  BindPasswordViewController.swift
//  iconex_ios
//
//  Created by Seungyeon Lee on 2019/09/08.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import ICONKit
import BigInt
import PanModal

class BindPasswordViewController: BaseViewController {
    @IBOutlet weak var navBar: PopableTitleView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    @IBOutlet weak var passwordInputBox: IXInputBox!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    var selectedWallet: ICXWallet?
    private var privateKey: PrivateKey?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
        
        self.scrollView?.rx.didScroll
            .subscribe({ (_) in
                self.view.endEditing(true)
                
            }).disposed(by: disposeBag)
    }
    
    func initialize() {
        guard let wallet = self.selectedWallet else { return }
        
        navBar.actionHandler = {
            Alert.basic(title: "Alert.Connect.Password.Cancel1".localized, subtitle: "Alert.Connect.Password.Cancel2".localized, isOnlyOneButton: false, confirmAction: {
                Conn.sendError(error: ConnectError.userCancel)
            }).show()
        }
        
        passwordInputBox.set { (password) -> String? in
            guard let prvKey = try? wallet.extractICXPrivateKey(password: password) else {
                self.confirmButton.isEnabled = false
                self.privateKey = nil
                return "Error.Password.Wrong".localized
            }
            self.confirmButton.isEnabled = true
            self.privateKey = prvKey
            return nil
        }
        
        cancelButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                Alert.basic(title: "Alert.Connect.Password.Cancel1".localized, subtitle: "Alert.Connect.Password.Cancel2".localized, isOnlyOneButton: false, confirmAction: {
                    Conn.sendError(error: ConnectError.userCancel)
                }).show()
        }.disposed(by: disposeBag)
        
        confirmButton.rx.tap.asControlEvent().subscribe(onNext: {
            guard Conn.received != nil else { return }
            self.showSendICX()
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        navBar.set(title: "Alert.Wallet.RequestPassword".localized)
        
        passwordInputBox.set(inputType: .confirmPassword)
        passwordInputBox.set(state: .normal, placeholder: "Placeholder.InputPassword".localized)
        
        cancelButton.setTitle("Common.Cancel".localized, for: .normal)
        cancelButton.round02()
        
        confirmButton.setTitle("Common.Confirm".localized, for: .normal)
        confirmButton.lightMintRounded()
        confirmButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let wallet = selectedWallet else {
            assertionFailure("Wallet info required")
            return
        }
        
        self.nameLabel.size14(text: wallet.name, color: .gray77, weight: .semibold)
        self.addressLabel.size12(text: wallet.address, color: .gray179, weight: .light)
        
        if let decimal = Conn.tokenDecimal, let symbol = Conn.tokenSymbol {
            guard let contract = Conn.received?.payload?.params.to else { return }
            
            let balance = Manager.balance.getTokenBalance(address: wallet.address, contract: contract)
            
            self.balanceLabel.size14(text: balance?.toString(decimal: decimal, 4).currencySeparated() ?? "-", color: .gray77, weight: .bold)
            self.symbolLabel.size14(text: symbol.uppercased(), color: .gray77, align: .right)
            
            
        } else {
            let balance = Manager.balance.getBalance(wallet: wallet) ?? 0
            self.balanceLabel.size14(text: balance.toString(decimal: 18, 4).currencySeparated(), color: .gray77, weight: .bold)
            self.symbolLabel.size14(text: "ICX", color: .gray77, align: .right)
        }
    }
    
    func showSendICX() {
        let sendView = UIStoryboard(name: "Connect", bundle: nil).instantiateViewController(withIdentifier: "ConnectSendView") as! ConnectSendViewController
        sendView.selectedWallet = self.selectedWallet
        sendView.privateKey = self.privateKey
        guard let payload = Conn.received?.payload else {
            Conn.sendError(error: .invalidJSON)
            return
        }
        sendView.connTx = payload.params
        self.presentPanModal(sendView)
    }
}

extension BindPasswordViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    func shouldRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return false
    }
    
    var isHapticFeedbackEnabled: Bool {
        return false
    }
    
    var topOffset: CGFloat {
        return app.window!.safeAreaInsets.top
    }
    
    var backgroundAlpha: CGFloat {
        return 0.4
    }
    
    var cornerRadius: CGFloat {
        return 18.0
    }
}
