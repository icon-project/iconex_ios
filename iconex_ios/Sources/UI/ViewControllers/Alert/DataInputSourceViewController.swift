//
//  DataInputSourceViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit

class DataInputSourceViewController: BaseViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var sheetTitle: UILabel!
    @IBOutlet weak var typeTitle: UILabel!
    @IBOutlet weak var stackContainer: UIView!
    @IBOutlet weak var utf8Button: UIButton!
    @IBOutlet weak var hexButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var selected: EncodeType = .utf8 {
        willSet {
            switch newValue {
            case .utf8:
                utf8Button.isSelected = true
                utf8Button.backgroundColor = UIColor.black
                utf8Button.setTitleColor(UIColor.white, for: .highlighted)
                hexButton.isSelected = false
                hexButton.backgroundColor = UIColor.white
                hexButton.setTitleColor(UIColor.black, for: .highlighted)
                
            case .hex:
                utf8Button.isSelected = false
                utf8Button.backgroundColor = UIColor.white
                utf8Button.setTitleColor(UIColor.black, for: .highlighted)
                hexButton.isSelected = true
                hexButton.backgroundColor = UIColor.black
                hexButton.setTitleColor(UIColor.white, for: .highlighted)
            }
        }
    }
    
    var handler: ((EncodeType) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initialize() {
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        confirmButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.close(completion: {
                if let handler = self.handler {
                    handler(self.selected)
                }
            })
        }).disposed(by: disposeBag)
        
        utf8Button.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.selected = .utf8
        }).disposed(by: disposeBag)
        
        hexButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.selected = .hex
        }).disposed(by: disposeBag)
        
        self.selected = .utf8
    }
    
    func initializeUI() {
        stackContainer.border(1.0, UIColor.black)
        stackContainer.corner(4)
        
        sheetTitle.text = "Transfer.DataTitle".localized
        confirmButton.setTitle("Common.Confirm".localized, for: .normal)
        typeTitle.text = "Transfer.InputType".localized
        utf8Button.setTitle("UTF-8", for: .normal)
        utf8Button.setTitleColor(UIColor.black, for: .normal)
        utf8Button.setTitleColor(UIColor.white, for: .selected)
        hexButton.setTitle("HEX", for: .normal)
        hexButton.setTitleColor(UIColor.black, for: .normal)
        hexButton.setTitleColor(UIColor.white, for: .selected)
    }
}

extension DataInputSourceViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.15, animations: {
            self.view.alpha = 1.0
        }, completion: { (bool) in
            self.bottomConstraint.constant = 0
            UIView.animate(withDuration: 0.15, animations: {
                self.view.layoutIfNeeded()
            })
        })
    }
    
    func present(from: UIViewController) {
        
        from.present(self, animated: false) {
            self.bottomConstraint.constant = (self.containerView.frame.height + 46)
        }
    }
    
    func close(completion: (() -> Void)? = nil) {
        self.bottomConstraint.constant = CGFloat((containerView.frame.height + 46))
        UIView.animate(withDuration: 0.15, animations: {
            self.view.layoutIfNeeded()
        }) { (bool) in
            UIView.animate(withDuration: 0.15, animations: {
                self.view.alpha = 0.0
            }) { (bool) in
                self.dismiss(animated: false, completion: {
                    if let handler = completion {
                        handler()
                    }
                })
            }
        }
    }
}
