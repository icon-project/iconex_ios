//
//  SendInfoViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 30/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SendInfoViewController: PopableViewController {
//    @IBOutlet weak var textView: UITextView!
    private var textView: UITextView!
    @IBOutlet weak var closeButton: UIButton!
    
    var type: String = "icx"

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
        tv.topAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: 20).isActive = true
        tv.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        tv.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        tv.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -66).isActive = true
        tv.bottomAnchor.constraint(equalTo: actionContainer.topAnchor).isActive = true
        self.textView = tv
        
        titleContainer.actionHandler = {
            self.dismiss(animated: true, completion: nil)
        }
        titleContainer.set(title: "Send.Info.Title".localized)
        
        textView.text = type == "icx" ? "Send.Info.ICX".localized : "Send.Info.ETH".localized
        textView.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        
        closeButton.gray77round()
        closeButton.setTitle("Common.Close".localized, for: .normal)
        
        closeButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
    }
}
