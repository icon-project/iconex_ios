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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        navTitleView.actionHandler = {
            self.navigationController?.popToRootViewController(animated: true)
        }
        
        scroll.rx.didEndDecelerating
            .subscribe { (_) in
                self.pageControl.currentPage = Int(self.scroll.contentOffset.x / self.scroll.frame.width)
        }.disposed(by: disposeBag)
        
        navTitleView.set(title: "CreateWallet.Create".localized)
        navTitleView.setButtonImage(image: #imageLiteral(resourceName: "icAppbarBack"))
        
        // address
        headerLabel.size20(text: "Wallet.Address".localized, color: .gray77, weight: .medium, align: .center)
        copyButton.cornered(size: 12)
        copyButton.border(1, .gray230)
        copyButton.setTitle("Wallet.Address.Copy".localized, for: .normal)
        copyButton.setTitleColor(.gray128, for: .normal)
        
        // private key
        headerLabel2.size20(text: "Wallet.Address".localized, color: .gray77, weight: .medium, align: .center)
        copyButton2.border(1, .gray230)
        copyButton2.setTitle("Wallet.PrivateKey.Copy".localized, for: .normal)
        copyButton2.setTitleColor(.gray128, for: .normal)
        
        pageControl.numberOfPages = 2
        pageControl.currentPageIndicatorTintColor = UIColor.init(white: 0, alpha: 0.7)
        pageControl.pageIndicatorTintColor = UIColor.init(white: 0, alpha: 0.2)
        
        copyButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                UIPasteboard.general.string = self.address
                self.view.showToast(message: "Wallet.Address.CopyComplete".localized)
        }.disposed(by: disposeBag)
        
        copyButton2.rx.tap.asControlEvent()
            .subscribe { (_) in
                UIPasteboard.general.string = self.pk
                self.view.showToast(message: "Wallet.PrivateKey.Copy.Message".localized)
            }.disposed(by: disposeBag)
        
    }
    
    override func refresh() {
        super.refresh()
        
        if let address = self.address, let pk = self.pk {
            guard let qrCodeSource = address.generateQRCode() else { return }
            guard let qrCodeSource2 = pk.generateQRCode() else { return }
            
            self.qrImageView.image = UIImage(ciImage: qrCodeSource)
            self.qrImageView2.image = UIImage(ciImage: qrCodeSource2)
            
            self.infoLabel.size12(text: address, color: .gray77, align: .center)
            copyButton2.cornered(size: 12)
            self.infoLabel2.text = pk
            
            self.infoLabel2.size12(text: pk, color: .gray77, align: .center)
            copyButton2.cornered(size: 12)
        }
    }
}