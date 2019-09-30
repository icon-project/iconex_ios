//
//  BaseViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 25/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BaseViewController: UIViewController, UINavigationControllerDelegate, UIGestureRecognizerDelegate, Scrollable {
    @IBOutlet weak var scrollView: UIScrollView?
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        setKeyboardListener()
        initializeComponents()
    }
    
    func initializeComponents() {
        
    }
    
    func refresh() {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
}

protocol Scrollable {
    
}

extension Scrollable where Self: BaseViewController {
    func setKeyboardListener() {
        keyboardHeight().asObservable().subscribe(onNext: { height in
            if height == 0 {
                self.scrollView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            } else {
                let keyboardHeight = height - (self.view.safeAreaInsets.bottom + 54)
                self.scrollView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
            }
        }).disposed(by: disposeBag)
    }
}
