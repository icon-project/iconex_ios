//
//  WalletCreateStepView.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit

enum CreateStep: Int {
    case one = 0, two, three, four
}

@IBDesignable class WalletCreateStepView: UIView {
    
    @IBInspectable var nibName: String?
    
    @IBOutlet weak var stepOneImage: UIImageView!
    @IBOutlet weak var stepTwoImage: UIImageView!
    @IBOutlet weak var stepThreeImage: UIImageView!
    @IBOutlet weak var stepFourImage: UIImageView!
    
    @IBOutlet weak var stepOneLabel: UILabel!
    @IBOutlet weak var stepTwoLabel: UILabel!
    @IBOutlet weak var stepThreeLabel: UILabel!
    @IBOutlet weak var stepFourLabel: UILabel!
    
    @IBOutlet weak var line1: UIView!
    @IBOutlet weak var line2: UIView!
    @IBOutlet weak var line3: UIView!
    var contentView: UIView?
    private var currentStep: CreateStep = .one {
        willSet {
            
            switch newValue {
            case .one:
                stepOneImage.image = #imageLiteral(resourceName: "icStep01On")
                stepTwoImage.image = #imageLiteral(resourceName: "icStep02")
                stepThreeImage.image = #imageLiteral(resourceName: "icStep03")
                stepFourImage.image = #imageLiteral(resourceName: "icStep04")
                stepOneLabel.textColor = UIColor.white
                stepTwoLabel.textColor = UIColor(6, 138, 153)
                stepThreeLabel.textColor = UIColor(6, 138, 153)
                stepFourLabel.textColor = UIColor(6, 138, 153)
                line1.backgroundColor = UIColor(6, 138, 153)
                line2.backgroundColor = UIColor(6, 138, 153)
                line3.backgroundColor = UIColor(6, 138, 153)
                
            case .two:
                stepOneImage.image = #imageLiteral(resourceName: "icStepCheck")
                stepTwoImage.image = #imageLiteral(resourceName: "icStep02On")
                stepThreeImage.image = #imageLiteral(resourceName: "icStep03")
                stepFourImage.image = #imageLiteral(resourceName: "icStep04")
                stepOneLabel.textColor = UIColor(255, 255, 255, 0.5)
                stepTwoLabel.textColor = UIColor.white
                stepThreeLabel.textColor = UIColor(6, 138, 153)
                stepFourLabel.textColor = UIColor(6, 138, 153)
                line1.backgroundColor = UIColor.white
                line2.backgroundColor = UIColor(6, 138, 153)
                line3.backgroundColor = UIColor(6, 138, 153)
                
                
            case .three:
                stepOneImage.image = #imageLiteral(resourceName: "icStepCheck")
                stepTwoImage.image = #imageLiteral(resourceName: "icStepCheck")
                stepThreeImage.image = #imageLiteral(resourceName: "icStep03On")
                stepFourImage.image = #imageLiteral(resourceName: "icStep04")
                stepOneLabel.textColor = UIColor(255, 255, 255, 0.5)
                stepTwoLabel.textColor = UIColor(255, 255, 255, 0.5)
                stepThreeLabel.textColor = UIColor.white
                stepFourLabel.textColor = UIColor(6, 138, 153)
                line1.backgroundColor = UIColor.white
                line2.backgroundColor = UIColor.white
                line3.backgroundColor = UIColor(6, 138, 153)
                
            case .four:
                stepOneImage.image = #imageLiteral(resourceName: "icStepCheck")
                stepTwoImage.image = #imageLiteral(resourceName: "icStepCheck")
                stepThreeImage.image = #imageLiteral(resourceName: "icStepCheck")
                stepFourImage.image = #imageLiteral(resourceName: "icStep04On")
                stepOneLabel.textColor = UIColor(255, 255, 255, 0.5)
                stepTwoLabel.textColor = UIColor(255, 255, 255, 0.5)
                stepThreeLabel.textColor = UIColor(255, 255, 255, 0.5)
                stepFourLabel.textColor = UIColor.white
                line1.backgroundColor = UIColor.white
                line2.backgroundColor = UIColor.white
                line3.backgroundColor = UIColor.white
                
            }
        }
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
        contentView = view
        stepOneLabel.text = "Create.Wallet.Step1.StepTitle".localized
        stepTwoLabel.text = "Create.Wallet.Step2.StepTitle".localized
        stepThreeLabel.text = "Create.Wallet.Step3.StepTitle".localized
        stepFourLabel.text = "Create.Wallet.Step4.StepTitle".localized
    }
    
    func loadViewFromNib() -> UIView? {
        guard let nibName = nibName else { return nil }
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 300, height: 56)
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        xibSetup()
        contentView?.prepareForInterfaceBuilder()
    }
    
    func setStep(step: CreateStep) {
        currentStep = step
    }
}
