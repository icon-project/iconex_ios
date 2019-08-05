//
//  LoadSelectViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 05/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class LoadSelectViewController: BaseViewController {
    @IBOutlet weak var loadSelectHeader: UILabel!
    @IBOutlet weak var keystoreCard: SelectCardView!
    @IBOutlet weak var privateCard: SelectCardView!
    @IBOutlet weak var loadSelectDesc1: UILabel!
    @IBOutlet weak var loadSelectDesc2: UILabel!
    
    private var _isKeystore: Bool = true {
        willSet {
            switch newValue {
            case true:
                keystoreCard.mode = .selected
                privateCard.mode = .normal
                
            case false:
                keystoreCard.mode = .normal
                privateCard.mode = .selected
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        keystoreCard.button.rx.tap.subscribe(onNext: { [unowned self] in
            self._isKeystore = true
        }).disposed(by: disposeBag)
        privateCard.button.rx.tap.subscribe(onNext:  { [unowned self] in
            self._isKeystore = false
        }).disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        loadSelectHeader.size16(text: "LoadSelect.Header".localized, color: .gray77, weight: .medium, align: .center)
        keystoreCard.setTitle(main: "LoadSelect.Keystore".localized, sub: nil)
        keystoreCard.setImage(normal: #imageLiteral(resourceName: "imgKeystore"))
        privateCard.setTitle(main: "LoadSelect.PrivateKey".localized, sub: nil)
        privateCard.setImage(normal: #imageLiteral(resourceName: "imgPrivatekey"))
        loadSelectDesc1.size12(text: "LoadSelect.Desc1".localized, color: .mint2, weight: .light, align: .left)
        loadSelectDesc2.size12(text: "LoadSelect.Desc2".localized, color: .mint2, weight: .light, align: .left)
        
        _isKeystore = true
    }
}
