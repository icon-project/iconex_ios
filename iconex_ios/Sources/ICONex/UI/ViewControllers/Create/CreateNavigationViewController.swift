//
//  CreateNavigationViewController.swift
//  iconex_ios
//
//  Created by sweepty on 09/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import PanModal
import RxSwift
import RxCocoa

class CreateNavigationViewController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.isHidden = true
        
        let nextVC = UIStoryboard(name: "CreateWallet", bundle: nil).instantiateViewController(withIdentifier: "Create") as! CreateWalletViewController
        
        pushViewController(nextVC, animated: true)
        
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        let vc = super.popViewController(animated: animated)
        panModalSetNeedsLayoutUpdate()
        return vc
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        panModalSetNeedsLayoutUpdate()
    }

}

extension CreateNavigationViewController: PanModalPresentable {
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
