//
//  SwapStepFourViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit

class SwapStepFourViewController: BaseViewController {
    @IBOutlet var headerLabel1: UILabel!
    @IBOutlet var descLabel1: UILabel!
    @IBOutlet var descLabel2: UILabel!
    @IBOutlet var headerLabel2: UILabel!
    @IBOutlet var privateLabel: UILabel!
    @IBOutlet var eyeButton: UIButton!
    @IBOutlet var copyButton: UIButton!
    @IBOutlet var infoButton: UIButton!
    @IBOutlet var prevButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    
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
            
            eyeButton.isSelected = newValue
            
            if newValue {
                privateLabel.text = String(repeating: "●", count: prv.length)
            } else {
                privateLabel.text = prv
            }
        }
    }
    
    var delegate: SwapStepDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeUI()
        initialize()
    }
    
    func initializeUI() {
        isHidePrivateKey = true
        headerLabel1.text = "Swap.Step4.Header1".localized
        descLabel1.text = "Swap.Step4.Desc1".localized
        descLabel2.text = "Swap.Step4.Desc2".localized
        headerLabel2.text = "Swap.Step4.Header2".localized
        copyButton.styleDark()
        copyButton.cornered()
        copyButton.setTitle("Swap.Step4.CopyPrivateKey".localized, for: .normal)
        infoButton.styleDark()
        infoButton.cornered()
        infoButton.setTitle("Swap.Step4.WalletInfo".localized, for: .normal)
        prevButton.styleDark()
        prevButton.rounded()
        prevButton.setTitle("Common.Back".localized, for: .normal)
        nextButton.styleLight()
        nextButton.rounded()
        nextButton.setTitle("Common.Next".localized, for: .normal)
    }

    func initialize() {
        copyButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            guard let prv = self.newPrivateKey else {
                return
            }
            copyString(message: prv)
            Tools.toast(message: "Wallet.PrivateKey.Copy.Message".localized)
        }).disposed(by: disposeBag)
        
        infoButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            let info = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "WalletPrivateInfo") as! WalletPrivateInfoViewController
            let wallet = WManager.loadWalletBy(info: WalletInfo(name: WCreator.newWallet!.alias!, address: WCreator.newWallet!.address!, type: WCreator.newWallet!.type))
            info.wallet = wallet
            info.privKey = self.newPrivateKey
            self.present(info, animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        prevButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            guard let delegate = self.delegate else { return }
            delegate.changeStep(to: SwapStepView.SwapStep.step3)
        }).disposed(by: disposeBag)
        
        nextButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            guard let delegate = self.delegate else { return }
            delegate.changeStep(to: SwapStepView.SwapStep.step5)
        }).disposed(by: disposeBag)
        
        eyeButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.eyeButton.isSelected = !self.eyeButton.isSelected
            self.isHidePrivateKey = self.eyeButton.isSelected
        }).disposed(by: disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
