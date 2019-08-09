//
//  CreateSelectViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 02/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CreateSelectViewController: BaseViewController {
    @IBOutlet weak var mainDescLabel: UILabel!
    @IBOutlet weak var icxCard: SelectCardView!
    @IBOutlet weak var ethCard: SelectCardView!
    @IBOutlet weak var bottomDescLabel1: UILabel!
    @IBOutlet weak var bottomDescLabel2: UILabel!
    
    private var _isIcx: Bool = true {
        willSet {
            switch newValue {
            case true:
                icxCard.mode = .selected
                ethCard.mode = .normal
                
            case false:
                icxCard.mode = .normal
                ethCard.mode = .selected
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        icxCard.button.rx.tap.subscribe(onNext: { [unowned self] in
            self._isIcx = true
        }).disposed(by: disposeBag)
        
        ethCard.button.rx.tap.subscribe(onNext: { [unowned self] in
            self._isIcx = false
        }).disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        mainDescLabel.size16(text: "CreateSelect.Main".localized, color: .gray77, weight: .medium, align: .center)
        bottomDescLabel1.size12(text: "CreateSelect.Instruction1".localized, color: .mint1, weight: .light)
        bottomDescLabel2.size12(text: "CreateSelect.Instruction2".localized, color: .mint1, weight: .light)
        
        icxCard.setImage(normal: #imageLiteral(resourceName: "imgLogoIconSel"))
        icxCard.setTitle(main: "ICX Wallet", sub: "ICON")
        ethCard.setImage(normal: #imageLiteral(resourceName: "imgLogoEthereumSel"))
        ethCard.setTitle(main: "ETH Wallet", sub: "Ethereum")
        
        _isIcx = true
    }
}
