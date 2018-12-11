//
//  CreateStepViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol CreateStepDelegate {
    
    func nextStep(currentStep: CreateStep)
    func prevStep(currentStep: CreateStep)
    
}

class CreateStepViewController: UIViewController, UIScrollViewDelegate, CreateStepDelegate {
    
    @IBOutlet weak var topTitle: UILabel!
    @IBOutlet weak var stepView: WalletCreateStepView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    private var stepTwoController: StepTwoViewController!
    private var stepFourController: StepFourViewController!
    
    var isLaunched: Bool = true
    
    var currentStep: CreateStep!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        initialize()
        initializeUI()
    }
    
    func initialize() {
        if let stepOne = children[0] as? StepOneViewController {
            stepOne.delegate = self
        }
        
        if let stepTwo = children[1] as? StepTwoViewController {
            stepTwo.delegate = self
            stepTwoController = stepTwo
        }
        
        if let stepThree = children[2] as? StepThreeViewController {
            stepThree.delegate = self
        }
        
        if let stepFour = children[3] as? StepFourViewController {
            stepFourController = stepFour
        }
        self.currentStep = .one
        
        keyboardHeight().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] (height: CGFloat) in
                if height == 0 {
                    self.topConstraint.constant = 0
                } else {
                    self.topConstraint.constant = -(self.stepView.frame.height)
                }
                
                UIView.animate(withDuration: 0.25, animations: {
                    self.view.layoutIfNeeded()
                })
            }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        self.topTitle.text = Localized(key: "Wallet.Create")
        self.stepView.setStep(step: .one)
    }
    
    @IBAction func clickedBack(_ sender: Any) {
        self.view.endEditing(true)
        if self.currentStep != .one {
            let confirmAction = Alert.Confirm(message: "Alert.CreateCancel".localized, cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: { [weak self] in
                WCreator.resetData()
                self?.dismiss(animated: true, completion: nil)
            })
            
            self.present(confirmAction, animated: true, completion: nil)
        } else {
            WCreator.resetData()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scroll(to: Int) {
        
        // scroll to step four
        if let type = WCreator.newType, to == 3 {
            switch type {
            case .icx:
                let prvKey = WCreator.newPrivateKey!
                stepFourController.newPrivateKey = prvKey
                
            case .eth:
                let prvKey = WCreator.newPrivateKey!
                stepFourController.newPrivateKey = prvKey
                
            default:
                break
            }
        }
        
        scrollView.setContentOffset(CGPoint(x: scrollView.frame.size.width * CGFloat(to), y: 0), animated: true)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
//        if scrollView.contentOffset.x == self.scrollView.frame.size.width * 3 {
//
//        }
    }
}

extension CreateStepDelegate where Self: CreateStepViewController {

    func prevStep(currentStep: CreateStep) {
        switch currentStep {
        case .two, .three:
            let level = currentStep.rawValue - 1
            scroll(to: level)
            let willStep = CreateStep(rawValue: level)!
            stepView.setStep(step: willStep)
            self.currentStep = willStep
            
        default:
            break;
        }
    }
    
    func nextStep(currentStep: CreateStep) {
        switch currentStep {
        case .one, .two, .three:
            let level = currentStep.rawValue + 1
            scroll(to: level)
            let willStep = CreateStep(rawValue: level)!
            stepView.setStep(step: willStep)
            self.currentStep = willStep
            
        default:
            break
        }
    }
    
}
