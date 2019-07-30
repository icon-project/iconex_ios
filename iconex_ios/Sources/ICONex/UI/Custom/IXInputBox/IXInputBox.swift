//
//  IXInputBox.swift
//  iconex_ios
//
//  Created by a1ahn on 29/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum IXInputBoxState {
    case normal
    case error
    case focus
    case disable
}

@IBDesignable class IXInputBox: UIView {
    private var contentView: UIView?
    
    @IBOutlet private var textField: IXTextField!
    @IBOutlet private var borderView: UIView!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var placeholderLabel: UILabel!

    private let disposeBag = DisposeBag()
    private var _state: IXInputBoxState = .normal {
        willSet {
            placeholderLabel.isHidden = false
            
            switch newValue {
            case .normal:
                borderView.backgroundColor = .gray250
                borderView.border(1.0, .gray230)
                placeholderLabel.textColor = .gray77
                
            case .focus:
                borderView.backgroundColor = .mint2
                borderView.border(1.0, .mint2)
                
            case .disable:
                borderView.backgroundColor = .gray250
                borderView.border(1.0, .gray230)
                placeholderLabel.isHidden = true
                
            case .error:
                borderView.backgroundColor = .error3
                borderView.border(1.0, .error1)
            }
        }
    }
    
    var state: IXInputBoxState { return _state }
    
    private var placeholder: String? {
        willSet {
            textField.placeholder = newValue
            
            if let text = textField.text, text.count > 0, let value = newValue {
                placeholderLabel.isHidden = false
                placeholderLabel.text = value
            } else {
                placeholderLabel.isHidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func xibSetup() {
        guard let view = loadViewFromNib() else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        subtitleLabel.text = ""
        subtitleLabel.textColor = .error1
        borderView.corner(4)
    }
    
    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "IXInputBox", bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
    func set(state: IXInputBoxState = .normal) {
        _state = state
    }
    
    func set(state: IXInputBoxState = .normal, placeholder: String? = nil, error: String? = nil) {
        _state = state
        
    }
    
    func set(validator: @escaping ((String) -> Void), events: UIControl.Event) {
        textField.rx.controlEvent(events).subscribe(onNext: { [unowned self] in
            validator(self.textField.text!)
        }).disposed(by: disposeBag)
    }
}
