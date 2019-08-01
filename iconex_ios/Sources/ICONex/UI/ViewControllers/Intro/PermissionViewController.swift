//
//  PermissionViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 30/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import PanModal
import RxCocoa
import RxSwift

class PermissionViewController: PopableViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var headerLabel1: UILabel!
    @IBOutlet weak var contentLabel1: UILabel!
    @IBOutlet weak var headerLabel2: UILabel!
    @IBOutlet weak var contentLabel2: UILabel!
    @IBOutlet weak var subLabel1: UILabel!
    @IBOutlet weak var bottomContainer: UIView!
    @IBOutlet weak var bottomLabel1: UILabel!
    @IBOutlet weak var bottomLabel2: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    
    var action: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func initializeComponents() {
        super.initializeComponents()
        
        confirmButton.rx.tap.subscribe(onNext: { [unowned self] in
            UserDefaults.standard.set(true, forKey: "permission")
            self.dismiss(animated: true, completion: {
                if let comp = self.action {
                    comp()
                }
            })
        }).disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        titleLabel.size18(text: "Permission.Title".localized, color: .gray77, weight: .medium, align: .center)
        headerLabel1.size16(text: "Permission.Required.Title".localized, color: .gray77, weight: .semibold)
        contentLabel1.size14(text: "Permission.None".localized, color: .gray77)
        headerLabel2.size16(text: "Permission.Optional.Title".localized, color: .gray77, weight: .semibold)
        contentLabel2.size14(text: "Permission.Camera.Title".localized, color: .gray77)
        subLabel1.size12(text: "Permission.Camera.Desc".localized, color: .gray128)
        bottomContainer.backgroundColor = .mint4
        bottomContainer.border(0.5, .mint3)
        bottomLabel1.size12(text: "Permission.footer.desc1".localized, color: .mint1, weight: .light)
        bottomLabel2.size12(text: "Permission.footer.desc2".localized, color: .mint1, weight: .light)
        
        confirmButton.round02()
        confirmButton.setTitle("Common.Confirm".localized, for: .normal)
    }
}
