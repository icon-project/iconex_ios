//
//  AppInfoViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 01/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AppInfoViewController: BaseViewController {
    @IBOutlet weak var navBar: IXNavigationView!
    
    @IBOutlet weak var currentVersionLabel: UILabel!
    @IBOutlet weak var latestVersionLabel: UILabel!
    @IBOutlet weak var updateContainer: UIView!
    @IBOutlet weak var updateButton: UIButton!
    
    @IBOutlet weak var opensourceLabel: UILabel!
    @IBOutlet weak var developerLabel: UILabel!
    @IBOutlet weak var opensourceButton: UIButton!
    @IBOutlet weak var developerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        navBar.setTitle("AppInfo.Version".localized)
        navBar.setLeft {
            self.navigationController?.popViewController(animated: true)
        }
        
        if app.all! > app.appVersion {
            currentVersionLabel.size14(text: "AppInfo.Current".localized + " \(app.appVersion)", color: .gray77, weight: .light, align: .center)
            latestVersionLabel.size20(text: "AppInfo.Latest".localized + " \(app.all!)", color: .mint1, weight: .light, align: .center)
            updateContainer.isHidden = false
        } else {
            currentVersionLabel.size20(text: "AppInfo.Current".localized + " \(app.appVersion)", color: .mint1, weight: .light, align: .center)
            latestVersionLabel.size14(text: "AppInfo.Latest".localized + " \(app.appVersion)", color: .gray77, weight: .light, align: .center)
            updateContainer.isHidden = true
        }
        
        opensourceLabel.size14(text: "AppInfo.License".localized, color: .gray77, weight: .regular, align: .left)
        developerLabel.size14(text: "AppInfo.DeveloperMode".localized, color: .gray77, weight: .regular, align: .left)
        
        developerButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                let develop = UIStoryboard(name: "AppInfo", bundle: nil).instantiateViewController(withIdentifier: "DevelopView")
                self.navigationController?.pushViewController(develop, animated: true)
            }).disposed(by: disposeBag)
    }
}
