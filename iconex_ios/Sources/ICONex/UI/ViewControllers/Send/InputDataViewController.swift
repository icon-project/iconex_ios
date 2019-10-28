//
//  InputDataViewController.swift
//  iconex_ios
//
//  Created by Seungyeon Lee on 2019/09/01.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PanModal

enum InputType {
    case utf8, hex
}

class InputDataViewController: BaseViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    var type: InputType = .utf8
    var data: String = ""
    
    var isViewMode: Bool = false
    var isEditingMode: Bool = false
    
    var completeHandler: ((_ data: String?, _ dataType: InputType) -> Void)?
    
    var delegate: SendDelegate!
    
    let toolBar: IXKeyboardToolBar = IXKeyboardToolBar(frame: CGRect(x: 0, y: 0, width: .max, height: 102))

    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolBar.dataType = self.type
        self.textView.inputAccessoryView = toolBar
        
        if !self.data.isEmpty {
            self.textView.text = self.data
        }
        
        if self.isViewMode {
            self.textView.isEditable = false
            self.textView.isSelectable = false
        }
        
        if type == .hex {
            self.textView.keyboardType = .asciiCapable
        }
        
        setupUI()
        setupBind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.data.isEmpty {
            textView.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textView.endEditing(true)
    }
    
    private func setupUI() {
        titleLabel.size18(text: "Send.DataType.Title".localized, color: .gray77, weight: .medium, align: .center)
        
        confirmButton.isHidden = data.isEmpty
        confirmButton.setTitle("Common.Modify".localized, for: .normal)
        
        if self.type == .utf8 {
            self.placeholderLabel.text = "Hello ICON"
        } else {
            self.placeholderLabel.text = "0x1234…"
        }
        textView.delegate = self
    }
    
    private func setupBind() {
        
        keyboardHeight().observeOn(MainScheduler.instance)
        .subscribe(onNext: { [unowned self] (height: CGFloat) in
            if height == 0 {
                self.textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            } else {
                let keyboardHeight: CGFloat = height - self.view.safeAreaInsets.bottom
                self.textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
            }
        }).disposed(by: disposeBag)
        
        closeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                if self.textView.text.isEmpty || self.isEditingMode || self.isViewMode {
                   self.dismiss(animated: true, completion: nil)
                } else {
                    Alert.basic(title: "Send.InputData.Alert.Cancel".localized, isOnlyOneButton: false, leftButtonTitle: "Common.No".localized, rightButtonTitle: "Common.Yes".localized, confirmAction: {
                        self.dismiss(animated: true, completion: nil)
                    }).show()
                }
        }.disposed(by: disposeBag)
        
        let textViewShare = textView.rx.text.orEmpty.share(replay: 1)
        
        textViewShare
            .subscribe(onNext: { (text) in
                self.placeholderLabel.isHidden = !text.isEmpty
                let byte = Int64(text.lengthOfBytes(using: .utf8))

                guard byte <= 524288 else {
                    var prompted = text
                    while prompted.lengthOfBytes(using: .utf8) > 524288 {
                        prompted.removeLast()
                    }
                    self.textView.text = String(prompted)
                    return
                }

                let textLength: String = {
                    var roundedByte = byte / 1024

                    if byte % 1024 != 0 {
                        roundedByte += 1
                    }

                    roundedByte = roundedByte * 1024

                    let byteFormatter = ByteCountFormatter()
                    byteFormatter.countStyle = .binary
                    byteFormatter.allowedUnits = .useKB

                    let kb = byteFormatter.string(fromByteCount: roundedByte)
                    return kb
                }()

                self.toolBar.kbLabel.text = textLength

            }).disposed(by: disposeBag)
        
        textViewShare.map { !$0.isEmpty }
            .bind(to: self.toolBar.completeButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        toolBar.completeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let text = self.textView.text ?? ""
                if let handler = self.completeHandler {
                    handler(text, self.type)
                }
                self.dismiss(animated: true, completion: nil)
            }.disposed(by: disposeBag)
        
        confirmButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                if self.isEditingMode {
                    Alert.basic(title: "Send.InputData.Alert.Delete".localized, isOnlyOneButton: false, leftButtonTitle: "Common.No".localized, rightButtonTitle: "Common.Yes".localized, confirmAction: {
                        self.textView.text = ""
                        if let handler = self.completeHandler {
                            handler(nil, self.type)
                        }
                        self.dismiss(animated: true, completion: nil)
                    }).show()
                }
                self.textView.isSelectable = true
                self.textView.isEditable = true
                self.textView.becomeFirstResponder()
                self.isEditingMode = true
                self.confirmButton.setTitle("Common.Remove".localized, for: .normal)
                
        }.disposed(by: disposeBag)
    }
}

extension InputDataViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    func shouldRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return false
    }
    
    var isHapticFeedbackEnabled: Bool {
        return false
    }
    
    var topOffset: CGFloat {
        return app.window!.safeAreaInsets.top
    }
    
    var backgroundAlpha: CGFloat {
        return 0.4
    }
    
    var cornerRadius: CGFloat {
        return 18.0
    }
}

extension InputDataViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let former = textView.text as NSString? else { return false }
        let replaced = former.replacingCharacters(in: range, with: text)
        
        let byte = Int64(replaced.lengthOfBytes(using: .utf8))
        guard byte <= 524288 else { return false }
        return true
    }
}
