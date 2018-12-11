//
//  TransactionDetailViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
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
        
        copyButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: {[unowned self] in
                copyString(message: self.txHash!)
                Tools.toast(message: "Alert.Transaction.IDCopied".localized)
            }).disposed(by: disposeBag)
        
        trackerButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: {
                var tracker: Tracker {
                    switch Config.host {
                    case .main:
                        return Tracker.main()
                        
                    case .dev:
                        return Tracker.dev()
                        
                    case .yeouido:
                        return Tracker.local()
                    }
                }
                
                guard let target = URL(string: tracker.provider)?.appendingPathComponent("transaction").appendingPathComponent(self.txHash!) else { return }
                UIApplication.shared.open(target, options: [:], completionHandler: nil)
                
            }).disposed(by: disposeBag)
        
        closeButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: {[weak self] in
                self?.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }
}
