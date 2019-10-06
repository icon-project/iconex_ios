//
//  BioAuthViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 06/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import LocalAuthentication

class BioAuthViewController: BaseViewController {

    @IBOutlet weak var navBar: IXNavigationView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bioImageView: UIImageView!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var useButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarBack")) {
            self.navigationController?.popViewController(animated: true)
        }
        
        useButton.gray77round()
        
        let bioType = LAContext().biometricType
        
        switch bioType.type {
        case .touchID:
            navBar.setTitle("LockSetting.TouchID.NavBar.Title".localized)
            titleLabel.size18(text: "LockSetting.TouchID.Title".localized, color: .mint1, align: .center)
            subtitleLabel.size14(text: "LockSetting.TouchID.SubTitle".localized, color: .gray128, weight: .light, align: .center)
            descLabel.size12(text: "LockSetting.TouchID.Description".localized, color: .gray128, weight: .light, align: .center)
            useButton.setTitle("LockSetting.TouchID.Button".localized, for: .normal)
            
        case .faceID:
            navBar.setTitle("LockSetting.FaceID.NavBar.Title".localized)
            titleLabel.size18(text: "LockSetting.FaceID.Title".localized, color: .mint1, align: .center)
            subtitleLabel.size14(text: "LockSetting.FaceID.SubTitle".localized, color: .gray128, weight: .light, align: .center)
            descLabel.isHidden = true
            useButton.setTitle("LockSetting.FaceID.Button".localized, for: .normal)
            
        default:
            break
        }
        
        useButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                Tool.bioVerification(message: "", completion: { (state) in
                    switch state {
                    case .success:
                        UserDefaults.standard.set(true, forKey: "useBio")
                        UserDefaults.standard.synchronize()
                        self.navigationController?.popViewController(animated: true)
                        
                    case .locked:
                        Alert.basic(title: bioType.type == .faceID ? "LockSetting.FaceID.Locked".localized : "LockSetting.TouchID.Locked".localized, leftButtonTitle: "Common.Confirm".localized, confirmAction: nil).show()
                        
                    default:
                        break
                    }
                })
            }.disposed(by: disposeBag)
    }
}
