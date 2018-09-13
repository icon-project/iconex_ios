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
    @IBOutlet weak var utf8Button: UIButton!
    @IBOutlet weak var hexButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var selected = 0
    
    var handler: ((Int) -> Void)?
    
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
            self.dismiss(animated: true, completion: {
                if let handler = self.handler {
                    handler(self.selected)
                }
            })
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        
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
