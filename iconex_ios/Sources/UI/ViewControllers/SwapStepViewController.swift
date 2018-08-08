//
//  SwapStepViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit

class SwapStepViewController: BaseViewController {
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var stepView: SwapStepView!
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
        step1.delegate = self
        let step2 = childViewControllers[1] as! SwapStepTwoViewController
        step2.delegate = self
        let step3 = childViewControllers[2] as! SwapStepThreeViewController
        step3.delegate = self
        let step4 = childViewControllers[3] as! SwapStepFourViewController
        step4.delegate = self
        let step5 = childViewControllers[4] as! SwapStepFiveViewController
        step5.delegate = self
        
        changeStep(to: .step1_1)
        
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.view.endEditing(true)
            let confirm = {
                SwapManager.sharedInstance.reset()
                self.dismiss(animated: true, completion: nil)
            }
            if self.stepView.step == .step5 {
                Alert.Confirm(message: "Alert.Swap.CancelSwap".localized, cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: confirm, nil).show(self)
            } else {
                Alert.Confirm(message: "Alert.Swap.CancelCreate".localized, cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: confirm, nil).show(self)
            }
        }).disposed(by: disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

protocol SwapStepDelegate {
    func currentIndex() -> SwapStepView.SwapStep
    func changeStep(to: SwapStepView.SwapStep)
}

extension SwapStepViewController: SwapStepDelegate {
    func currentIndex() -> SwapStepView.SwapStep {
        return stepView.step
    }
    
    func changeStep(to: SwapStepView.SwapStep) {
        var offsetX: CGFloat = 0
        switch to {
        case .step1_1:
            let step = "Swap.Step.Step1.Title".localized + "\n 1/2"
            stepView.stepLabel1.text = step
            offsetX = 0
            
        case .step1_2:
            let step = "Swap.Step.Step1.Title".localized + "\n 2/2"
            stepView.stepLabel1.text = step
            offsetX = 0
            
        case .step2:
            navTitle.text = "Swap.NavTitle.2".localized
            offsetX = 1
            
        case .step3:
            navTitle.text = "Swap.NavTitle.2".localized
            offsetX = 2
            
        case .step4:
            navTitle.text = "Swap.NavTitle.2".localized
            let step4 = childViewControllers[3] as! SwapStepFourViewController
            step4.newPrivateKey = WCreator.newPrivateKey
            offsetX = 3
            
        case .step5:
            navTitle.text = "Swap.NavTitle.3".localized
            offsetX = 4
        }
        
        stepView.step = to
        
        scrollView.setContentOffset(CGPoint(x: offsetX * view.frame.width, y: 0), animated: true)
    }
}
