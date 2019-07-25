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
    @IBOutlet weak var permissionTitle: UILabel!
    @IBOutlet weak var requiredTitle: UILabel!
    @IBOutlet weak var requiredDesc: UILabel!
    @IBOutlet weak var optionalTitle: UILabel!
    @IBOutlet weak var optionalCameraTitle: UILabel!
    @IBOutlet weak var optionalCameraDesc: UILabel!
    @IBOutlet weak var footerDesc1: UILabel!
    @IBOutlet weak var footerDesc2: UILabel!
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
        permissionTitle.text = "Permission.Title".localized
        requiredTitle.text = "Permission.Required.Title".localized
        requiredDesc.text = "Permission.None".localized
        optionalTitle.text = "Permission.Optional.Title".localized
        optionalCameraTitle.text = "Permission.Camera.Title".localized
        optionalCameraDesc.text = "Permission.Camera.Desc".localized
        footerDesc1.text = "Permission.footer.desc1".localized
        footerDesc2.text = "Permission.footer.desc2".localized
        confirmButton.setTitle("Common.Confirm".localized, for: .normal)
        confirmButton.styleDark()
        confirmButton.rounded()
    }
}
