//
//  CreateWalletViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 01/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class CreateWalletViewController: PopableViewController {
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    @IBOutlet weak var stepScrollView: UIScrollView!
    
    var scrollIndex: Int = 0 {
        willSet {
            var leftTitle: String = "Common.Back".localized
            var rightTitle: String = "Common.Next".localized
            switch newValue {
            case 0:
                leftTitle = "Common.Cancel".localized
                
            case 3:
                rightTitle = "Common.Complete".localized
                
            default:
                leftTitle = "Common.Back".localized
                rightTitle = "Common.Next".localized
            }
            leftButton.setTitle(leftTitle, for: .normal)
            rightButton.setTitle(rightTitle, for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        scrollIndex = 0
        
        stepScrollView.rx.didEndScrollingAnimation.subscribe(onNext: { [unowned self] in
            self.scrollIndex = (Int)(self.stepScrollView.contentOffset.x / self.view.frame.width)
        }).disposed(by: disposeBag)
        
        leftButton.rx.tap.subscribe(onNext: { [unowned self] in
            switch self.scrollIndex {
            case 0:
                self.dismiss(animated: true, completion: nil)
                
            default:
                let value = (CGFloat)(self.scrollIndex - 1)
                let x = value * self.view.frame.width
                self.stepScrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
            }
        }).disposed(by: disposeBag)
        
        rightButton.rx.tap.subscribe(onNext: { [unowned self] in
            switch self.scrollIndex {
            case 3:
                self.dismiss(animated: true, completion: nil)
                
            default:
                let value = (CGFloat)(self.scrollIndex + 1)
                let x = value * self.view.frame.width
                self.stepScrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
            }
        }).disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        
        titleContainer.set(title: "Wallet.Create".localized)
        titleContainer.actionHandler = {
            self.dismiss(animated: true, completion: nil)
        }
        
        leftButton.round02()
        rightButton.lightMintRounded()
    }
}
