//
//  DisclaimerViewController.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class DisclaimerViewController: UIViewController {
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var alertTitle: UILabel!
    @IBOutlet weak var disclaimerText: UITextView!
    @IBOutlet weak var confirmButton: UIButton!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }
    
    func initialize() {
        
    }
    
    func initializeUI() {
        alertTitle.text = "Side.Disclaimer".localized
        alertView.corner(12)
        let title = NSAttributedString(string: "Disclaimer.Title".localized, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15, weight: .bold)])
        let content = NSAttributedString(string: "Disclaimer.Content".localized, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15, weight: .regular)])
        let text = NSMutableAttributedString(attributedString: title)
        text.append(content)
        disclaimerText.attributedText = text
        
        confirmButton.styleDark()
        confirmButton.setTitle("Common.Confirm".localized, for: .normal)
        confirmButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                self.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        disclaimerText.setContentOffset(.zero, animated: false)
    }
}
