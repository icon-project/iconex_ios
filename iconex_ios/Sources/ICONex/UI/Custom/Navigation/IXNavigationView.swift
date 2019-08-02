//
//  IXNavigationView.swift
//  iconex_ios
//
//  Created by a1ahn on 02/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

@IBDesignable
class IXNavigationView: UIView {
    private var contentView: UIView?
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var leftButton: UIButton!
    @IBOutlet private weak var rightButton: UIButton!
    
    private let disposeBag = DisposeBag()
    
    private var leftAction: (() -> Void)? {
        willSet {
            leftButton.isHidden = newValue == nil
        }
    }
    private var rightAction: (() -> Void)? {
        willSet {
            rightButton.isHidden = newValue == nil
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        xibSetup()
        leftButton.rx.tap.subscribe(onNext: { [unowned self] in
            if let action = self.leftAction {
                action()
            }
        }).disposed(by: disposeBag)
        
        rightButton.rx.tap.subscribe(onNext: { [unowned self] in
            if let action = self.rightAction {
                action()
            }
        }).disposed(by: disposeBag)
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        xibSetup()
        contentView?.prepareForInterfaceBuilder()
    }
    
    func xibSetup() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "IXNavigationView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = .mint1
        addSubview(view)
        contentView = view
        backgroundColor = .mint1
        titleLabel.text = ""
        leftAction = nil
        rightAction = nil
    }
    
    func setTitle(_ title: String) {
        self.titleLabel.size18(text: title, color: .white, weight: .medium, align: .center)
    }
    
    func setLeft(action: (() -> Void)?) {
        self.leftAction = action
    }
    
    func setRight(image: UIImage?, action: (() -> Void)?) {
        self.rightAction = action
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 56)
    }
}
