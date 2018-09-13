//
//  ICXDataInputViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ICXDataInputViewController: BaseViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var stepView: UIView!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var lengthLabel: UILabel!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var handler: ((String) -> Void)?
    var type: Int = 0
    
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
    
    func initializeUI() {
        self.navTitle.text = "Transfer.DataTitle".localized
        self.doneButton.setTitle("Common.Done".localized, for: .normal)
        self.lengthLabel.text = "0"
        self.textView.text = nil
        
        self.typeLabel.text = self.type == 0 ? "UTF-8" : "HEX"
    }
    
    func initialize() {
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        doneButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            if let handler = self.handler, let text = self.textView.text {
                handler(text)
            }
            
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        keyboardHeight().observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] (height: CGFloat) in
            self.bottomConstraint.constant = height
        }).disposed(by: disposeBag)
        
        textView.rx.didChange.observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] in
            if let inputString = self.textView.text {
                let length = Float(inputString.bytes.count) / 1024.0
                Log.Debug("length - \(inputString.bytes.count)")
                if length < 1.0 {
                    self.lengthLabel.text = String(format: "%d", inputString.bytes.count) + "B"
                } else {
                    self.lengthLabel.text = String(format: "%.0f", length) + "KB"
                }
            }
        }).disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.textView.becomeFirstResponder()
    }
}
