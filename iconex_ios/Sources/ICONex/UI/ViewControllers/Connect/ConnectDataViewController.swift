//
//  ConnectDataViewController.swift
//  iconex_ios
//
//  Created by Seungyeon Lee on 2019/09/08.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PanModal

class ConnectDataViewController: BaseViewController {

    @IBOutlet weak var navBar: PopableTitleView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var closeButton: UIButton!
    
    var dataString: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBar.set(title: "Tx Data")
        navBar.actionHandler = {
            self.dismiss(animated: true, completion: nil)
        }
        
        textView.isUserInteractionEnabled = false
        textView.text = dataString
        
        closeButton.setTitle("Common.Close".localized, for: .normal)
        closeButton.round02()
        closeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
    }
}

extension ConnectDataViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    func shouldRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return false
    }
    
    var isHapticFeedbackEnabled: Bool {
        return false
    }
    
    var topOffset: CGFloat {
        return app.window!.safeAreaInsets.top
    }
    
    var backgroundAlpha: CGFloat {
        return 0.4
    }
    
    var cornerRadius: CGFloat {
        return 18.0
    }
}
