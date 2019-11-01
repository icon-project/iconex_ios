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
//import MessageUI

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
    
    @IBOutlet weak var fakeView: UIView!
    @IBOutlet weak var fakeImageView: UIImageView!
    @IBOutlet weak var fakeTop: NSLayoutConstraint!
    
    weak var delegate: MainCollectionDelegate?
    
    var wallet: BaseWalletConvertible? = nil {
        willSet {
            self.isICX = newValue is ICXWallet
        }
    }
    
    var isICX: Bool = true
    
    var fakeImage: UIImage?
    var dismissAction: (() -> Void)?
    let topOffset: CGFloat = 56
    var startHeight: CGFloat = 56
    
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
        sendButton.setTitle("Main.QRCode.Create".localized, for: .normal)
        
        descLabel.size12(text: "Main.QRCode.Description".localized, color: .mint1, weight: .light)
        
        dismissButton.rounded()
        
        fakeView.corner(18)
        
        if !isICX {
            inputBox.isHidden = true
            sendButton.isHidden = true
            descLabel.isHidden = true
        }
        
        // copy
        copyButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                bzz()
                UIPasteboard.general.string = self.wallet?.address.add0xPrefix() ?? ""
                Toast.toast(message: "Wallet.Address.CopyComplete".localized)
        }.disposed(by: disposeBag)
        
        sendButton.rx.tap.subscribe(onNext: {
            self.view.endEditing(true)
            let input = self.inputBox.text
            
            if !input.isEmpty {
                let amount = input.bigUInt(decimal: 18)
                guard let qrString = Tool.toConnectString(address: self.wallet!.address, amount: amount) else { return }
                guard let qrCodeSource = qrString.generateQRCode() else { return }
                self.qrImageView.image = UIImage(ciImage: qrCodeSource)
            } else {
                guard let qrCodeSource = self.wallet!.address.add0xPrefix().generateQRCode() else { return }
                self.qrImageView.image = UIImage(ciImage: qrCodeSource)
            }
            }).disposed(by: disposeBag)
        
//        sendButton.rx.tap.asControlEvent()
//            .subscribe { (_) in
//                if MFMessageComposeViewController.canSendText() {
//                    let messageVC = MFMessageComposeViewController()
//                    messageVC.delegate = self
//                    messageVC.body = "\(self.inputBox.text)ICX를 ICONex 지갑으로 보내주세요."
//
//                    // Add PNG
//                    if MFMessageComposeViewController.canSendAttachments() {
//                        guard let wallet = self.wallet else { return }
//                        guard let qrCodeSource = wallet.address.generateQRCode() else { return }
//
//                        guard let cgImageSource = qrCodeSource.convertCIImageToCGImage() else { return }
//                        let image = UIImage(cgImage: cgImageSource)
//
//                        // scale
//                        if let dataImage = image.pngData() {
//                            messageVC.addAttachmentData(dataImage, typeIdentifier: "image/png", filename: "ImageData.png")
//                        }
//
//                    }
//
//                    self.present(messageVC, animated: true, completion: nil)
//                }
//        }.disposed(by: disposeBag)
        
        dismissButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.beginClose()
        }.disposed(by: disposeBag)
        
        inputBox.set { (value) -> String? in
            guard !value.isEmpty else { return nil }
            let exchangedInfo = "icxusd"
            return "$ " + Tool.calculatePrice(decimal: 18, currency: exchangedInfo, balance: Tool.stringToBigUInt(inputText: value, decimal: 18, fixed: false))
        }

        fakeTop.constant = startHeight
        cardView.layer.transform = CATransform3DMakeRotation(.pi / 2, 0.0, 1.0, 0.0)
        fakeImageView.image = fakeImage
    }
    
    override func refresh() {
        super.refresh()
        guard let wallet = self.wallet else { return }
        
        nameLabel.size20(text: wallet.name, color: .gray77, weight: .medium, align: .center)
        
        DispatchQueue.main.async {
            guard let qrCodeSource = wallet.address.add0xPrefix().generateQRCode() else { return }
            self.qrImageView.image = UIImage(ciImage: qrCodeSource)
        }
        
        addressLabel.size12(text: wallet.address.add0xPrefix(), color: .gray77, align: .center)
        addressLabel.adjustsFontSizeToFitWidth = true
        
        inputBox.set(inputType: .decimal)
        inputBox.set(state: .normal, placeholder: "Main.QRCode.InputBox.Placeholder".localized)
        inputBox.set(maxDecimalLength: 8)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        beginShow()
    }
    
    func beginShow() {
        UIView.animateKeyframes(withDuration: 0.4, delay: 0.0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.2, animations: {
                self.fakeView.layer.transform = CATransform3DMakeRotation(-.pi / 2, 0.0, 1.0, 0.0)
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.2, animations: {
                self.cardView.layer.transform = CATransform3DMakeRotation(0.0, 0.0, 1.0, 0.0)
            })
        }, completion: { _ in
            self.fakeView.isHidden = true
        })
    }
    
    func beginClose() {
        UIView.animateKeyframes(withDuration: 0.4, delay: 0.0, options: [], animations: {
            self.fakeView.isHidden = false
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.2, animations: {
                self.cardView.layer.transform = CATransform3DMakeRotation(.pi / 2, 0, 1, 0)
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.2, animations: {
                self.fakeView.layer.transform = CATransform3DMakeRotation(0, 0, 1, 0)
            })
        }, completion: { _ in
            self.delegate?.cardFlip(false)
            self.dismiss(animated: false, completion: {
                self.dismissAction?()
            })
        })
    }
}

//extension MainQRCodeViewController: MFMessageComposeViewControllerDelegate {
//    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
//        switch result {
//        case .cancelled:
//            print("cancelled")
//            break
//        case .failed:
//            print("failed")
//            break
//        case .sent:
//            print("sent")
//            break
//        default:
//            print("err")
//            break
//        }
//        controller.dismiss(animated: true, completion: nil)
//    }
//}
