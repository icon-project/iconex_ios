//
//  WalletPrivateInfoViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class WalletPrivateInfoViewController: UIViewController {
    @IBOutlet weak var topTitle: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var qrAddressImage: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var addressCopy: UIButton!
    
    @IBOutlet weak var keyTitle: UILabel!
    @IBOutlet weak var qrKeyImage: UIImageView!
    @IBOutlet weak var keyLabel: UILabel!
    @IBOutlet weak var keyCopy: UIButton!
    
    var wallet: BaseWalletConvertible!
    var privKey: String?
    private var isShowed = false
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func initialize() {
        topTitle.text = wallet.alias
        mainLabel.text = "Wallet.Address".localized
        keyTitle.text = "Wallet.PrivateKey".localized
        
        addressCopy.styleDark()
        addressCopy.cornered()
        addressCopy.setTitle("Wallet.Address.Copy".localized, for: .normal)
        
        keyCopy.styleDark()
        keyCopy.cornered()
        keyCopy.setTitle("Wallet.PrivateKey.Copy".localized, for: .normal)
        
        qrAddressImage.image = generateQRCode(value: wallet.address!)
        addressLabel.text = wallet.address!
        
        if let createdDate = wallet.createdDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            dateLabel.text = formatter.string(from: createdDate)
        } else {
            dateLabel.text = ""
        }
        
        if wallet.type == .icx {
            typeLabel.text = "ICON(ICX)"
        } else if wallet.type == .eth {
            typeLabel.text = "Ethereum(ETH)"
        }
        
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                self.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
        
        addressCopy.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                copyString(message: self.wallet.address!)
                Tools.toast(message: "Wallet.Address.CopyComplete".localized)
            }).disposed(by: disposeBag)
        
        keyCopy.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                copyString(message: self.privKey!)
                Tools.toast(message: "Wallet.PrivateKey.Copy.Message".localized)
            }).disposed(by: disposeBag)
        
        scrollView.rx.didEndDecelerating.observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] _ in
            if !self.isShowed && self.scrollView.contentOffset.x == self.scrollView.frame.width {
                Alert.Basic(message: "Alert.PrivateKey".localized).show(self)
                self.isShowed = true
            }
        }).disposed(by: disposeBag)
        
        guard let privKey = self.privKey else {
            scrollView.isScrollEnabled = false
            pageControl.isHidden = true
            return
        }
        
        qrKeyImage.image = generateQRCode(value: privKey)
        keyLabel.text = privKey
        
        scrollView.rx.didEndDecelerating.map({ _ in
            return Int(self.scrollView.contentOffset.x / self.view.frame.width)
        }).bind(to: pageControl.rx.currentPage).disposed(by: disposeBag)
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func generateQRCode(value: String) -> UIImage? {
        guard let qrImage = value.generateQRCode() else {
            return nil
        }
        
        return scaleQRCode(origin: qrImage)
    }
}
