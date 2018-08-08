//
//  SwapStepView2.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit

class SwapStepView2: UIView {
    
    @IBOutlet weak var stepImage2_1: UIImageView!
    @IBOutlet weak var stepImage2_2: UIImageView!
    @IBOutlet weak var stepLabel2_1: UILabel!
    @IBOutlet weak var stepLabel2_2: UILabel!
    @IBOutlet weak var slider2: UISlider!
    
    var step: SwapStepView.SwapStep = .step1_1 {
        willSet {
            switch newValue {
            case .step1_1, .step1_2:
                stepImage2_1.image = #imageLiteral(resourceName: "icStep01On")
                stepImage2_2.image = #imageLiteral(resourceName: "icStep02")
                stepLabel2_1.textColor = UIColor.Step.current.text
                stepLabel2_2.textColor = UIColor.Step.standBy.text
                slider2.value = 0.0
                
            case .step2:
                stepImage2_1.image = #imageLiteral(resourceName: "icStepCheck")
                stepImage2_2.image = #imageLiteral(resourceName: "icStep02On")
                stepLabel2_1.textColor = UIColor.Step.checked.text
                stepLabel2_2.textColor = UIColor.Step.current.text
                slider2.value = 1.0
                
            default:
                break
            }
        }
    }
    
    func initializeUI() {
        stepLabel2_1.text = "Swap.Step.Step1.Title".localized
        stepLabel2_2.text = "Swap.Step.Step5.Title".localized
        slider2.minimumTrackTintColor = UIColor.Step.checked.line
        slider2.maximumTrackTintColor = UIColor.Step.standBy.line
        slider2.setThumbImage(UIImage(), for: .normal)
        slider2.maximumValue = 1.0
        slider2.minimumValue = 0.0
    }
    
    func initialize() {
        step = .step1_2
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
        let nibName = "SwapStepView2"
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle).instantiate(withOwner: self, options: nil)
        return nib.first as? UIView
    }
}
