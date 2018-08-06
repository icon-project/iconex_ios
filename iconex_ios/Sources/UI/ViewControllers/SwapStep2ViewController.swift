//
//  SwapStep2ViewController.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit

class SwapStep2ViewController: BaseViewController {
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var stepView: SwapStepView2!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }
    
    func initializeUI() {
        navTitle.text = "Swap.NavTitle.1".localized
    }
    
    func initialize() {
        let step1 = childViewControllers[0] as! SwapStepOneViewController
        step1.set2()
        step1.delegate = self
        let step5 = childViewControllers[1] as! SwapStepFiveViewController
        step5.delegate = self
        
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.view.endEditing(true)
            let confirm = {
                SwapManager.sharedInstance.reset()
                self.dismiss(animated: true, completion: nil)
            }
            Alert.Confirm(message: "Alert.Swap.CancelSwap".localized, cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: confirm, nil).show(self)
            
        }).disposed(by: disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}


extension SwapStep2ViewController: SwapStepDelegate {
    func currentIndex() -> SwapStepView.SwapStep {
        return stepView.step
    }
    
    func changeStep(to: SwapStepView.SwapStep) {
        var offsetX: CGFloat = 0
        switch to {
        case .step1_1 ,.step1_2:
            navTitle.text = "Swap.NavTitle.1".localized
            offsetX = 0
            
        case .step2:
            navTitle.text = "Swap.NavTitle.3".localized
            offsetX = 1
            
        default:
            break
        }
        
        stepView.step = to
        
        scrollView.setContentOffset(CGPoint(x: offsetX * view.frame.width, y: 0), animated: true)
    }
}
