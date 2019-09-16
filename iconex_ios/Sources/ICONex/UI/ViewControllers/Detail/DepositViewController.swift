//
//  DepositViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 16/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class DepositViewController: PopableViewController {
    @IBOutlet weak var walletAddressTitle: UILabel!
    @IBOutlet weak var qrImage: UIImageView!
    @IBOutlet weak var walletAddressLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var inputBox: IXInputBox!
    @IBOutlet weak var requestButton: UIButton!
    @IBOutlet weak var descLabel: UILabel!
    
    var wallet: BaseWalletConvertible!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        titleContainer.set(title: wallet.name)
        titleContainer.actionHandler = {
            self.dismiss(animated: true, completion: nil)
        }
        
        walletAddressTitle.size20(text: "Wallet.Address".localized, color: .gray77, weight: .medium, align: .center)
        
        guard let qrCodeSource = wallet.address.generateQRCode() else { return }
        self.qrImage.image = UIImage(ciImage: qrCodeSource)
        
        walletAddressLabel.size12(text: wallet.address.add0xPrefix(), color: .gray77, align: .center)
        walletAddressLabel.adjustsFontSizeToFitWidth = true
        
        copyButton.roundGray230()
        copyButton.setTitle("Wallet.Address.Copy".localized, for: .normal)
        copyButton.rx.tap.subscribe(onNext: {
            copyString(message: self.wallet.address)
            Tool.toast(message: "Wallet.Address.CopyComplete".localized)
        }).disposed(by: disposeBag)
        
        inputBox.set(state: .normal, placeholder: "Main.QRCode.InputBox.Placeholder".localized)
        requestButton.roundGray230()
        requestButton.setTitle("Main.QRCode.Request".localized, for: .normal)
        
        descLabel.size12(text: "Main.QRCode.Description".localized, color: .mint1, weight: .light)
        descLabel.numberOfLines = 0
    }
    
    
}
