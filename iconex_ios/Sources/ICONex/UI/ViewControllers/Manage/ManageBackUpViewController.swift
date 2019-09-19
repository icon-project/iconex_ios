//
//  MainBackUpViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 28/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ManageBackUpViewController: BaseViewController {
    @IBOutlet weak var navBar: IXNavigationView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton!
    
    @IBOutlet weak var keystoreBoxView: UIView!
    @IBOutlet weak var keystoreDescLabel: UILabel!
    @IBOutlet weak var keystoreInfoLabel: UILabel!
    
    @IBOutlet weak var pkBoxView: UIView!
    @IBOutlet weak var pkTitleLabel: UILabel!
    @IBOutlet weak var pkTitleLineView: UIView!
    @IBOutlet weak var pkLabel: UILabel!
    @IBOutlet weak var pkToggleButton: UIButton!
    
    @IBOutlet weak var copyPkButton: UIButton!
    @IBOutlet weak var walletInfoButton: UIButton!
    
    @IBOutlet weak var pkAttentionView: UIView!
    @IBOutlet weak var pkAttentionLabel: UILabel!
    
    @IBOutlet weak var pkNoPasswordLabel: UILabel!
    
    var wallet: BaseWalletConvertible? = nil
    var pk = String()
    
    var isPkHidden: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBind()
        
    }
    
    private func setupUI() {
        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarCloseW")) {
            self.dismiss(animated: true, completion: nil)
        }
        navBar.setTitle("Manage.Backup.NavBar.Title".localized)
        titleLabel.size16(text: "Manage.Backup.Title".localized, color: .gray77, weight: .medium, align: .center)
        
        downloadButton.setTitle("Manage.Backup.Download".localized, for: .normal)
        downloadButton.roundGray230()
        
        keystoreBoxView.mintBox()
        keystoreDescLabel.size12(text: "Manage.Backup.Keystore.Desc1".localized, color: .mint1)
        keystoreInfoLabel.size12(text: "Manage.Backup.Keystore.Desc2".localized, color: .mint1, weight: .light)
        
        pkBoxView.border(1, .gray230)
        pkBoxView.corner(4)
        pkBoxView.backgroundColor = .gray250
        
        pkTitleLabel.size12(text: "Wallet.PrivateKey".localized, color: .gray77)
        pkLabel.size16(text: String(repeating: "•", count: 62), color: .gray77)
        
        pkToggleButton.setImage(#imageLiteral(resourceName: "icInputEyeOn"), for: .normal)
        pkToggleButton.setImage(#imageLiteral(resourceName: "icInputEyeOff"), for: .selected)
        
        pkToggleButton.isSelected = false
        
        copyPkButton.roundGray230()
        copyPkButton.setTitle("Wallet.PrivateKey.Copy".localized, for: .normal)
        walletInfoButton.roundGray230()
        walletInfoButton.setTitle("Wallet.ViewInfo".localized, for: .normal)
        
        pkAttentionView.mintBox()
        pkAttentionLabel.size12(text: "Manage.Backup.PrivateKey.Desc1".localized, color: .mint1)
        pkNoPasswordLabel.size12(text: "Manage.Backup.PrivateKey.Desc2".localized, color: .mint1, weight: .light)
        
    }
    
    private func setupBind() {
        downloadButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                Alert.basic(title: "Create.Wallet.Step3.Alert.Info".localized, isOnlyOneButton: false, confirmAction: {
                    var filePath: URL = URL(fileURLWithPath: "")
                    do {
                        if let myWallet = self.wallet as? ICXWallet {
                            filePath = try myWallet.getBackupKeystoreFilepath()
                            
                        } else if let myWallet = self.wallet as? ETHWallet {
                            filePath = try myWallet.getBackupKeystoreFilepath()
                        }
                        
                        let activity = UIActivityViewController(activityItems: [filePath], applicationActivities: nil)
                        activity.excludedActivityTypes = [.postToFacebook, .postToVimeo, .postToWeibo, .postToFlickr, .postToTwitter, .postToTencentWeibo, .addToReadingList, .airDrop, .markupAsPDF, .openInIBooks, .print]
                        
                        activity.completionWithItemsHandler = { type, completed, _, error in
                            if completed {
                                Alert.basic(title: "Create.Wallet.Step3.Alert.Save".localized, leftButtonTitle: "Common.Confirm".localized).show()
                            }
                        }
                        self.present(activity, animated: true, completion: nil)
                        
                    } catch {
                        Alert.basic(title: "Error.CommonError".localized, confirmAction: nil).show()
                    }
                }).show()
                
            }.disposed(by: disposeBag)
        
        copyPkButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                UIPasteboard.general.string = self.pk
                self.view.showToast(message: "Wallet.PrivateKey.Copy.Message".localized)
        }.disposed(by: disposeBag)
        
        walletInfoButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let qrCodeVC = UIStoryboard(name: "CreateWallet", bundle: nil).instantiateViewController(withIdentifier: "QRCode") as! CreateQRCodeViewController
                qrCodeVC.address = self.wallet?.address
                qrCodeVC.pk = self.pk
                qrCodeVC.walletName = self.wallet?.name
                self.presentPanModal(qrCodeVC)
        }.disposed(by: disposeBag)
        
        pkToggleButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.isPkHidden.toggle()
                self.pkToggleButton.isSelected.toggle()
                
                if self.isPkHidden {
                    self.pkLabel.size16(text: String(repeating: "•", count: 62), color: .gray77)
                } else {
                    self.pkLabel.size16(text: self.pk, color: .gray77)
                }
        }.disposed(by: disposeBag)
    }
}
extension ManageBackUpViewController {
    func export(filepath: URL, _ completion: UIActivityViewController.CompletionWithItemsHandler?, _ sourceView: UIView) {
        let activity = UIActivityViewController(activityItems: [filepath], applicationActivities: nil)
        activity.excludedActivityTypes = [.postToVimeo, .postToWeibo, .postToFlickr, .postToTwitter, .postToFacebook, .postToTencentWeibo, .addToReadingList, .assignToContact, .openInIBooks]
        activity.completionWithItemsHandler = completion
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let vc = activity.popoverPresentationController {
                vc.sourceView = sourceView
                vc.permittedArrowDirections = .up
                vc.sourceRect = sourceView.bounds
            }
        }
        self.present(activity, animated: true, completion: nil)
    }
}
