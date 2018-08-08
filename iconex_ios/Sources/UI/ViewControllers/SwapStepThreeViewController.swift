//
//  SwapStepThreeViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit

class SwapStepThreeViewController: BaseViewController {
    @IBOutlet var headerLabel1: UILabel!
    @IBOutlet var descLabel1: UILabel!
    @IBOutlet var descLabel2: UILabel!
    @IBOutlet var headerLabel2: UILabel!
    @IBOutlet var downloadButton: UIButton!
    @IBOutlet var prevButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    
    var delegate: SwapStepDelegate?
    var token: TokenInfo?
    var isBackedup: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }
    
    func initialize() {
        downloadButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            let confirmAction = Alert.Confirm(message: Localized(key: "Alert.DownloadKeystore"), cancel: Localized(key: "Common.Cancel"), confirm: Localized(key: "Common.Confirm"), handler: {
                
                do {
                    guard let coinType = WCreator.newType else {
                        return
                    }
                    var filepath: URL = URL(fileURLWithPath: "")
                    switch coinType {
                    case .icx:
                        let wallet = WCreator.newWallet as! ICXWallet
                        filepath = try wallet.getBackupKeystoreFilepath()
                        
                    default:
                        break
                    }
                    
//                    let activity = UIActivityViewController(activityItems: [filepath], applicationActivities: nil)
//                    self.present(activity, animated: true, completion: nil)
                    let app = UIApplication.shared.delegate as! AppDelegate
                    app.fileShare(filepath: filepath, self.downloadButton)
                    
                    self.isBackedup = true
                } catch {
                    self.present(Alert.Basic(message: Localized(key: "Error.Wallet.Create")), animated: true, completion: nil)
                    Log.Debug(error)
                }
            })
            
            self.present(confirmAction, animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        prevButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            guard let delegate = self.delegate else { return }
            delegate.changeStep(to: SwapStepView.SwapStep.step2)
        }).disposed(by: disposeBag)
        
        nextButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            if let newWallet = WCreator.newWallet as? ICXWallet {
                
                do {
                    if let token = self.token {
                        token.swapAddress = newWallet.address
                        try Ethereum.modifyToken(tokenInfo: token)
                    }
                    
                    try newWallet.saveICXWallet()
                    
                } catch {
                    Log.Debug("\(error)")
                }
                
                WManager.loadWalletList()
                let app = UIApplication.shared.delegate as! AppDelegate
                if let root = app.window?.rootViewController as? UINavigationController, let main = root.viewControllers[0] as? MainViewController {
                    main.loadWallets()
                }
                
            }
            if self.isBackedup {
                guard let delegate = self.delegate else { return }
                delegate.changeStep(to: SwapStepView.SwapStep.step4)
            } else {
                Alert.Confirm(message: Localized(key: "Alert.SkipDownload"), cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: { [unowned self] in
                    guard let delegate = self.delegate else { return }
                    delegate.changeStep(to: SwapStepView.SwapStep.step4)
                }).show(self)
            }
        }).disposed(by: disposeBag)
        
        guard let walletInfo = SwapManager.sharedInstance.walletInfo, let eth = WManager.loadWalletBy(info: walletInfo) as? ETHWallet, let tokens = eth.tokens, let token = tokens.filter({ $0.symbol.lowercased() == "icx" }).first else { return }
        self.token = token
    }
    
    func initializeUI () {
        headerLabel1.text = "Swap.Step3.Header1".localized
        descLabel1.text = "Swap.Step3.Desc1".localized
        descLabel2.text = "Swap.Step3.Desc2".localized
        headerLabel2.text = "Swap.Step3.Header2".localized
        downloadButton.styleDark()
        downloadButton.cornered()
        downloadButton.setTitle("Swap.Step3.BackupDownload".localized, for: .normal)
        prevButton.styleDark()
        prevButton.rounded()
        prevButton.setTitle("Common.Back".localized, for: .normal)
        nextButton.styleLight()
        nextButton.rounded()
        nextButton.setTitle("Common.Next".localized, for: .normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
