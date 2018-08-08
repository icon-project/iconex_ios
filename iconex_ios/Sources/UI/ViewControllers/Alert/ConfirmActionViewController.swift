
//
//  ConfirmActionViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ConfirmActionViewController: UIViewController {

    @IBOutlet weak var alertContainer: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    var message: String?
    var confirmTitle: String?
    var cancelTitle: String?
    var handler: (() -> Void)?
    var cancel: (() -> Void)?
    
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
        alertContainer.corner(12)
        
        cancelButton.styleDark()
        cancelButton.setTitle(cancelTitle ?? "Common.Cancel".localized, for: .normal)
        confirmButton.styleLight()
        confirmButton.setTitle(confirmTitle ?? "Common.Confirm".localized, for: .normal)
        
        cancelButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [weak self] in
                if let cancel = self?.cancel {
                    cancel()
                }
                self?.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
        
        confirmButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: {
                    if let completion = self?.handler {
                        completion()
                    }
                })
            }).disposed(by: disposeBag)
        
        self.messageLabel.text = message
    }
    
    func addMessage(message: String?) {
        self.message = message
    }
    
    func addConfirm(action: (() -> Void)?) {
        self.handler = action
    }
}
