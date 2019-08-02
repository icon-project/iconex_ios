//
//  CreateSelectViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 02/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class CreateSelectViewController: BaseViewController {
    @IBOutlet weak var mainDescLabel: UILabel!
    @IBOutlet weak var bottomDescLabel1: UILabel!
    @IBOutlet weak var bottomDescLabel2: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
    }
    
    override func refresh() {
        super.refresh()
        mainDescLabel.size16(text: "CreateSelect.Main".localized, color: .gray77, weight: .medium, align: .center)
        bottomDescLabel1.size12(text: "CreateSelect.Instruction1".localized, color: .mint1, weight: .light)
        bottomDescLabel2.size12(text: "CreateSelect.Instruction2".localized, color: .mint1, weight: .light)
    }
}
