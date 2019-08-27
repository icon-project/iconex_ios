//
//  IXSlider.swift
//  iconex_ios
//
//  Created by a1ahn on 20/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import BigInt

@IBDesignable
class IXSlider: UIView {
    @IBOutlet private weak var firstLabel: UILabel!
    @IBOutlet private weak var fieldContainer: UIView!
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var innerLabel: UILabel!
    
    @IBOutlet private weak var votedContainer: UIView!
    @IBOutlet private weak var votedLabel: UILabel!
    
    @IBOutlet private weak var minLabel: UILabel!
    @IBOutlet private weak var maxLabel: UILabel!
    @IBOutlet private weak var barContainer: UIView!
    @IBOutlet private weak var minBar: UIView!
    @IBOutlet private weak var maxBar: UIView!
    @IBOutlet private weak var slider: UISlider!
    @IBOutlet private weak var minWidth: NSLayoutConstraint!
    @IBOutlet weak var sliderLeading: NSLayoutConstraint!
    
    private var contentView: UIView?
    
    private let disposeBag = DisposeBag()
    
    private var totalValue: BigUInt?
    
    private var staked: BigUInt?
    private var voted: BigUInt?
    
    var fieldAction: ((String) -> Void)?
    
    var firstHeader: String = "Staked (ICX)" {
        willSet {
            firstLabel.size14(text: newValue, color: .mint1, weight: .regular, align: .left)
        }
    }
    var secondHeader: String? = "→ Voted" {
        willSet {
            if let second = newValue {
                votedContainer.isHidden = false
                votedLabel.size12(text: second, color: .mint1, weight: .light, align: .left)
            } else {
                votedContainer.isHidden = true
            }
        }
    }
    var minText: String = "Min"
    var maxText: String = "Max"
    var minimum: Float = 0.0 {
        willSet {
            current = newValue
            slider.minimumValue = newValue
            slider.value = 0.0
            sliderLeading.constant = 1 + (self.frame.width - 40 + 4) * CGFloat(newValue)
        }
    }
    
    var current: Float = 0.0 {
        willSet {
            guard newValue >= minimum else { return }
            minWidth.constant = barContainer.frame.width * CGFloat(newValue)
        }
    }
    
    var isEnabled: Bool = true {
        willSet {
            if !newValue {
                current = 0.0
                slider.isHidden = true
                innerLabel.size12(text: "-")
                votedContainer.isHidden = true
                textField.isEnabled = false
            } else {
                slider.isHidden = false
                votedContainer.isHidden = false
                textField.isEnabled = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        xibSetup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        xibSetup()
        contentView?.prepareForInterfaceBuilder()
    }
    
    func xibSetup() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "IXSlider", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        
        view.border(0.5, .gray230)
        view.backgroundColor = .gray252
        
        minBar.corner(minBar.frame.height / 2)
        maxBar.corner(maxBar.frame.height / 2)
        minBar.backgroundColor = .mint2
        maxBar.backgroundColor = .gray77
        
        slider.setThumbImage(#imageLiteral(resourceName: "icControlerEnabled"), for: .normal)
        slider.setThumbImage(#imageLiteral(resourceName: "icControlerEnabled"), for: .highlighted)
        minLabel.size12(text: "Min", color: .gray77, weight: .light, align: .left)
        maxLabel.size12(text: "Max", color: .gray77, weight: .light, align: .right)
        
        fieldContainer.backgroundColor = .white
        fieldContainer.corner(4)
        fieldContainer.border(1, .gray230)
        
        textField.tintColor = .mint1
        
        slider.rx.value.subscribe(onNext: { value in
            self.current = value
        }).disposed(by: disposeBag)
        
        textField.rx.controlEvent([.editingDidEnd, .editingDidEndOnExit])
            .subscribe(onNext: { [unowned self] in
                if let action = self.fieldAction {
                    action(self.textField.text!)
                }
                self.fieldContainer.border(1.0, .gray230)
                self.fieldContainer.backgroundColor = .white
                self.innerLabel.alpha = 1.0
                self.innerLabel.textColor = .gray77
            }).disposed(by: disposeBag)
        
        textField.rx.controlEvent(.editingDidBegin)
            .subscribe(onNext: { [unowned self] in
                self.fieldContainer.border(1.0, .mint2)
                self.fieldContainer.backgroundColor = .mint4
                self.innerLabel.textColor = .mint1
                self.innerLabel.alpha = 0.5
            }).disposed(by: disposeBag)
        
        self.backgroundColor = .clear
        
    }
    
    func setRange(total: BigUInt, staked: BigUInt = 0, voted: BigUInt? = nil) {
        self.totalValue = total
        self.staked = staked
        self.voted = voted
        if total == 0 {
            self.slider.value = 0.0
            isEnabled = false
        } else {
            self.slider.value = Float(staked / total)
            isEnabled = true
        }
    }
}
