//
//  WalletBackupViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class WalletBackupViewController: UIViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var topTitle: UILabel!
    @IBOutlet weak var backupTitle: UILabel!
    @IBOutlet weak var backupUpper: UILabel!
    @IBOutlet weak var backupLower: UILabel!
    @IBOutlet weak var backupButton: UIButton!
    @IBOutlet weak var privkeyTitle: UILabel!
    @IBOutlet weak var privkeyUpper: UILabel!
    @IBOutlet weak var privkeyLower: UILabel!
    @IBOutlet weak var privkeyContainer: UIView!
    @IBOutlet weak var privkeyLabel: UILabel!
    @IBOutlet weak var eyeButton: UIButton!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var walletButton: UIButton!
    
    var walletInfo: WalletInfo?
    var privKey: String?
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initialize() {
        navTitle.text = "Wallet.Backup".localized
        
        topTitle.text = "Backup.StepTitle".localized
        backupTitle.text = "Backup.Header1".localized
        backupUpper.text = "Backup.Desc1_1".localized
        backupLower.text = "Backup.Desc1_2".localized
        backupButton.styleDark()
        backupButton.cornered()
        backupButton.setTitle("Backup.Download".localized, for: .normal)
        privkeyTitle.text = "Backup.Header2".localized
        privkeyUpper.text = "Backup.Desc2_1".localized
        privkeyLower.text = "Backup.Desc2_2".localized
        copyButton.styleDark()
        copyButton.cornered()
        copyButton.setTitle("Wallet.PrivateKey.Copy".localized, for: .normal)
        walletButton.styleDark()
        walletButton.cornered()
        walletButton.setTitle("Wallet.ViewInfo".localized, for: .normal)
        
        privkeyLabel.text = String(repeating: "•", count: 62)
        
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
        
        backupButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                let confirmAction = Alert.Confirm(message: "Alert.DownloadKeystore".localized, cancel: "Common.Cancel".localized, confirm: "Common.Confirm".localized, handler: {
                    
                    do {
                        guard let coinType = self.walletInfo?.type else {
                            return
                        }
                        var filepath: URL = URL(fileURLWithPath: "")
                        switch coinType {
                        case .icx:
                            let wallet = WManager.loadWalletBy(info: self.walletInfo!) as! ICXWallet
                            filepath = try wallet.getBackupKeystoreFilepath()
                            
                        case .eth:
                            let wallet = WManager.loadWalletBy(info: self.walletInfo!) as! ETHWallet
                            filepath = try wallet.getBackupKeystoreFilepath()
                            break
                            
                        default:
                            break
                        }
                        
                        let app = UIApplication.shared.delegate as! AppDelegate
                        app.fileShare(filepath: filepath, self.backupButton)
                        
                    } catch {
                        Log.Debug(error)
                        Alert.Basic(message: "Error.CommonError".localized).show(self)
                    }
                })
                
                self.present(confirmAction, animated: true, completion: nil)
            }).disposed(by: disposeBag)
        
        copyButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let prvKey = self.privKey else {
                    return
                }
                copyString(message: prvKey)
                Tools.toast(message: "Wallet.PrivateKey.Copy.Message".localized)
            }).disposed(by: disposeBag)
        
        eyeButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                self.eyeButton.isSelected = !self.eyeButton.isSelected
                if self.eyeButton.isSelected {
                    self.privkeyLabel.text = self.privKey
                } else {
                    self.privkeyLabel.text = String(repeating: "•", count: 62)
                }
            }).disposed(by: disposeBag)
        
        walletButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                let info = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "WalletPrivateInfo") as! WalletPrivateInfoViewController
                let wallet = WManager.loadWalletBy(info: self.walletInfo!)
                info.wallet = wallet
                info.privKey = self.privKey
                self.present(info, animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }
}
