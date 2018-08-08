//
//  RetryViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit

class RetryViewController: BaseViewController {

    @IBOutlet weak var noLabel: UILabel!
    @IBOutlet weak var retryLabel: UILabel!
    @IBOutlet weak var retry: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func initialize() {
        noLabel.text = "Retry.NoNetwork".localized
        retryLabel.text = "Retry.CheckConnectivity".localized
        retry.styleDark()
        retry.cornered()
        retry.setTitle("Retry.Retry".localized, for: .normal)
        retry.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: {
            let app = UIApplication.shared.delegate as! AppDelegate
            app.checkVersion()
        }).disposed(by: disposeBag)
    }
}
