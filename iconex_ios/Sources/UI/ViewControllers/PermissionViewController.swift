//
//  PermissionViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 04/01/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift

class PermissionViewController: BaseViewController {
    @IBOutlet weak var confirmButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }
    
    func initialize() {
        confirmButton.rx.controlEvent(.touchUpInside).subscribe(onNext: {
            UserDefaults.standard.set(true, forKey: "confirmPermissions")
            UserDefaults.standard.synchronize()
            
            self.dismiss(animated: true, completion: {
                let app = UIApplication.shared.delegate as! AppDelegate
                app.checkVersion()
            })
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        confirmButton.setTitle("Common.Confirm".localized, for: .normal)
        confirmButton.styleDark()
        confirmButton.rounded()
    }
}
