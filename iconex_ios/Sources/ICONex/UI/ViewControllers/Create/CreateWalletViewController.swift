//
//  CreateWalletViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 01/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import ICONKit
import Web3swift
import PanModal

protocol createWalletSequence {
    var walletInfo: WalletInfo? { get set }
    var newWallet: BaseWalletConvertible? { get }
    var isICX: Bool { get set }
    var isBackup: Bool { get set }
    func validated()
    func invalidated()
}

class CreateWalletViewController: PopableViewController {
    
    @IBOutlet weak var step1ImageView: UIImageView!
    @IBOutlet weak var step2ImageView: UIImageView!
    @IBOutlet weak var step3ImageView: UIImageView!
    @IBOutlet weak var step4ImageView: UIImageView!
    
    @IBOutlet weak var line1: UIView!
    @IBOutlet weak var line2: UIView!
    @IBOutlet weak var line3: UIView!
    
    @IBOutlet weak var step1Label: UILabel!
    @IBOutlet weak var step2Label: UILabel!
    @IBOutlet weak var step3Label: UILabel!
    @IBOutlet weak var step4Label: UILabel!
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    @IBOutlet weak var stepScrollView: UIScrollView!
    
    // container view list
    private var selectVC: CreateSelectViewController!
    private var keystoreVC: CreateKeystoreViewController!
    private var backupVC: CreateBackupViewController!
    private var completeVC: CreateCompleteViewController!
    private var qrCodeVC: CreateQRCodeViewController!
    
    private var _isICX: Bool = true
    private var _newWallet: BaseWalletConvertible?
    private var _walletInfo: WalletInfo?
    private var _isBackup: Bool = false
    
    var doneAction: (() -> Void)? = nil
    
    var scrollIndex: Int = 0 {
        willSet {
            var leftTitle: String = "Common.Back".localized
            var rightTitle: String = "Common.Next".localized
            switch newValue {
            case 0:
                leftTitle = "Common.Cancel".localized
                rightButton.isEnabled = true
                
                step2Label.textColor = .gray128
                step3Label.textColor = .gray128
                step4Label.textColor = .gray128
                
                step1ImageView.image = #imageLiteral(resourceName: "icStep01On")
                step2ImageView.image = #imageLiteral(resourceName: "icStep02Off")
                step3ImageView.image = #imageLiteral(resourceName: "icStep03Off")
                step4ImageView.image = #imageLiteral(resourceName: "icStep04Off")
                
                line1.backgroundColor = .gray230
                line2.backgroundColor = .gray230
                line3.backgroundColor = .gray230
                
            case 1:
                rightButton.isEnabled = false
                
                step2Label.textColor = .mint1
                step2ImageView.image = #imageLiteral(resourceName: "icStep02On")
                line1.backgroundColor = .mint1
                
                step3Label.textColor = .gray128
                step4Label.textColor = .gray128
                
                step1ImageView.image = #imageLiteral(resourceName: "icStepCheck")
                step3ImageView.image = #imageLiteral(resourceName: "icStep03Off")
                step4ImageView.image = #imageLiteral(resourceName: "icStep04Off")
                
                line2.backgroundColor = .gray230
                line3.backgroundColor = .gray230
                
            case 2:
                rightButton.isEnabled = true
                
                step3Label.textColor = .mint1
                step3ImageView.image = #imageLiteral(resourceName: "icStep03On")
                line2.backgroundColor = .mint1
                
                step4Label.textColor = .gray128
                
                step2ImageView.image = #imageLiteral(resourceName: "icStepCheck")
                step4ImageView.image = #imageLiteral(resourceName: "icStep04Off")
                line3.backgroundColor = .gray230
            case 3:
                rightTitle = "Common.Complete".localized
                rightButton.isEnabled = true
                
                step3ImageView.image = #imageLiteral(resourceName: "icStepCheck")
                step4ImageView.image = #imageLiteral(resourceName: "icStep04On")
                step4Label.textColor = .mint1
                line3.backgroundColor = .mint1
                
            default: break
            }
            
            leftButton.setTitle(leftTitle, for: .normal)
            rightButton.setTitle(rightTitle, for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        step1Label.size11(text: "Create.Wallet.Step1.StepTitle".localized, color: .mint1, align: .center, lineBreakMode: .byWordWrapping)
        step2Label.size11(text: "Create.Wallet.Step2.StepTitle".localized, color: .gray128, align: .center, lineBreakMode: .byWordWrapping)
        step3Label.size11(text: "Create.Wallet.Step3.StepTitle".localized, color: .gray128, align: .center, lineBreakMode: .byWordWrapping)
        step4Label.size11(text: "Create.Wallet.Step4.StepTitle".localized, color: .gray128, align: .center, lineBreakMode: .byWordWrapping)
        
        scrollIndex = 0

        for vc in children {
            if let select = vc as? CreateSelectViewController {
                select.delegate = self
                self.selectVC = select

            } else if let keystore = vc as? CreateKeystoreViewController {
                keystore.delegate = self
                self.keystoreVC = keystore

            } else if let backup = vc as? CreateBackupViewController {
                backup.delegate = self
                self.backupVC = backup

            } else if let complete = vc as? CreateCompleteViewController {
                complete.delegate = self
                self.completeVC = complete
            } else if let qrCode = vc as? CreateQRCodeViewController {
                qrCode.delegate = self
                self.qrCodeVC = qrCode
            }
        }

        stepScrollView.rx.didEndScrollingAnimation.subscribe(onNext: { [unowned self] in
            self.scrollIndex = (Int)(self.stepScrollView.contentOffset.x / self.view.frame.width)
        }).disposed(by: disposeBag)

        leftButton.rx.tap.subscribe(onNext: { [unowned self] in
            self.backupVC.refresh()
            self.completeVC.refresh()
            
            switch self.scrollIndex {
            case 0:
                self.dismiss(animated: true, completion: nil)
                
            case 1:
                self.isICX = true
                self.selectVC.refresh()

            case 2:
                self.keystoreVC.refresh()
                self._isBackup = false
                self._newWallet = nil
                self._walletInfo = nil
                
            default:
                break
            }

            let value = (CGFloat)(self.scrollIndex - 1)
            let x = value * self.view.frame.width
            self.stepScrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
        }).disposed(by: disposeBag)

        rightButton.rx.tap.asControlEvent().subscribe(onNext: { [unowned self] in
            switch self.scrollIndex {
            case 1:
                guard let info = self.walletInfo else { return }
                if self._isICX {
                    do {
                        let wallet = try ICXWallet.new(name: info.name, password: info.password)
                        self._newWallet = wallet
                        self.scrollNext()
                    } catch let err {
                        Log(err, .error)
                    }

                } else {
                    do {
                        let wallet = try ETHWallet.new(name: info.name, password: info.password)
                        self._newWallet = wallet
                        self.scrollNext()
                    } catch let err {
                        Log(err, .error)
                    }
                }
            case 2 where !self._isBackup:
                Alert.basic(title: "Create.Wallet.Step3.Alert.NotSaved".localized, isOnlyOneButton: false, leftButtonTitle: "Common.No".localized, rightButtonTitle: "Common.Yes".localized, confirmAction: {
                    self.scrollNext()
                }).show()

            case 3:
                guard let new = self._newWallet else { return }

                do {
                    try new.save()
                    Manager.balance.getAllBalances()
                    self.dismiss(animated: true, completion: {
                        self.doneAction?()
                    })
                } catch let err {
                    Alert.basic(title: err.localizedDescription).show()
                }

            default: self.scrollNext()
            }
        }).disposed(by: disposeBag)
    }
    
    private func scrollNext() {
        if self.scrollIndex == 2 {
            self.completeVC.refresh()
        }
        let value = (CGFloat)(self.scrollIndex + 1)
        let x = value * self.view.frame.width
        self.stepScrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
    }
    
    override func refresh() {
        super.refresh()

        titleContainer.set(title: "Wallet.Create".localized)
        titleContainer.actionHandler = {
            switch self.scrollIndex {
            case 0: self.dismiss(animated: true, completion: nil)
            default:
                let cancelAlert = Alert.basic(title: "Create.Wallet.Cancel".localized, isOnlyOneButton: false, leftButtonTitle: "Common.No".localized, rightButtonTitle: "Common.Yes".localized)

                cancelAlert.confirmHandler = {
                    self.dismiss(animated: true, completion: nil)
                }

                cancelAlert.show()
            }

        }

        leftButton.round02()
        rightButton.lightMintRounded()
    }
}

struct WalletInfo {
    var name: String
    var password: String
}

extension CreateWalletViewController: createWalletSequence {
    var walletInfo: WalletInfo? {
        get {
            return self._walletInfo
        }
        set {
            self._walletInfo = newValue
        }
    }
    
    var isICX: Bool {
        get {
            return self._isICX
        } set {
            self._isICX = newValue
        }
    }
    
    var isBackup: Bool {
        get {
            return self._isBackup
        }
        set {
            self._isBackup = newValue
        }
    }
    
    func set(info: WalletInfo) {
        self._walletInfo = info
    }
    
    var newWallet: BaseWalletConvertible? {
        get {
            return self._newWallet
        }
    }
    
    func validated() {
        self.rightButton.isEnabled = true
    }
    
    func invalidated() {
        self.rightButton.isEnabled = false
    }
}
