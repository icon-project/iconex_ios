//
//  BioAuthViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class BioAuthViewController: UIViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var descLabel1: UILabel!
    @IBOutlet weak var useButton: UIButton!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }

    func initialize() {
        closeButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                self.navigationController?.popViewController(animated: true)
            }).disposed(by: disposeBag)
        
        useButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                Tools.touchIDVerification(message: "", completion: { (state) in
                    switch state {
                    case .success:
                        UserDefaults.standard.set(true, forKey: "useBio")
                        UserDefaults.standard.synchronize()
                        self.navigationController?.popViewController(animated: true)
                        
                    case .locked:
                        Alert.Basic(message: UIDevice.current.type == .iPhoneX ? "Error.FaceID.Locked".localized : "Error.TouchID.Locked".localized).show(self)
                        
                    default:
                        break
                    }
                })
            }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        
        useButton.styleDark()
        useButton.rounded()
        
        switch Tools.biometryType() {
        case "Touch ID":
            navTitle.text = "LockScreen.Setting.Bio.Title.TouchID".localized
            headerLabel.text = "LockScreen.Setting.Bio.Header.TouchID".localized
            descLabel1.text = "LockScreen.Setting.Bio.Desc.TouchID".localized
            useButton.setTitle("LockScreen.Setting.Bio.Use.TouchID".localized, for: .normal)
            mainImage.image = #imageLiteral(resourceName: "imgFingerScan")
            
        case "Face ID":
            navTitle.text = "LockScreen.Setting.Bio.Title.FaceID".localized
            headerLabel.text = "LockScreen.Setting.Bio.Header.FaceID".localized
            descLabel1.text = "LockScreen.Setting.Bio.Desc.FaceID".localized
            useButton.setTitle("LockScreen.Setting.Bio.Use.FaceID".localized, for: .normal)
            mainImage.image = #imageLiteral(resourceName: "imgFaceId")
         
        default:
            navTitle.text = "LockScreen.Setting.Bio.Title.TouchID".localized
            headerLabel.text = "LockScreen.Setting.Bio.Header.TouchID".localized
            descLabel1.text = "LockScreen.Setting.Bio.Desc.TouchID".localized
            useButton.setTitle("LockScreen.Setting.Bio.Use.TouchID".localized, for: .normal)
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
