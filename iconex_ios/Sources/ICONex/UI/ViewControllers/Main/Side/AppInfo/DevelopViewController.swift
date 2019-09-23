//
//  DevelopViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 01/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ICONKit

class DevelopViewController: BaseViewController {
    @IBOutlet weak var navBar: IXNavigationView!
    @IBOutlet weak var developerModeLabel: UILabel!
    @IBOutlet weak var developSwitch: UISwitch!
    @IBOutlet weak var selectContainer: UIView!
    @IBOutlet weak var selectNetworkLabel: UILabel!
    @IBOutlet weak var networkNameLabel: UILabel!
    @IBOutlet weak var selectButton: UIButton!
    
    private var developer: Bool = false {
        willSet {
            selectContainer.isHidden = !newValue
            UserDefaults.standard.set(newValue, forKey: "Developer")
            if !newValue {
                UserDefaults.standard.removeObject(forKey: "Provider")
            } else {
                refresh()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        navBar.setTitle("AppInfo.DeveloperMode".localized)
        navBar.setLeft {
            self.navigationController?.popViewController(animated: true)
        }
        developerModeLabel.size14(text: "AppInfo.DeveloperMode".localized, color: .gray77)
        selectNetworkLabel.size12(text: "AppInfo.SelectNetwork".localized, color: .gray77)
        
        developer = UserDefaults.standard.bool(forKey: "Developer")
        developSwitch.isOn = developer
        
        selectButton.rx.tap.subscribe(onNext: {
            let picker = UIStoryboard(name: "Picker", bundle: nil).instantiateInitialViewController() as! IXPickerViewController
            picker.headerTitle = "Connect.Send.Developer.Title".localized
            picker.items = ["Mainnet", "Euljiro", "Yeouido"]
            picker.selectedAction = { index in
                UserDefaults.standard.set(index, forKey: "Provider")
                self.refresh()
                Manager.balance.getAllBalances()
            }
            picker.pop()
        }).disposed(by: disposeBag)
        
        developSwitch.rx.controlEvent(.valueChanged)
            .subscribe(onNext: {
                self.developer = self.developSwitch.isOn
            }).disposed(by: disposeBag)
       
    }
    
    override func refresh() {
        super.refresh()
        let save = UserDefaults.standard.integer(forKey: "Provider")
        
        if let provider = Configuration.HOST(rawValue: save) {
            networkNameLabel.size16(text: provider.name, color: .gray77)
        } else {
            networkNameLabel.size16(text: Configuration.HOST.main.name, color: .gray77)
        }
    }
}
