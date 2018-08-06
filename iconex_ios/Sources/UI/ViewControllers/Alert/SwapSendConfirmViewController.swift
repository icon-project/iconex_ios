//
//  SwapSendConfirmViewController.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit
import BigInt

class SwapSendConfirmViewController: BaseViewController {
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var swapTitle: UILabel!
    @IBOutlet weak var swapAmount: UILabel!
    @IBOutlet weak var feeTitle: UILabel!
    @IBOutlet weak var feeAmount: UILabel!
    @IBOutlet weak var receivingTitle: UILabel!
    @IBOutlet weak var receivingLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    var swapValue: String?
    var feeValue: String?
    var _gasPrice: BigUInt?
    var _gasLimit: BigUInt?
    var handler: (() -> Void)?
    
    private var burnAddress = "0x0000000000000000000000000000000000000000"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
    }
    
    func initialize() {
        alertView.corner(12)
        titleLabel.text = "Alert.Swap.AlertTitle".localized
        swapTitle.text = "Alert.Swap.Header1".localized + " (ICX)"
        swapAmount.text = swapValue!
        feeTitle.text = "Alert.Swap.Header2".localized + " (ETH)"
        feeAmount.text = feeValue!
        receivingTitle.text = "Alert.Transfer.Address".localized
        
        cancelButton.styleDark()
        cancelButton.setTitle("Common.Cancel".localized, for: .normal)
        confirmButton.styleLight()
        confirmButton.setTitle("Alert.Swap.RequestSwap".localized, for: .normal)
        
        let wallet = WManager.loadWalletBy(info: SwapManager.sharedInstance.walletInfo!) as! ETHWallet
        let token = wallet.tokens!.filter { $0.symbol.lowercased() == "icx" }.first!
        let walletInfo = WManager.walletInfoList.filter({ $0.address == token.swapAddress! }).first!
        let recvWallet = WManager.loadWalletBy(info: walletInfo)!
        
        let name = NSAttributedString(string: recvWallet.alias! + "\n", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .regular), .foregroundColor: UIColor.lightTheme.background.normal])
        let address = NSAttributedString(string: recvWallet.address!, attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.lightTheme.background.normal])
        let attr = NSMutableAttributedString(attributedString: name)
        attr.append(address)
        receivingLabel.text = ""
        receivingLabel.attributedText = attr
        
        cancelButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        confirmButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.sendToken()
        }).disposed(by: disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sendToken() {
        guard let gasPrice = _gasPrice, let gasLimit = _gasLimit, let swapString = swapValue, let icxValue = Tools.stringToBigUInt(inputText: swapString) else {
            return
        }
        confirmButton.isEnabled = false
        confirmButton.setTitle("", for: .normal)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: confirmButton.frame.width / 2 - 20, y: confirmButton.frame.height / 2 - 20), size: CGSize(width: 40, height: 40)))
        imageView.image = #imageLiteral(resourceName: "icRefresh01")
        imageView.tag = 999
        confirmButton.addSubview(imageView)
        Tools.rotateAnimation(inView: imageView)
        
        let wallet = WManager.loadWalletBy(info: SwapManager.sharedInstance.walletInfo!) as! ETHWallet
        let token = wallet.tokens!.filter { $0.symbol.lowercased() == "icx" }.first!
        Ethereum.requestTokenSendTransaction(privateKey: SwapManager.sharedInstance.privateKey!, from: wallet.address!, to: burnAddress, tokenInfo: token, limit: gasLimit, price: gasPrice, value: icxValue) { (isSuccess) in
            if isSuccess {
                
                self.dismiss(animated: true, completion: {
                    if let handler = self.handler {
                        handler()
                    }
                })
                
                
            } else {
                if let image = self.confirmButton.viewWithTag(999) {
                    image.removeFromSuperview()
                }
                self.confirmButton.setTitle("Alert.Swap.RequestSwap".localized, for: .normal)
                self.confirmButton.isEnabled = true
                Alert.Basic(message: "Error.CommonError".localized).show(self)
            }
        }
    }
    
}
