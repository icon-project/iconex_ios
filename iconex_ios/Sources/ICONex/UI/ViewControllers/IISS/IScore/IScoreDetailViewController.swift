//
//  IScoreDetailViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 13/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class IScoreDetailViewController: BaseViewController {
    @IBOutlet weak var navBar: IXNavigationView!
    @IBOutlet weak var IScoreHeader1: UILabel!
    @IBOutlet weak var currentIScoreValue: UILabel!
    @IBOutlet weak var IScoreHeader2: UILabel!
    @IBOutlet weak var receiveICXValue: UILabel!
    @IBOutlet weak var descContainer: UIView!
    @IBOutlet weak var descHeader1: UILabel!
    @IBOutlet weak var descValue1: UILabel!
    @IBOutlet weak var descHeader2: UILabel!
    @IBOutlet weak var descValue2: UILabel!
    @IBOutlet weak var exchangedValue: UILabel!
    @IBOutlet weak var bottomContainer: UIView!
    @IBOutlet weak var claimButton: UIButton!
    
    var wallet: ICXWallet!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        IScoreHeader1.size16(text: "IScoreDetail.Header1".localized, color: .gray77, weight: .medium, align: .left)
        IScoreHeader2.size16(text: "IScoreDetail.Header2".localized, color: .gray77, weight: .medium, align: .left)
        descContainer.border(0.5, .gray230)
        descContainer.backgroundColor = .gray250
        descHeader1.size12(text: "IScoreDetail.DescHeader1".localized, color: .gray128, weight: .light, align: .left)
        descHeader2.size12(text: "IScoreDetail.DescHeader2".localized, color: .gray128, weight: .light, align: .left)
        
        claimButton.lightMintRounded()
        claimButton.setTitle("IScoreDetail.Claim".localized, for: .normal)
        
        navBar.setLeft {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func refresh() {
        super.refresh()
        
        navBar.setTitle(wallet.name)
    }
}
