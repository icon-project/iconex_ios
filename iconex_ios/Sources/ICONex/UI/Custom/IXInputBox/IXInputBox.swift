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

enum IXInputBoxType {
    case normal
    case name
    case email
    case createPassword
    case secure
    case decimal
    case integer
}

@IBDesignable class IXInputBox: UIView {
    private var contentView: UIView?
    
    @IBOutlet private var textField: IXTextField!
    @IBOutlet private var borderView: UIView!
    @IBOutlet private weak var coverView: UIView!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var placeholderLabel: UILabel!
    
    private let disposeBag = DisposeBag()
    
    private var _state: IXInputBoxState = .normal {
        willSet {
            switch newValue {
            case .normal:
                borderView.backgroundColor = .gray250
                borderView.border(1.0, .gray230)
                placeholderLabel.textColor = .gray77
                
            case .focus:
                borderView.backgroundColor = .mint4
                borderView.border(1.0, .mint2)
                placeholderLabel.textColor = .mint2
                
            case .disable:
                borderView.backgroundColor = .gray250
                borderView.border(1.0, .gray230)
                placeholderLabel.isHidden = true
                coverView.isHidden = true
                
            case .error:
                borderView.backgroundColor = .error3
                borderView.border(1.0, .error1)
                placeholderLabel.textColor = .error1
            }
        }
    }
    
    private var _type: IXInputBoxType = .normal {
        willSet {
            textField.isSecureTextEntry = false
            
            switch newValue {
            case .normal:
                textField.keyboardType = .default
                textField.canPaste = true
                
            case .email:
                textField.keyboardType = .emailAddress
                textField.canPaste = true
                
            case .name:
                textField.keyboardType = .default
                textField.canPaste = false
                
            case .createPassword, .secure:
                textField.isSecureTextEntry = true
                textField.canPaste = false
                
            case .decimal:
                textField.keyboardType = .decimalPad
                textField.canPaste = false
                
            case .integer:
                textField.keyboardType = .numberPad
                textField.canPaste = true
            }
        }
    }
    
    var state: IXInputBoxState { return _state }
    var inputType: IXInputBoxType { return _type }
    
    private var validateOnExit: ((String) -> String?)?
    
    private var placeholder: String? {
        willSet {
            textField.placeholder = newValue
            
            if let text = textField.text, text.count > 0, let value = newValue {
                placeholderLabel.isHidden = false
                coverView.isHidden = false
                placeholderLabel.text = value
            } else {
                coverView.isHidden = true
                placeholderLabel.isHidden = true
            }
        }
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        xibSetup()
        contentView?.prepareForInterfaceBuilder()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        xibSetup()
        set(state: .normal)
        setKeyboard()
        
        textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.set(state: .focus)
        }).disposed(by: disposeBag)
        
        textField.tintColor = .mint1
        
        textField.rx.text.subscribe(onNext: { text in
            if let input = text, input.count > 0 {
                self.placeholderLabel.isHidden = false
                self.coverView.isHidden = false
                self.placeholderLabel.text = self.placeholder
            } else {
                self.placeholderLabel.isHidden = true
                self.coverView.isHidden = true
            }
        }).disposed(by: disposeBag)
        
        textField.rx.controlEvent([.editingDidEnd, .editingDidEndOnExit]).subscribe(onNext: { [unowned self] in
            self.set(state: .normal)
            if let validate = self.validateOnExit {
                self.setError(message: validate(self.textField.text!))
            }
        }).disposed(by: disposeBag)
    }
    
    func xibSetup() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "IXInputBox", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        subtitleLabel.text = ""
        subtitleLabel.textColor = .error1
        borderView.corner(4)
    }
    
    func set(state: IXInputBoxState = .normal) {
        _state = state
    }
    
    func set(state: IXInputBoxState = .normal, placeholder: String? = nil) {
        _state = state
        self.placeholder = placeholder
    }
    
    func setError(message: String?) {
        if let msg = message {
            _state = .error
            subtitleLabel.text = msg
        } else {
            _state = .normal
            subtitleLabel.text = ""
        }
    }
    
    func set(validator: @escaping ((String) -> String?)) {
        self.validateOnExit = validator
    }
    
    func setKeyboard(returnType type: UIReturnKeyType = .done) {
        self.textField.returnKeyType = type
    }
    
    func set(inputType: IXInputBoxType) {
        _type = inputType
    }
}
