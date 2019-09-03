//
//  DetailOptionViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 30/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class DetailOptionViewController: UIViewController {
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var subTitleLabel: UILabel!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var allButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var depositButton: UIButton!
    
    var filter: TxFilter = .all
    
    var confirmHandler: ((_ filter: TxFilter) -> Void)?
    
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBind()
    }
    
    private func setupUI() {
        detailViewModel.filter.subscribe(onNext: { (filter) in
            switch filter {
            case .all:
                self.allButton.isSelected = true
            case .send:
                self.sendButton.isSelected = true
            case .deposit:
                self.depositButton.isSelected = true
            }
        }).disposed(by: disposeBag)
        
        
        confirmButton.setTitle("Common.Confirm".localized, for: .normal)
        confirmButton.setTitleColor(.gray128, for: .normal)
        
        titleLabel.size18(text: "Wallet.Detail.Option.Title".localized, color: .gray77, weight: .medium, align: .center)
        subTitleLabel.size12(text: "Wallet.Detail.Option.SubTitle".localized, color: .gray128, weight: .light, align: .center)
        
        allButton.pickerTab()
        sendButton.pickerTab()
        depositButton.pickerTab()
        
        allButton.setTitle("Wallet.Detail.Option.All".localized, for: .normal)
        sendButton.setTitle("Wallet.Detail.Option.Send".localized, for: .normal)
        depositButton.setTitle("Wallet.Detail.Option.Deposit".localized, for: .normal)
        
        allButton.clipsToBounds = true
        depositButton.clipsToBounds = true
        
        allButton.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        sendButton.layer.maskedCorners = []
        depositButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    }
    
    private func setupBind() {
        
        closeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
        allButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.allButton.isSelected = true
                self.sendButton.isSelected = false
                self.depositButton.isSelected = false
                self.filter = .all
        }.disposed(by: disposeBag)

        sendButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.sendButton.isSelected = true
                self.allButton.isSelected = false
                self.depositButton.isSelected = false
                self.filter = .send
            }.disposed(by: disposeBag)

        depositButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.depositButton.isSelected = true
                self.sendButton.isSelected = false
                self.allButton.isSelected = false
                self.filter = .deposit
            }.disposed(by: disposeBag)
        
        confirmButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                detailViewModel.filter.onNext(self.filter)
                self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
    }
}
