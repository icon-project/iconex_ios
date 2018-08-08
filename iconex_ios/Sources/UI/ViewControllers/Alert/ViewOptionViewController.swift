//
//  ViewOptionViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

protocol ViewOptionDelegate {
    func viewOptionfilterSelected(state: (Int, Int))
}

class ViewOptionViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var stateHoldButton: UIButton!
    
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var firstContainer: UIView!
    @IBOutlet weak var stateAllButton: UIButton!
    
    @IBOutlet weak var tabView: UIView!
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var secondContainer: UIView!
    @IBOutlet weak var typeAllButton: UIButton!
    @IBOutlet weak var typeWithdrawButton: UIButton!
    @IBOutlet weak var typeDepositButton: UIButton!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var delegate: ViewOptionDelegate?
    
    let disposeBag = DisposeBag()
    
    private var state: Int = 0 {
        willSet {
            switch newValue {
            case 0:
                stateAllButton.isSelected = true
                stateAllButton.backgroundColor = UIColor.black
                stateAllButton.setTitleColor(UIColor.white, for: .highlighted)
                stateHoldButton.isSelected = false
                stateHoldButton.backgroundColor = UIColor.white
                stateHoldButton.setTitleColor(UIColor.black, for: .highlighted)
                
            case 1:
                stateAllButton.isSelected = false
                stateAllButton.backgroundColor = UIColor.white
                stateAllButton.setTitleColor(UIColor.black, for: .highlighted)
                stateHoldButton.isSelected = true
                stateHoldButton.backgroundColor = UIColor.black
                stateHoldButton.setTitleColor(UIColor.white, for: .highlighted)
                
            default:
                break
            }
        }
    }
    private var type: Int = 0 {
        willSet {
            switch newValue {
            case 0:
                typeAllButton.isSelected = true
                typeAllButton.backgroundColor = UIColor.black
                typeWithdrawButton.isSelected = false
                typeWithdrawButton.backgroundColor = UIColor.white
                typeDepositButton.isSelected = false
                typeDepositButton.backgroundColor = UIColor.white
                
            case 1:
                typeAllButton.isSelected = false
                typeAllButton.backgroundColor = UIColor.white
                typeWithdrawButton.isSelected = true
                typeWithdrawButton.backgroundColor = UIColor.black
                typeDepositButton.isSelected = false
                typeDepositButton.backgroundColor = UIColor.white
                
            case 2:
                typeAllButton.isSelected = false
                typeAllButton.backgroundColor = UIColor.white
                typeWithdrawButton.isSelected = false
                typeWithdrawButton.backgroundColor = UIColor.white
                typeDepositButton.isSelected = true
                typeDepositButton.backgroundColor = UIColor.black
                
            default:
                break
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initializeUI() {
        
        self.view.alpha = 0.0
        
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.close()
        }).disposed(by: disposeBag)
        confirmButton.setTitle("Common.Confirm".localized, for: .normal)
        
        stateLabel.text = "Detail.Filter.Status".localized
        firstContainer.corner(4)
        firstContainer.border(1, UIColor.black)
        stateAllButton.setTitle("Detail.Filter.Complete".localized, for: .normal)
        stateAllButton.setTitleColor(UIColor.black, for: .normal)
        stateAllButton.setTitleColor(UIColor.white, for: .selected)
        stateHoldButton.setTitle("Detail.Filter.Pending".localized, for: .normal)
        stateHoldButton.setTitleColor(UIColor.black, for: .normal)
        stateHoldButton.setTitleColor(UIColor.white, for: .selected)
        
        typeLabel.text = "Detail.Filter.Type".localized
        secondContainer.corner(4)
        secondContainer.border(1, UIColor.black)
        typeAllButton.setTitle("Detail.Filter.All".localized, for: .normal)
        typeAllButton.setTitleColor(UIColor.black, for: .normal)
        typeAllButton.setTitleColor(UIColor.white, for: .selected)
        typeWithdrawButton.setTitle("Transfer.Transfer".localized, for: .normal)
        typeWithdrawButton.setTitleColor(UIColor.black, for: .normal)
        typeWithdrawButton.setTitleColor(UIColor.white, for: .selected)
        typeDepositButton.setTitle("Detail.Filter.Deposit".localized, for: .normal)
        typeDepositButton.setTitleColor(UIColor.black, for: .normal)
        typeDepositButton.setTitleColor(UIColor.white, for: .selected)
        
        stateAllButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.state = 0
        }).disposed(by: disposeBag)
        stateHoldButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.state = 1
        }).disposed(by: disposeBag)
        
        typeAllButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.type = 0
        }).disposed(by: disposeBag)
        typeWithdrawButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.type = 1
        }).disposed(by: disposeBag)
        typeDepositButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.type = 2
        }).disposed(by: disposeBag)
        
        confirmButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in

            self.close(completion: {
                guard let delegate = self.delegate else {
                    return
                }
                
                delegate.viewOptionfilterSelected(state: (self.state, self.type))
                
            })
        }).disposed(by: disposeBag)
        
        let gesture = UITapGestureRecognizer()
        tabView.addGestureRecognizer(gesture)
        gesture.rx.event.subscribe(onNext: { [unowned self] _ in
            self.close()
        }).disposed(by: disposeBag)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
}

extension ViewOptionViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.15, animations: {
            self.view.alpha = 1.0
        }, completion: { (bool) in
            self.bottomConstraint.constant = 0
            UIView.animate(withDuration: 0.15, animations: {
                self.view.layoutIfNeeded()
            })
        })
    }
    
    func present(from: UIViewController, title: String, state: (Int, Int)) {
        
        from.present(self, animated: false) {
            self.state = state.0
            self.type = state.1
            
            self.topLabel.text = title
            self.bottomConstraint.constant = (self.containerView.frame.height + 46)
        }
    }
    
    func close(completion: (() -> Void)? = nil) {
        self.bottomConstraint.constant = CGFloat((containerView.frame.height + 46))
        UIView.animate(withDuration: 0.15, animations: {
            self.view.layoutIfNeeded()
        }) { (bool) in
            UIView.animate(withDuration: 0.15, animations: {
                self.view.alpha = 0.0
            }) { (bool) in
                self.dismiss(animated: false, completion: {
                    if let handler = completion {
                        handler()
                    }
                })
            }
        }
    }
}
