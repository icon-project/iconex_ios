//
//  IXKeyboardToolBar.swift
//  iconex_ios
//
//  Created by Seungyeon Lee on 2019/09/01.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class IXKeyboardToolBar: UIView {

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var typeLabel: UILabel!
    
    @IBOutlet weak var kbLabel: UILabel!
    @IBOutlet weak var kbTitleLabel: UILabel!
    
    var dataType: InputType = .utf8 {
        willSet {
            self.typeLabel.size14(text: newValue == .utf8 ? "UTF-8" : "HEX", color: .gray179)
        }
    }
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
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
        let nib = UINib(nibName: "IXKeyboardToolBar", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        
        completeButton.gray77round()
        completeButton.setTitle("Common.Complete".localized, for: .normal)
        kbTitleLabel.size14(text: "0", color: .gray77, align: .right)
        kbTitleLabel.size14(text: "/ 512 KB", color: .gray77, align: .right)
    }
}
