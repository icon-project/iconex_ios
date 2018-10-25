//
//  IXInputBox.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import BigInt
import RxCocoa
import RxSwift

class IXTextField: PreventTextField {
    
}

enum IXTextFieldState {
    case normal
    case error
    case focus
    case readOnly
    case exchange
}

enum IXTextFieldType {
    case normal
    case name
    case password
    case newPassword
    case numeric
    case plain
    case integer
    case address
    case data
}

@IBDesignable class IXInputBox: UIView, UITextFieldDelegate {
    @IBInspectable var nibName: String?
    var contentView: UIView?
    
    @IBOutlet var textField: IXTextField!
    @IBOutlet private var highlightLine: UIView!
    @IBOutlet private var warnLabel: UILabel!
    @IBOutlet weak var plainLabel: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var trailConstraint: NSLayoutConstraint!
    @IBOutlet weak var plainHighlight: UIView!
    
    private let disposeBag = DisposeBag()
    private var previousState: IXTextFieldState?
    
    var isEnable: Bool = true {
        didSet {
            self.textField.isEnabled = isEnable
            
            if !isEnable {
                _state = .readOnly
            } else {
                if let previous = self.previousState {
                    _state = previous
                } else {
                    _state = .normal
                }
            }
        }
    }
    
    var isLoading: Bool = false {
        willSet {
            if newValue {
                indicator.isHidden = false
                trailConstraint.constant = 44
                UIView.animate(withDuration: 0.2) {
                    self.layoutIfNeeded()
                }
            } else {
                indicator.isHidden = true
                trailConstraint.constant = 10
                UIView.animate(withDuration: 0.2, animations: {
                    self.layoutIfNeeded()
                }) { (isCompleted) in
                }
            }
        }
    }
    
    var state: IXTextFieldState {
        return _state
    }
    
    private var _state: IXTextFieldState = .normal {
        willSet {
            switch newValue {
            case .normal:
                if isEnable {
                    highlightLine.backgroundColor = UIColor.darkTheme.background.normal
                } else {
                    highlightLine.backgroundColor = UIColor.lightTheme.background.disabled
                }
                warnLabel.isHidden = true
                
            case .error:
                highlightLine.backgroundColor = UIColor.warn
                warnLabel.textAlignment = .left
                warnLabel.textColor = UIColor.warn
                warnLabel.isHidden = false
                
            case .focus:
                highlightLine.backgroundColor = UIColor.lightTheme.background.normal
                
            case .readOnly:
                highlightLine.backgroundColor = UIColor.lightTheme.background.disabled
                
            case .exchange:
                warnLabel.textAlignment = .right
                warnLabel.textColor = UIColor(38, 38, 38, 0.5)
                warnLabel.isHidden = false
            }
            
            if previousState == nil {
                previousState = newValue
            }
        }
    }
    
    private var _fieldType: IXTextFieldType = .normal {
        willSet {
            plainHighlight.isHidden = true
            highlightLine.isHidden = false
            
            switch newValue {
            case .name:
                textField.isSecureTextEntry = false
                textField.keyboardType = .default
                textField.isPreventPaste = true
                trailConstraint.constant = 10
                textField.isHidden = false
                plainLabel.isHidden = true
                
            case .normal, .address, .data:
                textField.isSecureTextEntry = false
                textField.keyboardType = .default
                textField.isPreventPaste = false
                trailConstraint.constant = 10
                textField.isHidden = false
                plainLabel.isHidden = true
                
            case .password:
                textField.isSecureTextEntry = true
                textField.isPreventPaste = true
                trailConstraint.constant = 10
                textField.isHidden = false
                plainLabel.isHidden = true
                
            case .newPassword:
                textField.isSecureTextEntry = true
                textField.isPreventPaste = true
                trailConstraint.constant = 10
                textField.isHidden = false
                plainLabel.isHidden = true
                
            case .numeric:
                textField.keyboardType = .decimalPad
                textField.isPreventPaste = true
                textField.isSecureTextEntry = false
                trailConstraint.constant = 10
                textField.isHidden = false
                plainLabel.isHidden = true
                
            case .plain:
                textField.isSecureTextEntry = false
                textField.isPreventPaste = false
                trailConstraint.constant = 10
                textField.isHidden = true
                plainLabel.isHidden = false
                plainHighlight.isHidden = false
                highlightLine.isHidden = true
                
            case .integer:
                textField.keyboardType = .decimalPad
                textField.isPreventPaste = true
                textField.isSecureTextEntry = false
                trailConstraint.constant = 10
                textField.isHidden = false
                plainLabel.isHidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        xibSetup()
    }
    
    func xibSetup() {
        guard let view  = loadViewFromNib() else { return }
        isLoading = false
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        warnLabel.textColor = UIColor.warn
        textField.returnKeyType = .done
        textField.delegate = self
        plainHighlight.backgroundColor = UIColor.lightTheme.background.disabled
        warnLabel.text = ""
    }
    
    func loadViewFromNib() -> UIView? {
        guard let nibName = nibName else { return nil }
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
    func setType(_ type: IXTextFieldType = .normal) {
        _fieldType = type
    }
    
    func setState(_ state: IXTextFieldState = .normal, _ message: String? = nil) {
        _state = state
        
        guard let msg = message else {
            return
        }
        
        warnLabel.text = msg
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        xibSetup()
        contentView?.prepareForInterfaceBuilder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if _fieldType == .numeric || _fieldType == .integer {
            switch string {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                return true
                
            case ".":
                if _fieldType == .integer { return false }
                let array = Array(textField.text!).filter { $0 == "." }
                let result = array.count >= 1 ? false : true
                return result
                
            default:
                let array = Array(string)
                if array.count == 0 {
                    return true
                }
                return false
            }
        } else if (_fieldType == .normal || _fieldType == .data || _fieldType == .name) && string != "" && string != "\n" {
            
            if string == " " {
                guard let text = textField.text, text != "", !text.hasPrefix(" "), range.location != 0 else { return false }
            }
            
            
            guard let former = textField.text as NSString? else { return true }
            let text = former.replacingCharacters(in: range, with: string)

            let length = text.unicodeScalars.compactMap({ $0.isASCII ? 1 : 2 }).reduce(0, +)
            
            if length > 16 && (_fieldType == .normal || _fieldType == .name) {
                return false
            }
        } else if _fieldType == .password || _fieldType == .newPassword || _fieldType == .address {
            if string == " " { return false }
        }
        
        return true
    }
}
