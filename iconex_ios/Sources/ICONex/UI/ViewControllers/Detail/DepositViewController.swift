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
    @IBOutlet weak var depositContainer: UIView!
    @IBOutlet weak var inputBox: IXInputBox!
    @IBOutlet weak var requestButton: UIButton!
    @IBOutlet weak var descLabel: UILabel!
    
    var wallet: BaseWalletConvertible!
    var isICX: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
//        super.initializeComponents()
        
        titleContainer.set(title: wallet.name)
        titleContainer.actionHandler = {
            self.dismiss(animated: true, completion: nil)
        }
        
        scrollView?.keyboardDismissMode = .onDrag
        
        walletAddressTitle.size20(text: "Wallet.Address".localized, color: .gray77, weight: .medium, align: .center)
        
        guard let qrCodeSource = wallet.address.add0xPrefix().generateQRCode() else { return }
        self.qrImage.image = UIImage(ciImage: qrCodeSource)
        
        walletAddressLabel.size12(text: wallet.address.add0xPrefix(), color: .gray77, align: .center)
        walletAddressLabel.adjustsFontSizeToFitWidth = true
        
        copyButton.roundGray230()
        copyButton.setTitle("Wallet.Address.Copy".localized, for: .normal)
        copyButton.rx.tap.subscribe(onNext: {
            copyString(message: self.wallet.address.add0xPrefix())
            Toast.toast(message: "Wallet.Address.CopyComplete".localized)
        }).disposed(by: disposeBag)
        
        inputBox.set(state: .normal, placeholder: "Main.QRCode.InputBox.Placeholder".localized)
        inputBox.set(inputType: .decimal)
        inputBox.set(maxDecimalLength: 8)
        inputBox.set(validator: { value in
            guard !value.isEmpty else { return nil }
            let exchangedInfo = "icxusd"
            let usdPrice = Manager.exchange.exchangeInfoList[exchangedInfo]?.price
            
            guard let usd = Float(usdPrice ?? "0"), let value = Float(value) else {
                return nil
            }
            
            let priceString = "$ " + String(format: "%.2f", usd*value)
            return priceString
        })
        
        requestButton.roundGray230()
        requestButton.setTitle("Main.QRCode.Create".localized, for: .normal)
        
        descLabel.size12(text: "Main.QRCode.Description".localized, color: .mint1, weight: .light)
        descLabel.numberOfLines = 0
        
        requestButton.rx.tap.subscribe(onNext: {
            let input = self.inputBox.text
            
            if !input.isEmpty {
                let amount = input.bigUInt(decimal: 18)
                guard let qrString = Tool.toConnectString(address: self.wallet.address, amount: amount) else { return }
                guard let qrCodeSource = qrString.generateQRCode() else { return }
                self.qrImage.image = UIImage(ciImage: qrCodeSource)
            } else {
                guard let qrCodeSource = self.wallet.address.add0xPrefix().generateQRCode() else { return }
                self.qrImage.image = UIImage(ciImage: qrCodeSource)
            }
        }).disposed(by: disposeBag)
        
        keyboardHeight().asObservable().subscribe(onNext: { height in
            if height == 0 {
                self.scrollView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            } else {
                let keyboardHeight = height - self.view.safeAreaInsets.bottom
                self.scrollView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
            }
        }).disposed(by: disposeBag)
        
        depositContainer.isHidden = !wallet.address.hasPrefix("hx") || !isICX
        descLabel.isHidden = !wallet.address.hasPrefix("hx") || !isICX
    }
    
    
}
