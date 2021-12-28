//
//  SwapConfirmViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit

class SwapConfirmViewController: BaseViewController {
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var detailButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
    }
    
    func initialize() {
        alertView.corner(12)
        messageLabel.text = "Alert.Swap.Completed".localized
        let attr = NSAttributedString(string: "Alert.Swap.Policy".localized, attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .bold), .foregroundColor: UIColor(68, 136, 230), .underlineStyle: NSUnderlineStyle.single.rawValue])
        detailButton.setAttributedTitle(attr, for: .normal)
        detailButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: {
            guard let faqURL = URL(string: Config.faqLink) else { return }
            UIApplication.shared.open(faqURL, options: [:], completionHandler: nil)
        }).disposed(by: disposeBag)
        
        confirmButton.styleDark()
        confirmButton.setTitle("Common.Confirm".localized, for: .normal)
        confirmButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
