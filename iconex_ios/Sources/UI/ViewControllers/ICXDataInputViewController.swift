//
//  ICXDataInputViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ICONKit
import BigInt

enum EncodeType {
    case utf8
    case hex
}

class ICXDataInputViewController: BaseViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var stepView: UIView!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var lengthLabel: UILabel!
    @IBOutlet weak var placeholder: UILabel!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var handler: ((String) -> Void)?
    var type: EncodeType = .utf8
    var savedData: String? = nil
    var stepPrice: BigUInt?
    var costs: ICON.Response.StepCosts.CostResult?
    var walletAmount: BigUInt?
    var sendAmount: BigUInt?
    var isModify: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeUI()
        initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        switch self.type {
        case .utf8:
            self.placeholder.text = "Hello, ICON!"
            
        case .hex:
            self.placeholder.text = "0x1234"
        }
        if let saved = savedData {
            textView.text = saved
            textView.isEditable = false
            self.doneButton.setTitle("Common.Modify".localized, for: .normal)
        } else {
            textView.isEditable = true
            self.doneButton.setTitle("Common.Done".localized, for: .normal)
        }
        
        self.textChanged()
    }
    
    func initializeUI() {
        self.navTitle.text = "Transfer.DataTitle".localized
        self.lengthLabel.text = "0"
        self.textView.text = nil
        self.textView.delegate = self
        self.typeLabel.text = self.type == .utf8 ? "UTF-8" : "HEX"
        self.doneButton.setTitleColor(UIColor.white, for: .normal)
        self.doneButton.setTitleColor(UIColor(179, 179, 179), for: .disabled)
    }
    
    func initialize() {
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            if let text = self.textView.text, text != "" {
                Alert.Confirm(message: "Transfer.Data.Cancel".localized, cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: { [unowned self] in
                    self.dismiss(animated: true, completion: nil)
                }, nil).show(self)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
            
            
        }).disposed(by: disposeBag)
        
        doneButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            if self.savedData != nil && self.isModify == false {
                self.isModify = true
                self.textView.isEditable = true
                self.textView.becomeFirstResponder()
                self.doneButton.setTitle("Common.Done".localized, for: .normal)
                return
            }
            
            guard let text = self.textView.text, text != "" else {
                return
            }
            
            var encoded = text
            
            if self.type == .hex {
                let set = CharacterSet(charactersIn: "0123456789ABCDEF").inverted
                
                guard text.prefix0xRemoved().uppercased().rangeOfCharacter(from: set) == nil, text.prefix0xRemoved().hexToData() != nil else {
                    Alert.Basic(message: "Error.InputData".localized).show(self)
                    return
                }
            } else {
                guard let hexData = text.data(using: .utf8) else {
                    Alert.Basic(message: "Error.InputData".localized).show(self)
                    return
                }
                encoded = hexData.hexEncodedString()
            }
            
            let length = encoded.bytes.count
            guard length <= 250 * 1024 else {
                Alert.Basic(message: String(format: "Error.Data.Exceeded".localized, 250)).show(self)
                return
            }
            
            guard let costs = self.costs, let amount = self.walletAmount, let stepPrice = self.stepPrice else { return }
            guard let stepDefault = BigUInt(costs.defaultValue.prefix0xRemoved(), radix: 16) else { return }
            let stepLimit = 2 * stepDefault * stepPrice
            
            var sendValue = BigUInt(0)
            if let send = self.sendAmount {
                sendValue = send
            }
            Log.Debug("amount - \(amount) , stepLimit - \(stepLimit) , sendValue - \(sendValue)")
            if amount > sendValue, stepLimit > (amount - sendValue) {
                Alert.Basic(message: "Error.Transfer.InsufficientFee.ICX".localized).show(self)
                return
            }
            
            self.textView.resignFirstResponder()
            
            if let handler = self.handler{
                handler(text)
            }
            
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        keyboardHeight().observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] (height: CGFloat) in
            var keyHeight: CGFloat = height
            if #available(iOS 11.0, *) {
                keyHeight = height - self.view.safeAreaInsets.bottom
            }
            self.bottomConstraint.constant = keyHeight
        }).disposed(by: disposeBag)
        
        textView.rx.didChange.observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] in
            self.textChanged()
        }).disposed(by: disposeBag)
        
        textView.rx.text.map { $0!.length > 0 }.subscribe(onNext: {
            self.placeholder.isHidden = $0
            self.doneButton.isEnabled = ($0 && self.costs != nil)
        }).disposed(by: disposeBag)
    }
    
    func textChanged() {
        if let inputString = self.textView.text {
            let length = Float(inputString.bytes.count) / 1024.0
            self.lengthLabel.textColor = UIColor.black
            
            if length < 1.0 {
                self.lengthLabel.text = String(format: "%d", inputString.bytes.count) + "B"
            } else {
                self.lengthLabel.text = String(format: "%.0f", length) + "KB"
                
                if length > 250 * 1024 {
                    self.lengthLabel.textColor = UIColor.red
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if savedData == nil {
            self.textView.becomeFirstResponder()
        }
    }
}


extension ICXDataInputViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let former = textView.text as NSString? else { return false }
        let value = former.replacingCharacters(in: range, with: text)
        guard let hexData = value.data(using: .utf8) else { return false }
        let hexEncoded = hexData.hexEncodedString()
        let count = hexEncoded.bytes.count
        if count > 250 * 1024 {
            Alert.Basic(message: String(format: "Error.Data.Exceeded".localized, 250)).show(self)
            return false
        }
        
        
        return true
    }
}
