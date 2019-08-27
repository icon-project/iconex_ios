//
//  MainQRCodeViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 22/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MainQRCodeViewController: BaseViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var inputBox: IXInputBox!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var contentView: UIView!
    
    var wallet: BaseWalletConvertible? = nil {
        willSet {
            self.isICX = newValue is ICXWallet
        }
    }
    
    var isICX: Bool = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView?.keyboardDismissMode = .onDrag
        
        keyboardHeight().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] (height: CGFloat) in
                if height == 0 {
                    self.scrollView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                } else {
                    var keyboardHeight: CGFloat = height
                    if #available(iOS 11.0, *) {
                        keyboardHeight = keyboardHeight - self.view.safeAreaInsets.bottom
                    }
                    self.scrollView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
                }
            }).disposed(by: disposeBag)
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        // UI
        cardView.corner(18)
        
        copyButton.roundGray230()
        copyButton.setTitle("Wallet.Address.Copy".localized, for: .normal)
        
        sendButton.roundGray230()
        sendButton.setTitle("Main.QRCode.Request".localized, for: .normal)
        
        descLabel.size12(text: "Main.QRCode.Description".localized, color: .mint1, weight: .light)
        
        dismissButton.rounded()
        
        // keyboard
        
        // copy
        copyButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                UIPasteboard.general.string = self.wallet?.address ?? ""
                self.view.showToast(message: "Wallet.Address.CopyComplete".localized)
        }.disposed(by: disposeBag)
        
        sendButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                // TODO
        }.disposed(by: disposeBag)
        
        dismissButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
        inputBox.setError(message: "$\t0.000")
        
        inputBox.set { (value) -> String? in
            let exchangedInfo = self.isICX ? "icxusd" : "ethusd"
            let usdPrice = Manager.exchange.exchangeInfoList[exchangedInfo]?.price
            
            guard let usd = Float(usdPrice ?? "0"), let value = Float(value) else {
                return "Error.CommonError".localized
            }
            // TODO: qrCode image update
            let priceString = "$ " + String(usd*value)
            return priceString
        }

    }
    
    override func refresh() {
        super.refresh()
        guard let wallet = self.wallet else { return }
        
        nameLabel.size20(text: wallet.name, color: .gray77, weight: .medium, align: .center)
        
        DispatchQueue.main.async {
            guard let qrCodeSource = wallet.address.generateQRCode() else { return }
            self.qrImageView.image = UIImage(ciImage: qrCodeSource)
        }
        
        addressLabel.size12(text: wallet.address, color: .gray77, align: .center)
        
        inputBox.set(inputType: .decimal)
        inputBox.set(state: .normal, placeholder: "Main.QRCode.InputBox.Placeholder".localized)
        
    }
}
