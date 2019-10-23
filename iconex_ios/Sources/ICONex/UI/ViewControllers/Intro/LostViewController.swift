//
//  LostViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 23/10/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class LostViewController: BaseViewController {
    @IBOutlet weak var lostTitle: UILabel!
    @IBOutlet weak var lostDesc: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    
    var retryHandler: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        lostTitle.size14(text: "Retry.NoNetwork".localized, color: .gray77, weight: .semibold, align: .center, lineBreakMode: .byWordWrapping)
        lostDesc.size12(text: "Retry.CheckConnectivity".localized, color: .gray179, weight: .light, align: .center, lineBreakMode: .byWordWrapping)
        retryButton.line01()
        retryButton.setTitle("Retry.Retry".localized, for: .normal)
        retryButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.retryHandler?()
            }).disposed(by: disposeBag)
    }
}
