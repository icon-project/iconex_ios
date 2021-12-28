//
//  StepThreeViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit

class StepThreeViewController: UIViewController {

    @IBOutlet weak var topHeaderTitle: UILabel!
    @IBOutlet weak var firstDescription: UILabel!
    @IBOutlet weak var secondDescription: UILabel!
    @IBOutlet weak var walletDownloadHeader: UILabel!
    @IBOutlet weak var walletDownloadButton: UIButton!
    
    
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    var delegate: CreateStepDelegate?
    var isBackedup: Bool = false
    
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
        topHeaderTitle.text = Localized(key: "Create.Wallet.Step3.Header.1")
        firstDescription.text = Localized(key: "Create.Wallet.Step3.Desc.1_1")
        secondDescription.text = Localized(key: "Create.Wallet.Step3.Desc.1_2")
        walletDownloadHeader.text = Localized(key: "Create.Wallet.Step3.Header.2")
        walletDownloadButton.setTitle(Localized(key: "Create.Wallet.Step3.Download"), for: .normal)
        walletDownloadButton.styleDark()
        walletDownloadButton.cornered()
        
        prevButton.setTitle(Localized(key: "Common.Back"), for: .normal)
        prevButton.styleDark()
        prevButton.rounded()
        nextButton.setTitle(Localized(key: "Common.Next"), for: .normal)
        nextButton.styleLight()
        nextButton.rounded()
    }
    
    @IBAction func clickedDownload(_ sender: Any) {
        
        let confirmAction = Alert.Confirm(message: Localized(key: "Alert.DownloadKeystore"), cancel: Localized(key: "Common.Cancel"), confirm: Localized(key: "Common.Confirm"), handler: { [weak self] in
            
            do {
                guard let coinType = WCreator.newType else {
                    return
                }
                var filepath: URL = URL(fileURLWithPath: "")
                switch coinType {
                case .icx:
                    let wallet = WCreator.newWallet as! ICXWallet
                    filepath = try wallet.getBackupKeystoreFilepath()
                    
                case .eth:
                    let wallet = WCreator.newWallet as! ETHWallet
                    filepath = try wallet.getBackupKeystoreFilepath()
                    break
                    
                default:
                    break
                }
                
//                let activity = UIActivityViewController(activityItems: [filepath], applicationActivities: nil)
//                self?.present(activity, animated: true, completion: nil)
                let app = UIApplication.shared.delegate as! AppDelegate
                app.fileShare(filepath: filepath, self?.walletDownloadButton)
                
                self?.isBackedup = true
            } catch {
                self?.present(Alert.Basic(message: Localized(key: "Error.Wallet.Create")), animated: true, completion: nil)
                Log(error)
            }
        })
        
        present(confirmAction, animated: true, completion: nil)
    }
    
    @IBAction func clickedPrev(_ sender: Any) {
        guard let delegate = delegate else {
            return
        }
        
        delegate.prevStep(currentStep: .three)
    }
    
    @IBAction func clickedNext(_ sender: Any) {
        guard let delegate = delegate else {
            return
        }
        
        if isBackedup {
            
            delegate.nextStep(currentStep: .three)
        } else {
            let confirm = Alert.Confirm(message: Localized(key: "Alert.SkipDownload"), cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: {
                delegate.nextStep(currentStep: .three)
            })
            
            present(confirm, animated: true, completion: nil)
        }
    }
}
