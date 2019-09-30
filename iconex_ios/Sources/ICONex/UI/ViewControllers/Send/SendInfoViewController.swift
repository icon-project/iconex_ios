//
//  SendInfoViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 30/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SendInfoViewController: PopableViewController {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var closeButton: UIButton!
    
    var type: String = "icx"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        titleContainer.actionHandler = {
            self.dismiss(animated: true, completion: nil)
        }
        titleContainer.set(title: "Send.Info.Title".localized)
        
        textView.text = type == "icx" ? "Send.Info.ICX".localized : "Send.Info.ETH".localized
        
        closeButton.gray77round()
        closeButton.setTitle("Common.Close".localized, for: .normal)
        
        closeButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
    }
}
