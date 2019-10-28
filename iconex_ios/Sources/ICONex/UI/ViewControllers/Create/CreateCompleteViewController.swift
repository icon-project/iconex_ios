//
//  CreateCompleteViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 02/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class CreateCompleteViewController: BaseViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var pkView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var privateKeyLabel: UILabel!
    @IBOutlet weak var toggleButton: UIButton!
    
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    
    @IBOutlet weak var mintView: UIView!
    @IBOutlet weak var mintLabel: UILabel!
    @IBOutlet weak var descLabel1: UILabel!
    @IBOutlet weak var descLabel2: UILabel!
    
    var delegate: createWalletSequence! = nil
    
    private var isHiddenPk: Bool = true
    private var privateKey: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        headerLabel.size16(text: "Create.Wallet.Step4.Header".localized, color: .gray77, weight: .medium, align: .center)
        
        pkView.border(1, .gray230)
        pkView.corner(4)
        pkView.backgroundColor = .gray250
        
        titleLabel.size12(text: "Private Key", color: .gray77, weight: .regular)
        
        copyButton.setTitle("Create.Wallet.Step4.Copy".localized, for: .normal)
        copyButton.cornered(size: 12)
        copyButton.border(1, .gray230)
        copyButton.setTitleColor(.gray128, for: .normal)
        
        infoButton.setTitle("Create.Wallet.Step4.WalletInfo".localized, for: .normal)
        infoButton.cornered(size: 12)
        infoButton.border(1, .gray230)
        infoButton.setTitleColor(.gray128, for: .normal)
        
        mintView.mintBox()
        mintLabel.size12(text: "Create.Wallet.Step4.Footer".localized, color: .mint1, weight: .regular, align: .left)
        
        descLabel1.size12(text: "Create.Wallet.Step4.Desc.1".localized, color: .mint1, weight: .light, align: .left)
        descLabel2.size12(text: "Create.Wallet.Step4.Desc.2".localized, color: .mint1, weight: .light, align: .left)
        
        toggleButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.isHiddenPk.toggle()
                self.privateKeyLabel.size16(text: self.isHiddenPk ? self.privateKey : String(repeating: "•", count: 62), color: .gray77, weight: .regular, align: .left)
                
                if self.isHiddenPk {
                    self.toggleButton.setImage(#imageLiteral(resourceName: "icInputEyeOff"), for: .normal)
                } else {
                    self.toggleButton.setImage(#imageLiteral(resourceName: "icInputEyeOn"), for: .normal)
                }
                
        }.disposed(by: disposeBag)
        
        copyButton.rx.tap.asControlEvent()
            .subscribe(onNext: { (_) in
                UIPasteboard.general.string = self.privateKey
                Toast.toast(message: "Wallet.PrivateKey.Copy.Message".localized)
            }).disposed(by: disposeBag)
        
        infoButton.rx.tap.asControlEvent()
            .subscribe(onNext: { (_) in
                let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "QRCode") as! CreateQRCodeViewController
                nextVC.address = self.delegate.newWallet?.address
                nextVC.pk = self.privateKey
                nextVC.walletName = self.delegate.newWallet?.name
                self.presentPanModal(nextVC)
            }).disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        if let myWallet = self.delegate.newWallet {
            guard let password = self.delegate.walletInfo?.password else { return }
            do {
                if let icx = myWallet as? ICXWallet {
                    self.privateKey = try icx.extractICXPrivateKey(password: password).hexEncoded
                } else if let eth = myWallet as? ETHWallet {
                    self.privateKey = try eth.extractETHPrivateKey(password: password)
                }
                privateKeyLabel.size16(text: String(repeating: "•", count: 62), color: .gray77, weight: .regular, align: .left)
            } catch let err {
                Log(err, .error)
            }
        }
    }
}
