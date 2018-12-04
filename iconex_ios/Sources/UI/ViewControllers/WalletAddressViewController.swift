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

    @IBOutlet weak var mainContainer: UIView!
    @IBOutlet weak var subContainer: UIView!
    @IBOutlet weak var walletNameLabel: UILabel!
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var walletAddressLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var snapshotView: UIView!
    @IBOutlet weak var snapImage: UIImageView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    var snap: UIImage?
    var startY: CGFloat = 264
    var minimumY: CGFloat = 56
    
    var closeHandler: (() -> Void)?
    
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
        
        mainContainer.layer.shadowOffset = CGSize(width: 0, height: 20)
        mainContainer.layer.shadowColor = UIColor(0, 38, 38).cgColor
        mainContainer.layer.shadowOpacity = 0.18
        mainContainer.layer.shadowRadius = 25 / 2
        subContainer.corner(5)
        snapshotView.corner(4)
        closeButton.isHidden = true
        
        copyButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            guard let address = self?.currentWallet.address else {
                return
            }
            copyString(message: address)
            Tools.toast(message: "Wallet.Address.CopyComplete".localized)
        }).disposed(by: disposeBag)
        
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.flipDown()
        }).disposed(by: disposeBag)
    }
}

extension WalletAddressViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        topConstraint.constant = startY == 0 ? 264 : minimumY
        setInfo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        flipUp()
    }
    
    func setInfo() {
        guard let address = self.currentWallet.address else { return }
        
        self.walletNameLabel.text = self.currentWallet.alias
        self.walletAddressLabel.text = address
        
        if let image = self.snap {
            snapImage.image = image
        }
        
        generateQRCode(address: address)
    }
    
    func generateQRCode(address: String) {
        guard let img = address.generateQRCode() else {
            return
        }
        
        qrImageView.image = scaleQRCode(origin: img)
    }
    
    func flipUp() {
        topConstraint.constant = minimumY
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
        }) { _ in
            self.closeButton.isHidden = false
        }
        
        mainContainer.layer.transform = AnimationHelper.yRotation(.pi / 2)
        mainContainer.alpha = 0.0
        
        UIView.animateKeyframes(withDuration: 0.25, delay: 0, options: .calculationModeCubic, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1/2, animations: {
                self.snapshotView.layer.transform = AnimationHelper.yRotation(-.pi / 2)
                self.snapshotView.alpha = 0.0
            })
            
            UIView.addKeyframe(withRelativeStartTime: 1/2, relativeDuration: 1/2, animations: {
                self.mainContainer.layer.transform = AnimationHelper.yRotation(0.0)
                self.mainContainer.alpha = 1.0
            })
        }) { _ in
            
        }
    }
    
    func flipDown() {
        self.closeButton.isHidden = true
        topConstraint.constant = startY == 0 ? 264 : minimumY
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
        }) { _ in
        }
        UIView.animateKeyframes(withDuration: 0.25, delay: 0, options: .calculationModeCubic, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1/2, animations: {
                self.mainContainer.layer.transform = AnimationHelper.yRotation(.pi / 2)
                self.mainContainer.alpha = 0.0
            })
            
            UIView.addKeyframe(withRelativeStartTime: 1/2, relativeDuration: 1/2, animations: {
                self.snapshotView.layer.transform = AnimationHelper.yRotation(0.0)
                self.snapshotView.alpha = 1.0
            })
        }) { _ in
            if let close = self.closeHandler {
                close()
            }
            self.dismiss(animated: false, completion: {
                
            })
        }
    }
    
}
