//
//  BasicActionViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BasicActionViewController: UIViewController {
    @IBOutlet weak private var alertView: UIView!
    @IBOutlet weak private var messageLabel: UILabel!
    @IBOutlet weak private var confirmButton: UIButton!
    
    var handler: (() -> Void)?
    
    var message: String?
    var attrMessage: NSAttributedString?
    var alignment: NSTextAlignment = .center
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initialize() {
        alertView.corner(12)
        confirmButton.styleDark()
        confirmButton.setTitle("Common.Confirm".localized, for: .normal)
        
        confirmButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: {
                    if let completion = self?.handler {
                        completion()
                    }
                })
            }).disposed(by: disposeBag)
        
        if let attr = self.attrMessage {
            messageLabel.attributedText = attr
        } else {
            messageLabel.text = message
        }
        
        messageLabel.textAlignment = alignment
    }
    
    func setAlignment(_ alignment: NSTextAlignment) {
        self.alignment = alignment
    }

}
