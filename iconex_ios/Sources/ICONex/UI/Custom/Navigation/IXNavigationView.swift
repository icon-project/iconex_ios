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
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var toggleImageView: UIImageView!
    
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
    private var toggleAction: (() -> Void)? {
        willSet {
            toggleButton.isHidden = newValue == nil
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        xibSetup()
        
        toggleButton.isHidden = true
        
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
        
        toggleButton.rx.tap.subscribe(onNext: { (_) in
            if let action = self.toggleAction {
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
    
    func setTitle(_ title: String, isMain: Bool = false) {
        self.titleLabel.size18(text: title, color: .white, weight: .medium, align: .center)
        if isMain {
            self.toggleImageView.image = #imageLiteral(resourceName: "icArrowToggle")
        } else {
            self.toggleImageView.isHidden = true
        }
    }
    
    func setLeft(image: UIImage? = #imageLiteral(resourceName: "icAppbarBack"), action: (() -> Void)?) {
        self.leftButton.setImage(image, for: .normal)
        self.leftAction = action
    }
    
    func setRight(image: UIImage? = nil, action: (() -> Void)?) {
        self.rightButton.setImage(image, for: .normal)
        self.rightAction = action
    }
    
    func setRight(title: String? = nil, action: (() -> Void)?) {
        self.rightButton.setTitle(title, for: .normal)
        self.rightButton.setTitleColor(.white, for: .normal)
        self.rightButton.setTitleColor(UIColor.init(white: 1, alpha: 0.6), for: .disabled)
        
        self.rightAction = action
    }
    
    func setRight(title: String? = nil) {
        self.rightButton.setTitle(title, for: .normal)
        self.rightButton.setTitleColor(.white, for: .normal)
        self.rightButton.setTitleColor(UIColor.init(white: 1, alpha: 0.6), for: .disabled)
    }
    
    func hideToggleImageView(_ value: Bool? = nil) {
        if let val = value {
            self.toggleImageView.isHidden = val
            self.toggleButton.isEnabled = val
        } else {
            self.toggleImageView.isHidden.toggle()
            self.toggleButton.isEnabled.toggle()
        }
    }
    
    func setToggleButton(action: (() -> Void)?) {
        self.toggleAction = action
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 56)
    }
}
