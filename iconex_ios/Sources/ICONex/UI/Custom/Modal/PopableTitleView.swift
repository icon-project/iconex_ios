//
//  PopableTitleView.swift
//  iconex_ios
//
//  Created by a1ahn on 02/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

@IBDesignable
class PopableTitleView: UIView {
    var contentView: UIView?
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var leftButton: UIButton!
    
    let disposeBag = DisposeBag()
    
    var actionHandler: (() -> Void)? {
        willSet {
            self.leftButton.isHidden = newValue == nil
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        xibSetup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        xibSetup()
    }
    
    func xibSetup() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "PopableTitleView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        
        actionHandler = nil
        
        leftButton.rx.tap.subscribe(onNext: { [unowned self] in
            self.actionHandler?()
        }).disposed(by: disposeBag)
    }
    
    func set(title: String) {
        titleLabel.size18(text: title, weight: .medium, align: .center)
    }
    
    func setButtonImage(image: UIImage) {
        leftButton.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        leftButton.tintColor = .darkGray
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 60)
    }
}
