//
//  Popable.swift
//  iconex_ios
//
//  Created by a1ahn on 30/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import PanModal

class PopableViewController: BaseViewController {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var actionContainer: UIView!
    
    override func initializeComponents() {
        super.initializeComponents()
        
        actionContainer.backgroundColor = .gray250
        actionContainer.alpha = 0.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showBottom()
    }
    
    func showBottom() {
        UIView.animate(withDuration: 0.4) {
            self.actionContainer.alpha = 1.0
        }
    }
    
    func pop(_ viewController: UIViewController? = nil) {
        if let source = viewController {
            source.presentPanModal(self)
        } else {
            app.topViewController()?.presentPanModal(self)
        }
    }
}

extension PopableViewController: PanModalPresentable {
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
        return UIApplication.shared.statusBarFrame.height
    }
    
    var backgroundAlpha: CGFloat {
        return 0.4
    }
}
