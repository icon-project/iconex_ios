//
//  TransactionDetailViewController.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class TransactionDetailViewController: UIViewController {
    @IBOutlet weak var alertContainer: UIView!
    @IBOutlet weak var alertTitleLabel: UILabel!
    @IBOutlet weak var txHashLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var trackerButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    var txHash: String?
    
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
        alertContainer.corner(12)
        alertTitleLabel.text = "Alert.Transaction.ID".localized
        txHashLabel.text = txHash
        
        copyButton.styleDark()
        copyButton.cornered()
        copyButton.setTitle("Alert.Transaction.IDCopy".localized, for: .normal)
        trackerButton.styleLight()
        trackerButton.cornered()
        trackerButton.setTitle("Alert.Transaction.History".localized, for: .normal)
        closeButton.styleDark()
        closeButton.setTitle("Common.Close".localized, for: .normal)
        
        copyButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: {[unowned self] in
                copyString(message: self.txHash!)
                Tools.toast(message: "Alert.Transaction.IDCopied".localized)
            }).disposed(by: disposeBag)
        
        trackerButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: {
                guard let target = URL(string: ICON.V2.TRACKER_HOST)?.appendingPathComponent("transaction").appendingPathComponent(self.txHash!) else {
                    return
                }
                
                UIApplication.shared.open(target, options: [:], completionHandler: nil)
            }).disposed(by: disposeBag)
        
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: {[weak self] in
                self?.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }
}
