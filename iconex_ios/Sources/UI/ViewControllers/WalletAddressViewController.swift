//
//  WalletAddressViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class WalletAddressViewController: UIViewController {

    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var mainConatiner: UIView!
    @IBOutlet weak var walletNameLabel: UILabel!
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var walletAddressLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var snapshotView: UIView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    let disposeBag = DisposeBag()
    
    var currentWallet: BaseWalletConvertible!
    
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
        copyButton.styleDark()
        copyButton.corner(4)
        copyButton.setTitle("Wallet.Address.Copy".localized, for: .normal)
        mainConatiner.corner(4)
        shadowView.backgroundColor = UIColor.clear
        shadowView.layer.shadowColor = UIColor(0, 38, 38).cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 20)
        shadowView.layer.shadowOpacity = 0.18
        shadowView.layer.shadowRadius = 25 / 2
        snapshotView.isHidden = true
//        mainConatiner.isHidden = true
//        closeButton.isHidden = true
        
        copyButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            guard let address = self?.currentWallet.address else {
                return
            }
            copyString(message: address)
            Tools.toast(message: "Wallet.Address.CopyComplete".localized)
        }).disposed(by: disposeBag)
        
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.dismiss(animated: true, completion: {
                
            })
        }).disposed(by: disposeBag)
    }
}

extension WalletAddressViewController {
    
//    func present(from: UIViewController, wallet: WalletBaseConvertible, snapshotView: UIView, handler: @escaping () -> Void) {
//        
//        from.present(self, animated: false, completion: {
//            self.addSnapshot(snapshot: snapshotView)
//            self.currentWallet = wallet
//            self.setInfo()
//            self.flipUp(handler: handler)
//        })
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        topConstraint.constant = 62
        setInfo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        topConstraint.constant = 16
//        UIView.animate(withDuration: 0.25) {
//            self.view.layoutIfNeeded()
//        }
    }
    
    func setInfo() {
        guard let address = self.currentWallet.address else { return }
        
        self.walletNameLabel.text = self.currentWallet.alias
        self.walletAddressLabel.text = address
        
        generateQRCode(address: address)
    }
    
    func generateQRCode(address: String) {
        guard let img = address.generateQRCode() else {
            return
        }
        
        qrImageView.image = scaleQRCode(origin: img)
    }
    
    func addSnapshot(snapshot: UIView) {
        self.snapshotView.addSubview(snapshot)
    }
    
//    func flipUp(handler: @escaping () -> Void) {
//        UIView.transition(from: snapshotView, to: mainConatiner, duration: 4, options: .transitionFlipFromRight, completion: { completed in
//            self.view.bringSubview(toFront: self.closeButton)
//            self.closeButton.isHidden = false
//            handler()
//        })
//    }
}
