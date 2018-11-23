//
//  DeveloperViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift

class DeveloperViewController: BaseViewController {
    @IBOutlet weak var back: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var developer: UILabel!
    @IBOutlet weak var modeSwitch: UISwitch!
    @IBOutlet weak var networkName: UILabel!
    @IBOutlet weak var chooseNetwork: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
        
        refresh()
    }
    
    func initialize() {
        back.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: {
            self.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
        
        modeSwitch.rx.controlEvent(UIControlEvents.valueChanged).subscribe(onNext: {
            if self.modeSwitch.isOn {
                UserDefaults.standard.set(true, forKey: "Developer")
            } else {
                UserDefaults.standard.removeObject(forKey: "Developer")
                UserDefaults.standard.removeObject(forKey: "Provider")
            }
            UserDefaults.standard.synchronize()
            
            self.refresh()
        }).disposed(by: disposeBag)
        
        chooseNetwork.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: {
            Alert.NetworkProvider(source: self, completion: {
                self.refresh()
            })
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        navTitle.text = "AppInfo.DeveloperMode".localized
        developer.text = "AppInfo.DeveloperMode".localized
    }
    
    func refresh() {
        let saved = UserDefaults.standard.integer(forKey: "Provider")
        if let provider = Configuration.HOST(rawValue: saved) {
            networkName.text = provider.name
        } else {
            networkName.text = Configuration.HOST.main.name
        }
    }
}
