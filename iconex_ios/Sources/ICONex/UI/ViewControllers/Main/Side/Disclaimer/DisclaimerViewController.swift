//
//  DisclaimerViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 01/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class DisclaimerViewController: PopableViewController {
//    @IBOutlet weak var textView: UITextView!
    private var textView: UITextView!
    @IBOutlet weak var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        let tv = UITextView()
        tv.showsVerticalScrollIndicator = false
        tv.showsHorizontalScrollIndicator = false
        tv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tv)
        tv.topAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: 30).isActive = true
        tv.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30).isActive = true
        tv.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30).isActive = true
        tv.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -66).isActive = true
        tv.bottomAnchor.constraint(equalTo: actionContainer.topAnchor).isActive = true
        self.textView = tv
        
        titleContainer.set(title: "Side.Disclaimer".localized)
        titleContainer.actionHandler = {
            self.dismiss(animated: true, completion: nil)
        }
        
        let title = NSAttributedString(string: "Disclaimer.Title".localized, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .bold)])
        let content = NSAttributedString(string: "Disclaimer.Content".localized, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .regular)])
        let text = NSMutableAttributedString(attributedString: title)
        text.append(content)
        textView.attributedText = text
        
        closeButton.round02()
        closeButton.setTitle("Common.Close".localized, for: .normal)
        closeButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }
}
