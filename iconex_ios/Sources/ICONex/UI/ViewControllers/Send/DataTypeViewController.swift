//
//  DataTypeViewController.swift
//  iconex_ios
//
//  Created by Seungyeon Lee on 2019/09/01.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PanModal

class DataTypeViewController: UIViewController {
    @IBOutlet weak var dimmView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var utf8Button: UIButton!
    @IBOutlet weak var hexButton: UIButton!
    
    var isSelect: InputType = .utf8
    
    var disposeBag = DisposeBag()
    
    var handler: ((_ data: String?, _ dataType: InputType) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBind()
    }
    
    private func setupUI() {
        titleLabel.size18(text: "Send.DataType.Title".localized, color: .gray77, weight: .medium, align: .center)
        subtitleLabel.size12(text: "Send.DataType.Subtitle".localized, color: .gray128, weight: .light, align: .center)
        confirmButton.setTitleColor(.gray128, for: .normal)
        confirmButton.setTitle("Common.Confirm".localized, for: .normal)
        
        utf8Button.pickerTab()
        hexButton.pickerTab()

        utf8Button.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        hexButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        
        utf8Button.setTitle("UTF-8", for: .normal)
        hexButton.setTitle("HEX", for: .normal)
        
        utf8Button.isSelected = true
        
    }
    
    private func setupBind() {
        utf8Button.rx.tap.asControlEvent()
            .subscribe { [unowned self] (_) in
                self.isSelect = .utf8
                if !self.utf8Button.isSelected {
                    self.utf8Button.isSelected = true
                    self.hexButton.isSelected = false
                }
        }.disposed(by: disposeBag)
        
        hexButton.rx.tap.asControlEvent()
            .subscribe { [unowned self] (_) in
                self.isSelect = .hex
                if !self.hexButton.isSelected {
                    self.hexButton.isSelected = true
                    self.utf8Button.isSelected = false
                }
            }.disposed(by: disposeBag)
        
        
        dismissButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
        confirmButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let inputVC = self.storyboard?.instantiateViewController(withIdentifier: "InputData") as! InputDataViewController
                inputVC.type = self.isSelect
                
                self.dismiss(animated: true, completion: {
                    app.topViewController()?.presentPanModal(inputVC)
                    
                    inputVC.completeHandler = { data, dataType in
                        if let handler = self.handler {
                            handler(data, dataType)
                        }
                    }
                })
                
        }.disposed(by: disposeBag)
    }
}
