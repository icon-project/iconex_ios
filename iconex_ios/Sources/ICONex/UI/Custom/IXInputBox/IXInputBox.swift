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
    case readOnly
}

enum IXInputBoxType {
    case normal
    case name
    case email
    case createPassword
    case confirmPassword
    case secure
    case decimal
    case integer
    case fileSelect
    case address
}

@IBDesignable class IXInputBox: UIView {
    private var contentView: UIView?
    
    @IBOutlet var textField: IXTextField!
    @IBOutlet private var borderView: UIView!
    @IBOutlet private weak var coverView: UIView!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var placeholderLabel: UILabel!
    
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
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
                if _type == .fileSelect {
                    textField.textColor = .mint1
                }
                
            case .disable:
                borderView.backgroundColor = .gray250
                borderView.border(1.0, .gray230)
                placeholderLabel.isHidden = true
                coverView.isHidden = true
                
            case .error:
                borderView.backgroundColor = .error3
                borderView.border(1.0, .error1)
                placeholderLabel.textColor = .error1
                if _type == .fileSelect {
                    textField.textColor = .error1
                }
            case .readOnly:
                borderView.backgroundColor = .gray250
                borderView.border(1.0, .gray230)
                placeholderLabel.textColor = .gray77
                placeholderLabel.isHidden = false
                coverView.isHidden = false
                textField.isEnabled = false
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
                subtitleLabel.text = ""
                
            case .email:
                textField.keyboardType = .emailAddress
                textField.canPaste = true
                
            case .name:
                textField.keyboardType = .default
                textField.canPaste = false
                
            case .createPassword, .confirmPassword:
                textField.isSecureTextEntry = true
                textField.canPaste = false
                forgotPasswordButton.isHidden = true
                
            case .secure:
                textField.isSecureTextEntry = true
                textField.canPaste = false
                forgotPasswordButton.isHidden = false
                forgotPasswordButton.setTitle("Alert.ForgotPasscode.Title".localized, for: .normal)
                forgotPasswordButton.setTitleColor(.gray128, for: .normal)
                
            case .decimal:
                textField.keyboardType = .decimalPad
                textField.canPaste = false
                
            case .integer:
                textField.keyboardType = .numberPad
                textField.canPaste = false
                
            case .fileSelect:
                textField.isEnabled = false
                textField.canPaste = false
                
            case .address:
                textField.keyboardType = .asciiCapable
                textField.canPaste = true
                subtitleLabel.text = ""
            }
        }
    }
    
    var state: IXInputBoxState { return _state }
    var inputType: IXInputBoxType { return _type }
    var maxDecimalLength: Int = 18
    
    var text: String {
        get {
            return textField.text!
        }
        
        set {
            textField.text = newValue
        }
    }
    
    var leftAccessory: UIView? {
        get {
            return textField.leftView
        }
        
        set {
            textField.leftView = newValue
            textField.leftViewMode = newValue != nil ? .always : .never
        }
    }
    
    private var validateOnExit: ((String) -> String?)?
    
    private var placeholder: String? {
        willSet {
            textField.attributedPlaceholder = NSAttributedString(string: newValue!, attributes: [.foregroundColor: UIColor.gray217, .font: UIFont.systemFont(ofSize: 15, weight: .medium)])
            
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
        textField.textColor = .gray77
        
        let textFieldShare = textField.rx.text.orEmpty.share(replay: 1)
        
        textFieldShare
            .subscribe(onNext: { text in
            if text.count > 0 {
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
        forgotPasswordButton.isHidden = true
        textField.delegate = self
    }
    
    func set(state: IXInputBoxState = .normal) {
        _state = state
        subtitleLabel.text = ""
    }
    
    func set(state: IXInputBoxState = .normal, placeholder: String? = nil) {
        _state = state
        self.placeholder = placeholder
    }
    
    func set(maxDecimalLength: Int = 18) {
        self.maxDecimalLength = maxDecimalLength
    }
    
    func setError(message: String?) {
        subtitleLabel.textColor = .error1
        if let msg = message, msg.count > 0 {
            if msg.hasPrefix("$") {
                _state = .normal
                subtitleLabel.textColor = .gray179
                subtitleLabel.text = msg
            } else {
                _state = .error
                subtitleLabel.text = msg
            }
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

extension IXInputBox: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch string {
        case Tool.decimalSeparator where _type == .integer:
            return false
            
        case Tool.decimalSeparator where _type == .decimal:
            return Array(textField.text!).filter { String($0) == Tool.decimalSeparator }.count < 1
            
        case " " where _type == .createPassword:
            return false
            
        case " " where _type == .normal || _type == .name:
            return !textField.text!.hasPrefix(" ") && range.location != 0
            
        case "": return true
            
        case "\n": return true
            
        default:
            guard let former = textField.text as NSString? else { return false }
            let text = former.replacingCharacters(in: range, with: string)
            if _type == .name {
                let length = text.unicodeScalars.compactMap({ $0.isASCII ? 1 : 2}).reduce(0, +)
                return length <= 16
            }
            
            if _type == .decimal {
                let split = text.components(separatedBy: ".")
                if let above = split.first {
                    if above.count <= 10 {
                        
                        if let below = split.last {
                            
                            if below.count <= maxDecimalLength {
                                return below.onlyNumbers()
                            }
                            return false
                        }
                        return above.onlyNumbers()
                    }
                }
                return false
            }
            return true
        }
    }
}

extension String {
    func onlyNumbers() -> Bool {
        let numSet = CharacterSet.decimalDigits
        let validSet = numSet.union(CharacterSet(charactersIn: ".,"))
        
        return self.rangeOfCharacter(from: validSet.inverted, options: .caseInsensitive, range: nil) == nil
    }
}
