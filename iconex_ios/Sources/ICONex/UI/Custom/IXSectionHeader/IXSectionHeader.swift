//
//  IXSectionHeader.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 28/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class IXSectionHeader: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var toggleButton: UIButton!
    
    var filter: TxFilter = .all
    
    var handler: ((_ txFilter: TxFilter) -> Void)?
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupBind()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        xibSetup()
        setupBind()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func xibSetup() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "IXSectionHeader", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        
        titleLabel.text = "Wallet.Detail.Section.Title".localized
//        typeLabel.text = "Wallet.Detail.Option.All".localized
    }
    
    private func setupBind() {
        
        infoButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                Alert.basic(title: "Wallet.Detail.Alert.Info".localized, leftButtonTitle: "Common.Confirm".localized).show()
            }.disposed(by: disposeBag)
        
        toggleButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let optionVC = UIStoryboard(name: "Detail", bundle: nil).instantiateViewController(withIdentifier: "DetailOption") as! DetailOptionViewController
                optionVC.filter = self.filter
                
                optionVC.confirmHandler = { filter in
                    if let confirmHandler = self.handler {
                        confirmHandler(filter)
                    }
                }
                
                optionVC.show()
                
            }.disposed(by: disposeBag)
    }
}
