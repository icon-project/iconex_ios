//
//  SwapStepOneViewController.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit

class SwapStepOneViewController: BaseViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerLabel1: UILabel!
    @IBOutlet weak var descLabel1: UILabel!
    @IBOutlet weak var headerLabel2: UILabel!
    @IBOutlet weak var descContainer: UIView!
    @IBOutlet weak var descLabel2_1: UILabel!
    @IBOutlet weak var descLabel2_H: UILabel!
    @IBOutlet weak var descLabel2_2: UILabel!
    @IBOutlet weak var descButton: UIButton!
    @IBOutlet weak var descContainer2: UIView!
    @IBOutlet weak var descLabel2_3: UILabel!
    @IBOutlet var checkButton: UIButton!
    @IBOutlet var checkImage: UIImageView!
    @IBOutlet var checkLabel: UILabel!
    @IBOutlet var prevButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    
    @IBOutlet weak var buttonHeightConstraint: NSLayoutConstraint!
    var isWalletExists: Bool = false
    
    var delegate: SwapStepDelegate?
    
    private var isChecked: Bool = false {
        willSet {
            checkImage.isHighlighted = newValue
            nextButton.isEnabled = newValue
        }
    }
    private var innerStep: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeUI()
        initialize()
    }
    
    func initializeUI() {
        set1()
        
        prevButton.styleDark()
        prevButton.setTitle("Common.Back".localized, for: .normal)
        prevButton.rounded()
        nextButton.styleLight()
        nextButton.setTitle("Common.Next".localized, for: .normal)
        nextButton.isEnabled = false
        nextButton.rounded()
    }
    
    func initialize() {
        checkButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                self.isChecked = !self.isChecked
            }).disposed(by: disposeBag)
        
        prevButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.prevButton.isHidden = true
            self.nextButton.isEnabled = false
            self.isChecked = false
            self.set1()
            guard let delegate = self.delegate else { return }
            delegate.changeStep(to: SwapStepView.SwapStep.step1_1)
        }).disposed(by: disposeBag)
        nextButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.isChecked = false
            if self.innerStep == 1 {
                guard let delegate = self.delegate else { return }
                delegate.changeStep(to: SwapStepView.SwapStep.step1_2)
                self.set2()
            } else {
                guard let delegate = self.delegate else { return }
                delegate.changeStep(to: SwapStepView.SwapStep.step2)
                self.set1()
            }
        }).disposed(by: disposeBag)
        
        descButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            if self.innerStep == 1 {
                
            } else {
                guard let faqURL = URL(string: Config.faqLink) else { return }
                UIApplication.shared.open(faqURL, options: [:], completionHandler: nil)
            }
        }).disposed(by: disposeBag)
    }
    
    func set1() {
        innerStep = 1
        self.prevButton.isHidden = true
        self.nextButton.isEnabled = false
        nextButton.styleDark()
        headerLabel1.text = "Swap.Step1_1.Header1".localized
        descLabel1.text = "Swap.Step1_1.Desc1".localized
        headerLabel2.text = "Swap.Step1_1.Header2".localized
        descLabel2_1.text = "Swap.Step1_1.Desc2_1".localized
        descLabel2_2.text = "Swap.Step1_1.Desc2_2".localized
        descLabel2_3.text = "Swap.Step1_1.Desc2_3".localized
        descLabel2_H.text = "Swap.Step1_1.Desc2_H".localized
        descContainer.isHidden = false
        descContainer2.isHidden = false
        buttonHeightConstraint.constant = 0
        descButton.setAttributedTitle(nil, for: .normal)
        checkLabel.text = "Swap.Step1_1.Check".localized
    }
    
    func set2() {
        innerStep = 2
        self.prevButton.isHidden = false
        self.nextButton.isEnabled = false
        nextButton.styleLight()
        headerLabel1.text = "Swap.Step1_1.Header1".localized
        descLabel1.text = "Swap.Step1_1.Desc1".localized
        headerLabel2.text = "Swap.Step1_2.Header2".localized
        descLabel2_1.text = "Swap.Step1_2.Desc2_1".localized
        descLabel2_2.text = "Swap.Step1_2.Desc2_2".localized
        descLabel2_3.text = "Swap.Step1_2.Desc2_3".localized
        descLabel2_H.text = ""
        descContainer.isHidden = true
        descContainer2.isHidden = false
        buttonHeightConstraint.constant = 16
        let attr = NSAttributedString(string: "Swap.Step1_2.ButtonTitle".localized, attributes: [.font: UIFont.systemFont(ofSize: 13, weight: .bold), .underlineStyle: NSUnderlineStyle.styleSingle.rawValue, .foregroundColor: UIColor(69, 136, 230)])
        descButton.setAttributedTitle(attr, for: .normal)
        checkLabel.text = "Swap.Step1_2.Check".localized
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let delegate = self.delegate, delegate is SwapStep2ViewController {
            prevButton.isHidden = true
            nextButton.styleDark()
        }
    }
}
