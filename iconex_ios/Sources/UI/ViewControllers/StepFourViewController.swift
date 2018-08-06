//
//  StepFourViewController.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class StepFourViewController: UIViewController {
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var firstDesc: UILabel!
    @IBOutlet weak var secondDesc: UILabel!
    @IBOutlet weak var headerPrivateKey: UILabel!
    @IBOutlet weak var privateContainer: UIView!
    @IBOutlet weak var privateKeyLabel: UILabel!
    @IBOutlet weak var eyeOnButton: UIButton!
    @IBOutlet weak var prvCopyButton: UIButton!
    @IBOutlet weak var walletInfoButton: UIButton!
    
    @IBOutlet weak var doneButton: UIButton!
    
    var newPrivateKey: String? {
        didSet {
            isHidePrivateKey = true
        }
    }
    
    private var isHidePrivateKey: Bool = true {
        willSet {
            guard let prv = newPrivateKey else {
                return
            }
            
            eyeOnButton.isSelected = newValue
            
            if newValue {
                privateKeyLabel.text = String(repeating: "●", count: prv.length)
            } else {
                privateKeyLabel.text = prv
            }
        }
    }
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initializeUI() {
        headerLabel.text = Localized(key: "Create.Wallet.Step4.Header.1")
        firstDesc.text = Localized(key: "Create.Wallet.Step4.Desc.1_1")
        secondDesc.text = Localized(key: "Create.Wallet.Step4.Desc.1_2")
        headerPrivateKey.text = Localized(key: "Wallet.PrivateKey")
        
        prvCopyButton.setTitle(Localized(key: "Wallet.PrivateKey.Copy"), for: .normal)
        prvCopyButton.styleDark()
        prvCopyButton.cornered()
        
        walletInfoButton.setTitle(Localized(key: "Wallet.ViewInfo"), for: .normal)
        walletInfoButton.styleDark()
        walletInfoButton.cornered()
        
        doneButton.setTitle(Localized(key: "Common.Complete"), for: .normal)
        doneButton.styleDark()
        doneButton.rounded()
        
        privateContainer.backgroundColor = UIColor(237, 237, 237)
        privateContainer.corner(4)
        
        walletInfoButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                let info = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "WalletPrivateInfo") as! WalletPrivateInfoViewController
                info.wallet = WCreator.newWallet
                info.privKey = self.newPrivateKey
                self.present(info, animated: true, completion: nil)
            }).disposed(by: disposeBag)
        
        prvCopyButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let prv = self.newPrivateKey else {
                    return
                }
                copyString(message: prv)
                Tools.toast(message: "Wallet.PrivateKey.Copy.Message".localized)
            }).disposed(by: disposeBag)
    }
    
    @IBAction func clickedShowHide(_ sender: Any) {
        isHidePrivateKey = !isHidePrivateKey
    }
    
    @IBAction func clickedDone(_ sender: Any) {
        trySaveWallet()
        WCreator.resetData()
        WManager.loadWalletList()
        if let nav = self.navigationController {
            let main = nav.viewControllers[0] as! MainViewController
            main.loadWallets()
            nav.popToRootViewController(animated: true)
        } else {
            self.dismiss(animated: false, completion: {
                let app = UIApplication.shared.delegate as! AppDelegate
                let main = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                app.window?.rootViewController = main
            })
        }
    }
    
    func trySaveWallet() {
        if WCreator.newType! == .icx {
            if let newWallet = WCreator.newWallet as? ICXWallet {
                try! newWallet.saveICXWallet()
            }
        } else if WCreator.newType! == .eth {
            if let newWallet = WCreator.newWallet as? ETHWallet {
                try! newWallet.saveETHWallet()
            }
        }
    }
}
