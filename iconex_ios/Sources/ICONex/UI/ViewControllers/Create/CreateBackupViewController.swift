//
//  CreateBackupViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 02/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class CreateBackupViewController: BaseViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var mintBoxView: UIView!
    @IBOutlet weak var mintLabel: UILabel!
    @IBOutlet weak var descLabel1: UILabel!
    @IBOutlet weak var descLabel2: UILabel!
    
    var delegate: createWalletSequence! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        headerLabel.size16(text: "Create.Wallet.Step3.Header".localized, color: .gray77, weight: .medium, align: .center)
        
        downloadButton.layer.masksToBounds = true
        downloadButton.layer.cornerRadius = 4
        downloadButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        downloadButton.setTitle("Create.Wallet.Step3.Download".localized, for: .normal)
        downloadButton.setTitleColor(.gray128, for: .normal)
        downloadButton.border(1, .gray230)
        
        mintBoxView.mintBox()
        mintLabel.size12(text: "Create.Wallet.Step3.Footer".localized, color: .mint1, weight: .regular, align: .left)
        
        descLabel1.size12(text: "Create.Wallet.Step3.Desc.1_1".localized, color: .mint1, weight: .light, align: .left)
        descLabel2.size12(text: "Create.Wallet.Step3.Desc.1_2".localized, color: .mint1, weight: .light, align: .left)
        
        
        downloadButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                Alert.basic(title: "Create.Wallet.Step3.Alert.Info1".localized, subtitle: "Create.Wallet.Step3.Alert.Info2".localized, isOnlyOneButton: false, confirmAction: {
                    var filePath: URL = URL(fileURLWithPath: "")
                    do {
                        if let myWallet = self.delegate.newWallet as? ICXWallet {
                            filePath = try myWallet.getBackupKeystoreFilepath()

                        } else if let myWallet = self.delegate.newWallet as? ETHWallet {
                            filePath = try myWallet.getBackupKeystoreFilepath()
                        }
                        
                        self.export(filepath: filePath, sender: self.downloadButton) { (_, completed, _, _) in
                            if completed {
                                self.delegate.isBackup = true
                                Alert.basic(title: "Create.Wallet.Step3.Alert.Save".localized, leftButtonTitle: "Common.Confirm".localized).show()
                            }
                        }
                    } catch {
                        Alert.basic(title: "Error.CommonError".localized, confirmAction: nil).show()
                    }
                }).show()
                
            }.disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        
    }
}

extension CreateBackupViewController: Exportable {
    
}
