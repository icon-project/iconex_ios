//
//  DisclaimerViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class DisclaimerViewController: BaseViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var disclaimerText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }
    
    func initialize() {
        closeButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        navTitle.text = "Side.Disclaimer".localized
        
        let title = NSAttributedString(string: "Disclaimer.Title".localized, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .bold)])
        let content = NSAttributedString(string: "Disclaimer.Content".localized, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .regular)])
        let text = NSMutableAttributedString(attributedString: title)
        text.append(content)
        disclaimerText.attributedText = text
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
