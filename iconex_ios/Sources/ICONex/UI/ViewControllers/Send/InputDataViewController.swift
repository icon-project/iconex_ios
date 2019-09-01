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

class InputDataViewController: UIViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    var type: Int = 0
    var data: String = ""
    
    var isEditMode: Bool = false
    
    var completeHandler: ((_ data: String) -> Void)?
    
    var disposeBag = DisposeBag()
    
    let toolBar: IXKeyboardToolBar = IXKeyboardToolBar(frame: CGRect(x: 0, y: 0, width: .max, height: 102))

    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolBar.dataType = self.type
        self.textView.inputAccessoryView = toolBar
        
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
        confirmButton.setTitle("Common.Change".localized, for: .normal)
        
        if self.type == 0 {
            self.placeholderLabel.text = "Hello ICON"
        } else {
            self.placeholderLabel.text = "0x1234…"
        }
    }
    
    private func setupBind() {
        closeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                if self.textView.text.isEmpty {
                   self.dismiss(animated: true, completion: nil)
                } else {
                    Alert.basic(title: "Send.InputData.Alert.Cancel".localized, isOnlyOneButton: false, confirmAction: {
                        self.dismiss(animated: true, completion: nil)
                    }).show()
                }
        }.disposed(by: disposeBag)
        
        textView.rx.didBeginEditing.asControlEvent()
            .subscribe { (_) in
                self.placeholderLabel.isHidden = true
        }.disposed(by: disposeBag)
        
        let textViewShare = textView.rx.text.orEmpty.share(replay: 1)
        
        textViewShare.scan("") { (previous, new) -> String in
            guard !new.isEmpty else { return new }
            if new.lengthOfBytes(using: .utf8) > 500 {
                return previous
            } else {
                return new
            }
        }.bind(to: textView.rx.text)
        .disposed(by: disposeBag)
        
        textViewShare
            .subscribe(onNext: { (text) in
                self.placeholderLabel.isHidden = !text.isEmpty
                let textLength = text.utf8.count
                self.toolBar.kbLabel.text = "\(textLength)"
                
            }).disposed(by: disposeBag)
        
        textViewShare.map { !$0.isEmpty }
            .bind(to: self.toolBar.completeButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        toolBar.completeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                
            }.disposed(by: disposeBag)
        
        confirmButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                if self.isEditMode {
                    self.textView.text = ""
                }
                self.isEditMode = true
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
