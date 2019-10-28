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
    @IBOutlet weak var textField: IXTextField!
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
    
    private var minICX: BigUInt = BigUInt(1).convert()
    
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
    
    private var myStake: BigUInt = 0 {
        willSet {
            guard let totalNum = self.totalValue?.decimalNumber, let votedNum = self.voted?.decimalNumber, let myStakeNum = newValue.decimalNumber, let minDecimal = self.minICX.decimalNumber else { return }

            let stakeSliderPercent: Float = {
                if myStakeNum > votedNum && totalNum > votedNum {
                    let top = myStakeNum - votedNum
                    let bottom = totalNum - votedNum
                    return (top / bottom).floatValue * 100
                } else {
                    return 0.0
                }
            }()

            let stakePercent: Float = {
                if myStakeNum > 0 {
                    let bottom = totalNum + minDecimal
                    return (myStakeNum / bottom).floatValue * 100
                } else {
                    return 0.0
                }
            }()

            self.minWidth.constant = self.barContainer.frame.width * CGFloat(stakeSliderPercent / 100.0)

            currentValue.onNext(newValue)

            textField.text = newValue.toString(decimal: 18, 4, false)
            innerLabel.size12(text: "(" + String(format: "%.1f", stakePercent) + "%)")
        }
    }
    
    var isEnabled: Bool = true {
        willSet {
            if !newValue {
                slider.isHidden = true
                votedContainer.isHidden = true
                textField.isEnabled = false
            } else {
                slider.isHidden = false
                votedContainer.isHidden = false
                textField.isEnabled = true
            }
        }
    }
    
    var currentValue: PublishSubject<BigUInt> = PublishSubject<BigUInt>()
    
    var estimateFee: PublishSubject<Bool> = PublishSubject<Bool>()
    
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
        view.corner(8)
        view.backgroundColor = .gray252
        
        minBar.corner(minBar.frame.height / 2)
        maxBar.corner(maxBar.frame.height / 2)
        minBar.backgroundColor = .mint2
        maxBar.backgroundColor = .gray77
        
        slider.setThumbImage(#imageLiteral(resourceName: "icControlerEnabled"), for: .normal)
        slider.setThumbImage(#imageLiteral(resourceName: "icControlerAtive"), for: .highlighted)
        minLabel.size12(text: "Min", color: .gray77, weight: .light, align: .left)
        maxLabel.size12(text: "Max", color: .gray77, weight: .light, align: .right)
        
        fieldContainer.backgroundColor = .white
        fieldContainer.corner(4)
        fieldContainer.border(1, .gray230)
        textField.delegate = self
        textField.keyboardType = .decimalPad
        textField.tintColor = .mint1
        let bar = UIToolbar()
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(resign))
        done.tintColor = .mint1
        bar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), done]
        bar.sizeToFit()
        textField.inputAccessoryView = bar
        
        slider.rx.value.subscribe(onNext: { value in
            let percent = roundf(value) / 100
            
            guard let totalNum = self.totalValue?.decimalNumber, let voted = self.voted?.decimalNumber, let minDecimal = self.minICX.decimalNumber else { return }
            
            let totalValue = totalNum - voted
            let rateValueNum = totalValue * NSDecimalNumber(value: percent).decimalValue
            let rateValue: BigUInt = {
                if percent == 1.0 {
                    guard let total = self.totalValue else { return BigUInt.zero }
                    return total
                }
                
                let total = (rateValueNum + voted).floatValue
                return BigUInt(total)

            }()
            
            self.currentValue.onNext(rateValue)
            
            let stakePercent: Float = {
                let top = rateValueNum + voted
                if top > 0 {
                    let bottom = totalNum + minDecimal
                    return (top / bottom).floatValue * 100
                } else {
                    return 0.0
                }
            }()
            self.textField.text = rateValue.toString(decimal: 18, 4, false)
            self.innerLabel.size12(text: "(" + String(format: "%.1f", stakePercent) + "%)")
            
            self.minWidth.constant = self.barContainer.frame.width * CGFloat(percent)
            
        }).disposed(by: disposeBag)
        
        slider.rx.controlEvent(.touchUpInside).subscribe { (_) in
            self.estimateFee.onNext(true)
        }.disposed(by: disposeBag)
        
        textField.rx.controlEvent([.editingDidEnd, .editingDidEndOnExit])
            .subscribe(onNext: { [unowned self] in
                if let action = self.fieldAction {
                    action(self.textField.text!)
                }
                self.fieldContainer.border(1.0, .gray230)
                self.fieldContainer.backgroundColor = .white
                self.innerLabel.alpha = 1.0
                self.innerLabel.textColor = .gray77
                
                guard let value = self.textField.text, let bigValue = Tool.stringToBigUInt(inputText: value), let bigTotal = self.totalValue, let bigVoted = self.voted else { return }
                
                if bigValue < bigVoted {
                    bzz()
                    
                    let minValue = bigVoted.toString(decimal: 18, 4).currencySeparated()
                    
                    Toast.toast(message: String(format: "Error.Transfer.Limit.MoreThen".localized, minValue))
                    self.textField.text = minValue
                    
                    self.currentValue.onNext(bigVoted)
                    
                } else if bigValue > bigTotal {
                    bzz()
                    
                    let maxValue = bigTotal.toString(decimal: 18, 4).currencySeparated()
                    
                    Toast.toast(message: String(format: "Error.Transfer.Limit.LessThen".localized, maxValue))
                    self.textField.text = maxValue
                    
                    self.currentValue.onNext(bigTotal)
                }
                self.estimateFee.onNext(true)
            }).disposed(by: disposeBag)
        
        textField.rx.controlEvent(.editingDidBegin)
            .subscribe(onNext: { [unowned self] in
                self.fieldContainer.border(1.0, .mint2)
                self.fieldContainer.backgroundColor = .mint4
                self.innerLabel.textColor = .mint1
                self.innerLabel.alpha = 0.5
            }).disposed(by: disposeBag)
        
        textField.rx.text.orEmpty.subscribe(onNext: { (value) in
            // BigUInt
            guard let bigValue = Tool.stringToBigUInt(inputText: value, decimal: 18, fixed: true), let bigTotal = self.totalValue, let bigVoted = self.voted else { return }
            // Decimal
            guard let valueDecimal = bigValue.decimalNumber, let totalDecimal = bigTotal.decimalNumber, let votedDecimal = bigVoted.decimalNumber, let minDecimal = self.minICX.decimalNumber else { return }

            if valueDecimal > totalDecimal {
                self.minWidth.constant = self.barContainer.frame.width * CGFloat(100.0)
                self.innerLabel.size12(text: "100.0 %")
                self.slider.value = 100.0

            } else if valueDecimal < votedDecimal {
                self.minWidth.constant = self.barContainer.frame.width * CGFloat(0.0)
                self.innerLabel.size12(text: "0.0 %")
                self.slider.value = 0.0

            } else {
                let percent: Float = {
                    let top = valueDecimal - votedDecimal
                    let bottom = totalDecimal - votedDecimal
                    if top > 0 {
                        let result = (top / bottom) * 100
                        return result.floatValue
                    } else {
                        return 0.0
                    }
                }()
                
                let innerPercent: Float = {
                    let bottom = totalDecimal + minDecimal
                    let result = (valueDecimal / bottom) * 100
                    return result.floatValue
                }()
                
                self.minWidth.constant = self.barContainer.frame.width * CGFloat(percent / 100.0)
                self.innerLabel.size12(text: "(" + String(format: "%.1f", innerPercent) + "%)")
                self.currentValue.onNext(bigValue)
                self.slider.value = percent
            }

        }).disposed(by: disposeBag)
        
        self.backgroundColor = .clear
        
    }
    
    func setRange(total: BigUInt, staked: BigUInt = 0, voted: BigUInt? = nil) {
        if total > BigUInt.zero {
            self.totalValue = total - self.minICX
        } else {
            self.totalValue = total
        }
        self.staked = staked
        self.voted = voted
        if total == 0 {
            myStake = voted ?? 0
            slider.value = 0
            isEnabled = false
        } else {
            guard let stakedDecimal = staked.decimalNumber, let votedDecimal = voted?.decimalNumber, let totalDecimal = self.totalValue?.decimalNumber, let minDecimal = self.minICX.decimalNumber else { return }
            
            let percent: Float = {
                let top = stakedDecimal - votedDecimal
                let bottom = totalDecimal - votedDecimal
                if top > 0 {
                    let result = (top / bottom) * 100
                    return result.floatValue
                } else {
                    return 0.0
                }
            }()
            
            let minPercent: Float = {
               let top = stakedDecimal - votedDecimal
                let bottom = totalDecimal - votedDecimal
                if top > 0 {
                    return (top / bottom).floatValue
                } else {
                    return 0.0
                }
            }()
            
            self.minWidth.constant = barContainer.frame.width * CGFloat(minPercent)
            currentValue.onNext(staked)
            
            textField.text = staked.toString(decimal: 18, 4, false)
            
            let bottom = totalDecimal + minDecimal
            let innerPercent = (stakedDecimal / bottom) * 100
            
            innerLabel.size12(text: "(" + String(format: "%.1f", innerPercent.floatValue) + "%)")
            
            slider.value = percent
            isEnabled = true
        }
    }
}

extension IXSlider {
    @objc func resign() {
        textField.resignFirstResponder()
    }
}

extension IXSlider: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch string {
        case Tool.decimalSeparator:
            return Array(textField.text!).filter({ String($0) == Tool.decimalSeparator }).count < 1
        default:
            guard let former = textField.text as NSString? else { return false }
            let text = former.replacingCharacters(in: range, with: string)
            
            if text.contains(".") {
                let split = text.components(separatedBy: ".")
                if let below = split.last {

                    if below.count <= 4 {
                        return true
                    }
                    return false
                }
                return false
            }
            return true
        }
    }
}
