//
//  PRepDetailAlertView.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 17/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PRepDetailAlertView: UIView {
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var prepNameLabel: UILabel!
    @IBOutlet weak var serverTitle: UILabel!
    @IBOutlet weak var serverLabel: UILabel!
    @IBOutlet weak var detailButton: UIButton!
    
    var prepInfo: PRepInfoResponse? {
        willSet {
            guard let prep = newValue else { return }
            prepNameLabel.size16(text: prep.name, color: .gray77, weight: .semibold)
            
            let status: String = {
                switch prep.status {
                case .active: return "Active"
                default: return "Inactive"
                }
            }()
            serverLabel.size14(text: "\(prep.city) / \(status)", color: .gray128)
        }
    }
    
    var disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func xibSetup() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "PRepDetailAlertView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        
        serverTitle.size14(text: "Server:", color: .gray128)
        
        let attrString = NSAttributedString(string: "PRepView.Alert.Detail".localized, attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .light), .foregroundColor: UIColor.mint1, .underlineStyle: NSUnderlineStyle.single.rawValue])
        
        detailButton.setAttributedTitle(attrString, for: .normal)
        
        detailButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                guard let prep = self.prepInfo else { return }
                guard let url = URL(string: prep.website), UIApplication.shared.canOpenURL(url) else { return }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }.disposed(by: disposeBag)
        
    }
}
