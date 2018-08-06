//
//  SwapStepView.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit

class SwapStepView: UIView {
    enum SwapStep {
        case step1_1
        case step1_2
        case step2
        case step3
        case step4
        case step5
    }
    
    @IBOutlet var stepImage1: UIImageView!
    @IBOutlet var stepImage2: UIImageView!
    @IBOutlet var stepImage3: UIImageView!
    @IBOutlet var stepImage4: UIImageView!
    @IBOutlet var stepImage5: UIImageView!
    @IBOutlet var stepLabel1: UILabel!
    @IBOutlet var stepLabel2: UILabel!
    @IBOutlet var stepLabel3: UILabel!
    @IBOutlet var stepLabel4: UILabel!
    @IBOutlet var stepLabel5: UILabel!
    @IBOutlet var slider: UISlider!
    
    var step: SwapStep = .step1_1 {
        willSet {
            switch newValue {
            case .step1_1, .step1_2:
                stepImage1.image = #imageLiteral(resourceName: "icStep01On")
                stepImage2.image = #imageLiteral(resourceName: "icStep02")
                stepImage3.image = #imageLiteral(resourceName: "icStep03")
                stepImage4.image = #imageLiteral(resourceName: "icStep04")
                stepImage5.image = #imageLiteral(resourceName: "icStep05")
                stepLabel1.textColor = UIColor.Step.current.text
                stepLabel2.textColor = UIColor.Step.standBy.text
                stepLabel3.textColor = UIColor.Step.standBy.text
                stepLabel4.textColor = UIColor.Step.standBy.text
                stepLabel5.textColor = UIColor.Step.standBy.text
                slider.value = 0.0
                
            case .step2:
                stepImage1.image = #imageLiteral(resourceName: "icStepCheck")
                stepImage2.image = #imageLiteral(resourceName: "icStep02On")
                stepImage3.image = #imageLiteral(resourceName: "icStep03")
                stepImage4.image = #imageLiteral(resourceName: "icStep04")
                stepImage5.image = #imageLiteral(resourceName: "icStep05")
                stepLabel1.textColor = UIColor.Step.checked.text
                stepLabel2.textColor = UIColor.Step.current.text
                stepLabel3.textColor = UIColor.Step.standBy.text
                stepLabel4.textColor = UIColor.Step.standBy.text
                stepLabel5.textColor = UIColor.Step.standBy.text
                slider.value = 0.25
                
            case .step3:
                stepImage1.image = #imageLiteral(resourceName: "icStepCheck")
                stepImage2.image = #imageLiteral(resourceName: "icStepCheck")
                stepImage3.image = #imageLiteral(resourceName: "icStep03On")
                stepImage4.image = #imageLiteral(resourceName: "icStep04")
                stepImage5.image = #imageLiteral(resourceName: "icStep05")
                stepLabel1.textColor = UIColor.Step.checked.text
                stepLabel2.textColor = UIColor.Step.checked.text
                stepLabel3.textColor = UIColor.Step.current.text
                stepLabel4.textColor = UIColor.Step.standBy.text
                stepLabel5.textColor = UIColor.Step.standBy.text
                slider.value = 0.5
                
            case .step4:
                stepImage1.image = #imageLiteral(resourceName: "icStepCheck")
                stepImage2.image = #imageLiteral(resourceName: "icStepCheck")
                stepImage3.image = #imageLiteral(resourceName: "icStepCheck")
                stepImage4.image = #imageLiteral(resourceName: "icStep04On")
                stepImage5.image = #imageLiteral(resourceName: "icStep05")
                stepLabel1.textColor = UIColor.Step.checked.text
                stepLabel2.textColor = UIColor.Step.checked.text
                stepLabel3.textColor = UIColor.Step.checked.text
                stepLabel4.textColor = UIColor.Step.current.text
                stepLabel5.textColor = UIColor.Step.standBy.text
                slider.value = 0.75
                
            case .step5:
                stepImage1.image = #imageLiteral(resourceName: "icStepCheck")
                stepImage2.image = #imageLiteral(resourceName: "icStepCheck")
                stepImage3.image = #imageLiteral(resourceName: "icStepCheck")
                stepImage4.image = #imageLiteral(resourceName: "icStepCheck")
                stepImage5.image = #imageLiteral(resourceName: "icStep05On")
                stepLabel1.textColor = UIColor.Step.checked.text
                stepLabel2.textColor = UIColor.Step.checked.text
                stepLabel3.textColor = UIColor.Step.checked.text
                stepLabel4.textColor = UIColor.Step.checked.text
                stepLabel5.textColor = UIColor.Step.current.text
                slider.value = 1.0
                
            }
        }
    }
    
    func initializeUI() {
        stepLabel1.text = "Swap.Step.Step1.Title".localized
        stepLabel2.text = "Swap.Step.Step2.Title".localized
        stepLabel3.text = "Swap.Step.Step3.Title".localized
        stepLabel4.text = "Swap.Step.Step4.Title".localized
        stepLabel5.text = "Swap.Step.Step5.Title".localized
        slider.minimumTrackTintColor = UIColor.Step.checked.line
        slider.maximumTrackTintColor = UIColor.Step.standBy.line
        slider.setThumbImage(UIImage(), for: .normal)
        slider.maximumValue = 1.0
        slider.minimumValue = 0.0
    }
    
    func initialize() {
        step = .step1_1
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        xibSetup()
    }
    
    func xibSetup() {
        guard let view  = loadViewFromNib() else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        
        initialize()
        initializeUI()
    }
    
    func loadViewFromNib() -> UIView? {
        let nibName = "SwapStepView"
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle).instantiate(withOwner: self, options: nil)
        return nib.first as? UIView
    }
}
