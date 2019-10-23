//
//  BasicAlertView.swift
//  iconex_ios
//
//  Created by Seungyeon Lee on 2019/08/07.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class BasicAlertView: UIView {
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    var info: AlertBasicInfo? {
        willSet {
            titleLabel.size16(text: newValue!.title, color: .gray77, weight: .medium, align: .center, lineBreakMode: .byWordWrapping)
            if let sub = newValue?.subtitle {
                subtitleLabel.size14(text: sub, color: .gray128, weight: .light, align: .center, lineBreakMode: .byWordWrapping)
            } else {
                subtitleLabel.isHidden = true
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func xibSetup() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "BasicAlertView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
    }

}
