//
//  SelectCardView.swift
//  iconex_ios
//
//  Created by a1ahn on 05/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

enum SelectCardMode {
    case normal, selected
}

@IBDesignable
class SelectCardView: UIView {
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var subLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    
    private var contentView: UIView?
    
//    private var mainText: String?
//    private var subText: String?
    
    var mode: SelectCardMode = .normal {
        willSet {
            switch newValue {
            case .normal:
                iconView.tintColor = .gray77
                contentView?.border(1.0, .gray230)
                contentView?.backgroundColor = .gray250
                mainLabel.textColor = .gray77
                subLabel.textColor = .gray77
                
            case .selected:
                iconView.tintColor = .mint2
                contentView?.border(1.0, .mint2)
                contentView?.backgroundColor = .mint4
                mainLabel.textColor = .mint2
                subLabel.textColor = .mint2
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        xibSetup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        xibSetup()
        contentView?.prepareForInterfaceBuilder()
    }

    private func xibSetup() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "SelectCardView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.corner(4)
        addSubview(view)
        contentView = view
        
        mode = .normal
    }
    
    func setImage(normal: UIImage, isLogo: Bool = false) {
        if isLogo {
            self.iconView.image = normal
        } else {
            self.iconView.image = normal.withRenderingMode(.alwaysTemplate)
        }
    }
    
    func setTitle(main: String, sub: String?) {
        self.mainLabel.size16(text: main, color: .mint2, weight: .medium, align: .center)
        if let subString = sub {
            self.subLabel.isHidden = false
            self.subLabel.size12(text: subString, color: .mint2, weight: .light, align: .center)
        } else {
            self.subLabel.isHidden = true
        }
    }
}
