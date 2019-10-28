//
//  CreateQRCodeViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 09/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import PanModal
import RxSwift
import RxCocoa

class CreateQRCodeViewController: BaseViewController {
    @IBOutlet weak var navTitleView: PopableTitleView!
    
    @IBOutlet weak var scroll: UIScrollView!
    
    // address
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!
    
    // private key
    @IBOutlet weak var headerLabel2: UILabel!
    @IBOutlet weak var qrImageView2: UIImageView!
    @IBOutlet weak var infoLabel2: UILabel!
    @IBOutlet weak var copyButton2: UIButton!
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    var delegate: createWalletSequence! = nil
    
    var address: String?
    var pk: String?
    var walletName: String?
    
    var isfirstTime: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    // ???
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIView.animate(withDuration: 0.4) {
            self.view.alpha = 0.0
        }
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        pageControl.isUserInteractionEnabled = false
        
        navTitleView.actionHandler = {
            self.dismiss(animated: true, completion: nil)
        }
        
        scroll.rx.didEndDecelerating
            .subscribe { (_) in
                self.pageControl.currentPage = Int(self.scroll.contentOffset.x / self.scroll.frame.width)
                
                if self.pageControl.currentPage == 1 && self.isfirstTime {
                    self.isfirstTime = false
                    Alert.basic(title: "Alert.QRCode.PrivateKey".localized, leftButtonTitle: "Common.Confirm".localized).show()
                }
        }.disposed(by: disposeBag)
        
        guard let name = self.walletName else { return }
        navTitleView.set(title: name)
        navTitleView.setButtonImage(image: #imageLiteral(resourceName: "icAppbarClose"))
        
        // address
        headerLabel.size20(text: "Wallet.Address".localized, color: .gray77, weight: .medium, align: .center)
        copyButton.roundGray230()
        copyButton.setTitle("Wallet.Address.Copy".localized, for: .normal)
        
        // private key
        headerLabel2.size20(text: "Wallet.PrivateKey".localized, color: .gray77, weight: .medium, align: .center)
        copyButton2.roundGray230()
        copyButton2.setTitle("Wallet.PrivateKey.Copy".localized, for: .normal)
        
        pageControl.numberOfPages = 2
        pageControl.currentPageIndicatorTintColor = UIColor.init(white: 0, alpha: 0.7)
        pageControl.pageIndicatorTintColor = UIColor.init(white: 0, alpha: 0.2)
        
        copyButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                UIPasteboard.general.string = self.address
                Toast.toast(message: "Wallet.Address.CopyComplete".localized)
        }.disposed(by: disposeBag)
        
        copyButton2.rx.tap.asControlEvent()
            .subscribe { (_) in
                UIPasteboard.general.string = self.pk
                Toast.toast(message: "Wallet.PrivateKey.Copy.Message".localized)
            }.disposed(by: disposeBag)
        
    }
    
    override func refresh() {
        super.refresh()
        
        if let address = self.address, let pk = self.pk {
            guard let qrCodeSource = address.add0xPrefix().generateQRCode() else { return }
            guard let qrCodeSource2 = pk.generateQRCode() else { return }
            
            self.qrImageView.image = UIImage(ciImage: qrCodeSource)
            self.qrImageView2.image = UIImage(ciImage: qrCodeSource2)
            
            self.infoLabel.size12(text: address, color: .gray77, align: .center)
            self.infoLabel2.text = pk
            
            self.infoLabel2.size12(text: pk, color: .gray77, align: .center)
        }
    }
}

extension CreateQRCodeViewController: PanModalPresentable {
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
        return app.window!.safeAreaInsets.top + (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad ? UIApplication.shared.statusBarFrame.height : 0)
    }
    
    var backgroundAlpha: CGFloat {
        return 0.4
    }
    
    var cornerRadius: CGFloat {
        return 18.0
    }
    
}
