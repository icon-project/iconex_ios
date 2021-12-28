//
//  StakeViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 20/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import BigInt
import ICONKit

class StakeViewController: BaseViewController {
    @IBOutlet weak var navBar: IXNavigationView!
    @IBOutlet weak var stakeHeader1: UILabel!
    @IBOutlet weak var stakeProgress: IXStakeProgressView!
    @IBOutlet weak var balanceHeader: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var unstakedHeader: UILabel!
    @IBOutlet weak var unstakedLabel: UILabel!
    
    @IBOutlet weak var slider: IXSlider!
    
    @IBOutlet weak var desc1: UILabel!
    @IBOutlet weak var desc2: UILabel!
    @IBOutlet weak var infoContainer: UIView!
    @IBOutlet weak var timeHeader: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var stepLimitHeader: UILabel!
    @IBOutlet weak var stepLimitLabel: UILabel!
    @IBOutlet weak var estimatedHeader: UILabel!
    @IBOutlet weak var estimatedLabel: UILabel!
    @IBOutlet weak var exchangedLabel: UILabel!
    @IBOutlet weak var buttonContainer: UIView!
    @IBOutlet weak var submitButton: UIButton!
    
    private var refreshControl: UIRefreshControl? = UIRefreshControl()
    
    private var delegateInfo: TotalDelegation?
    private var stakedInfo: PRepStakeResponse?
    private var estimatedStep: BigUInt?
    private var estimatedTime: String = "-"
    
    private var totalICX: BigUInt?
    
    private var stepPrice: BigUInt?
    
    var wallet: ICXWallet!
    
    var key: PrivateKey!
    
    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = TimeZone.autoupdatingCurrent
        
        return formatter
    }()
    
    private var modifiedStake: BigUInt? = nil {
        willSet {
            guard let total = self.totalICX, let newStake = newValue else { return }
            
            let unstaked = total - newStake
            self.unstakedLabel.size14(text: unstaked.toString(decimal: 18, 4).currencySeparated(), color: .gray77, weight: .regular, align: .right)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        navBar.setTitle(wallet.name)
        navBar.setLeft {
            if let modified = self.modifiedStake, let staked = self.stakedInfo?.stake {
                Log("Modified - \(modified)")
                guard modified != staked else {
                    self.navigationController?.popViewController(animated: true)
                    return
                }
                let question: String = {
                    if modified > staked {
                        return "Stake"
                    } else {
                        return "Unstake"
                    }
                }()
                
                Alert.basic(title: "Stake.Alert.Discard.Title".localized, subtitle: String(format: "Stake.Alert.Discard.Message".localized, question), hasHeaderTitle: false, isOnlyOneButton: false, leftButtonTitle: "Common.No".localized, rightButtonTitle: "Common.Yes".localized, confirmAction: {
                    self.slider.preventValidation = true
                    self.navigationController?.popViewController(animated: true)
                }).show()
                
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        stakeHeader1.size16(text: "Stake", color: .gray77, weight: .medium, align: .left)
        balanceHeader.size12(text: "Balance (ICX)", color: .gray77, weight: .light, align: .left)
        unstakedHeader.size12(text: "Unstaked (ICX)", color: .gray77, weight: .light, align: .left)
        unstakedLabel.size12(text: "-", color: .gray77, weight: .light, align: .right)
        
        slider.firstHeader = "Stake (ICX)"
        slider.secondHeader = "→ Voted"
        
        desc1.isHidden = true
        desc2.isHidden = true
        infoContainer.isHidden = true
        
        desc1.size12(text: "Stake.Desc1.Stake".localized, color: .gray128, weight: .light, align: .left)
        desc2.size12(text: "Stake.Desc2.Stake".localized, color: .gray128, weight: .light, align: .left)
        
        submitButton.lightMintRounded()
        submitButton.setTitle("Stake.Button.Submit".localized, for: .normal)
        
        buttonContainer.backgroundColor = .gray252
        
        stakeProgress.staked = 0.0
        stakeProgress.voted = 0.0
        
        slider.setRange(total: 0, staked: 0, voted: 0)
        
        infoContainer.border(0.5, .gray230)
        infoContainer.backgroundColor = .gray252
        infoContainer.corner(8)
        
        timeHeader.size12(text: "Stake.Header.TimeRequired".localized, color: .gray128, weight: .light, align: .left)
        stepLimitHeader.size12(text: "Stake.Header.StepLimit".localized, color: .gray128, weight: .light, align: .left)
        estimatedHeader.size12(text: "Stake.Header.EstimatedFee".localized, color: .gray128, weight: .light, align: .left)
        
        timeLabel.size14(text: "-", color: .gray77)
        
        stepLimitLabel.size14(text: "-", color: .gray77)
        estimatedLabel.size14(text: "-", color: .gray77)
        exchangedLabel.size12(text: "-", color: .gray179)
        
        slider.currentValue
            .skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .distinctUntilChanged()
            .subscribe(onNext: { current in
                self.modifiedStake = current
                
                Log("CURRENT \(current)")
                
                // update slider
                let voted = self.delegateInfo?.totalDelegated ?? BigUInt.zero
                guard let totalICXDecimal = self.totalICX?.decimalNumber, let newStake = current.decimalNumber, let votedDecimal = voted.decimalNumber else { return }
                
                let stakeRate: Decimal = {
                    if newStake == 0 {
                        return 0
                    } else {
                        return newStake / totalICXDecimal
                    }
                }()
                
                let votedRate: Decimal = {
                    if votedDecimal > 0 {
                        return votedDecimal / newStake
                    } else {
                        return 0.0
                    }
                }()
                
                let totalStaked: BigUInt = {
                    let staked = self.stakedInfo?.stake ?? BigUInt.zero
                    let unstake = self.stakedInfo?.unstake ?? BigUInt.zero
                    return staked + unstake
                }()
                
                self.slider.isEnabled = true
                
                self.submitButton.isEnabled = self.modifiedStake != totalStaked
//                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = self.modifiedStake == totalStaked
                self.navigationController?.interactivePopGestureRecognizer?.delegate = self
                self.stakeProgress.staked = stakeRate.floatValue
                self.stakeProgress.voted = votedRate.floatValue
                
        }).disposed(by: disposeBag)
        
        
        slider.estimateFee.subscribe { (_) in
            self.getEstimateFee()
        }.disposed(by: disposeBag)
        
        submitButton.isEnabled = false
        scrollView?.refreshControl = self.refreshControl
        refreshControl?.beginRefreshing()
        
        submitButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                guard let staked = self.stakedInfo?.stake,
                    let modified = self.modifiedStake,
                let stepPrice = self.stepPrice
                else { return }
                
                guard let limit = self.estimatedStep else { return }
                
                let unstake = self.stakedInfo?.unstake ?? BigUInt.zero
                let totalStaked = staked + unstake
                let fee = limit * stepPrice
                
                // Check fee
                let balance = Manager.icon.getBalance(address: self.wallet.address) ?? BigUInt.zero
                
                guard balance >= fee else {
                    Alert.basic(title: "Send.Error.InsufficientFee.ICX".localized, leftButtonTitle: "Common.Confirm".localized).show()
                    return
                }
                
                let stepLimitPrice = limit.toString(decimal: 0, 0, false).currencySeparated() + " / " + stepPrice.toString(decimal: 18, 18, true).currencySeparated()
                
                // unstake
                if totalStaked > modified {
                    let unstake = StakeInfo(timeRequired: self.estimatedTime, stepLimit: stepLimitPrice, estimatedFee: fee.toString(decimal: 18, 18, true), estimatedFeeUSD: (fee.exchange(from: "icx", to: "usd", decimal: 18)?.toString(decimal: 18, 2, false) ?? "-"))
                    Alert.unstake(unstakeInfo: unstake, confirmAction: {
                        self.setStake(value: modified, stepLimit: limit, message: "Unstake")
                    }).show()
                    
                } else {
                    // stake
                    let stake = StakeInfo(timeRequired: "Stake.Value.TimeRequired.Stake".localized, stepLimit: stepLimitPrice, estimatedFee: fee.toString(decimal: 18, 18, true), estimatedFeeUSD: (fee.exchange(from: "icx", to: "usd", decimal: 18)?.toString(decimal: 18, 2, false) ?? "-"))
                    Alert.stake(stakeInfo: stake, confirmAction: {
                        self.setStake(value: modified, stepLimit: limit, message: "Stake")
                    }).show()
                    
                }
            }).disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        if refreshControl != nil {
            guard let balance = wallet.balance else {
                balanceLabel.size14(text: "-")
                submitButton.isEnabled = false
                return
            }
            balanceLabel.size14(text: "-", color: .gray77, weight: .regular, align: .right)
            
            DispatchQueue.global().async {
                let delegatedInfo = Manager.icon.getDelegation(wallet: self.wallet)
                let stakedInfo = Manager.icon.getStake(from: self.wallet)
                let stepPriceInfo = Manager.icon.getStepPrice()
                self.delegateInfo = delegatedInfo
                self.stakedInfo = stakedInfo
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    if let delegated = delegatedInfo, let staked = stakedInfo, let stepPrice = stepPriceInfo {
                        Log("Info - \(balance) + \(staked.stake) + \(staked.unstake ?? 0) = \(balance + staked.stake + (staked.unstake ?? 0))")
                        self.stepPrice = stepPrice
                        
                        let totalDelegated = delegated.totalDelegated
                        let stakeValue = staked.stake
                        let unstakeValue = staked.unstake ?? 0
                        let votedValue = delegated.totalDelegated
                        
                        let totalValue = balance + stakeValue + unstakeValue
                        
                        let minICX: BigUInt = {
                            if balance >= BigUInt(1).convert() {
                                return BigUInt(1).convert()
                            } else {
                                return balance
                            }
                        }()
                        
                        self.totalICX = totalValue
                        
                        let totalStaked = stakeValue + unstakeValue
                        
                        Log("Total = \(totalValue)\nStaked = \(stakeValue)\nVoted = \(delegated.totalDelegated)")
                        
                        if let totalNum = totalValue.decimalNumber, let stakeNum = stakeValue.decimalNumber, let votedNum = votedValue.decimalNumber, let totalStakedNum = totalStaked.decimalNumber {
                            
                            let unstakeNum = staked.unstake?.decimalNumber ?? 0.0
                            
                            let stakeRate: Decimal = {
                                let top = stakeNum + unstakeNum
                                if top == 0 {
                                    return 0
                                } else {
                                    return top / totalNum
                                }
                            }()

                            let voteRate: Decimal = {
                                let bottom = stakeNum + unstakeNum
                                if votedNum == 0 {
                                    return 0
                                } else {
                                    return votedNum / bottom
                                }
                            }()
                            
                            let icx1 = BigUInt(1).convert().decimalNumber ?? 0
                            let isOnly1ICX = (totalNum == icx1) && (totalStakedNum == 0)
                            let vote100check = ((totalStakedNum == votedNum) && stakeNum != 0) && (totalStakedNum + icx1 > totalNum)
                            
                            if vote100check || isOnly1ICX {
                                self.desc1.isHidden = false
                                self.desc1.size12(text: "Stake.Desc1.Unavailable".localized, color: .gray128, weight: .light, align: .left, lineBreakMode: .byWordWrapping)
                                self.infoContainer.isHidden = true
                                self.slider.isEnabled = false
                            } else {
                                self.desc1.isHidden = false
                                self.desc1.size12(text: "Stake.Desc1.Stake".localized, color: .gray128, weight: .light, align: .left, lineBreakMode: .byWordWrapping)
                                self.desc2.isHidden = false
                                self.infoContainer.isHidden = false
                                self.slider.isEnabled = true
                            }
                            
                            self.stakeProgress.staked = stakeRate.floatValue
                            self.stakeProgress.voted = voteRate.floatValue
                            
                            self.slider.setRange(total: totalValue, staked: totalStaked, voted: totalDelegated, minICX: minICX)
                            self.getEstimateFee()
                            
                            self.slider.secondHeader = "→ Voted (ICX) \(votedValue.toString(decimal: 18, 4, false).currencySeparated()) (\(String(format: "%.1f", voteRate.floatValue * 100))%)"
                            
                        } else {
                            self.slider.isEnabled = false
                            self.slider.setRange(total: 0)
                        }
                        
                        self.balanceLabel.size14(text: totalValue.toString(decimal: 18, 4, false).currencySeparated(), color: .gray77, weight: .regular, align: .right)
                        self.unstakedLabel.size14(text: (totalValue - totalStaked).toString(decimal: 18, 4, false).currencySeparated(), color: .gray77, weight: .regular, align: .right)
                        
                    } else {
                        self.slider.isEnabled = false
                        Toast.toast(message: "Error.CommonError".localized)
                        self.navigationController?.popViewController(animated: true)
                    }
                    self.refreshControl?.endRefreshing()
                    self.refreshControl = nil
                    self.scrollView?.refreshControl = nil
                    self.refreshFeeInfo()
                }
            }
        }
    }
}

extension StakeViewController {
    func getEstimateFee() {
        guard let value = modifiedStake else {
            refreshFeeInfo()
            return
        }
        
        DispatchQueue.global().async {
            let params = ["value": value.toHexString()]
            
            let call = CallTransaction()
            call.from = self.wallet.address
            call.to = CONST.iiss
            call.method("setStake")
            call.params(params)
            call.nid = Manager.icon.iconService.nid
            
            let result = Manager.icon.iconService.estimateStep(transaction: call).execute()
            
            DispatchQueue.main.async {
                do {
                    let estimated = try result.get()
                    Log("Fee - \(estimated)")
                    self.estimatedStep = estimated
                } catch {
                    Log("Error - \(error)")
                }
                self.refreshFeeInfo()
                self.estimatedPeriod()
            }
        }
    }
    
    func estimatedPeriod() {
        guard let modified = modifiedStake, let stakedInfo = stakedInfo else {
            timeLabel.size14(text: "-", color: .gray77)
            submitButton.isEnabled = false
            return
        }
        
        let totalStake = stakedInfo.stake + (stakedInfo.unstake ?? BigUInt.zero)
        
        if modified > totalStake {
            timeLabel.size14(text: "Stake.Value.TimeRequired.Stake".localized, color: .gray77)
            
        } else if modified < totalStake {
            DispatchQueue.global().async {
                guard let estimatedUnstakeTime = Manager.icon.estimateUnstakeLockPeriod(from: self.wallet) else {
                    DispatchQueue.main.async {
                        self.submitButton.isEnabled = false
                    }
                    return
                }
                
                let estimated: TimeInterval = Double(estimatedUnstakeTime) * 2.0
                let estimatedDate = Date(timeIntervalSinceNow: estimated)
                let estimatedString = self.dateFormatter.string(from: estimatedDate)
                
                self.estimatedTime = estimatedString
                
                DispatchQueue.main.async {
                    self.timeLabel.size14(text: estimatedString, color: .gray77)
                }
            }
        } else {
            timeLabel.size14(text: "-", color: .gray77)
            submitButton.isEnabled = false
        }
    }
    
    func refreshFeeInfo() {
        guard let stepPrice = self.stepPrice else {
            timeLabel.size14(text: "-", color: .gray77)
            stepLimitLabel.size14(text: "-", color: .gray77)
            estimatedLabel.size14(text: "-", color: .gray77)
            submitButton.isEnabled = false
            return
        }
        
        if let estimated = estimatedStep {
            stepLimitLabel.size14(text: estimated.toString(decimal: 0).currencySeparated() + " / " + stepPrice.toString(decimal: 18, 18, true), color: .gray77)
            let fee = estimated * stepPrice
            estimatedLabel.size14(text: fee.toString(decimal: 18, 18, true).currencySeparated(), color: .gray77)
            exchangedLabel.size14(text: "$ " + (fee.exchange(from: "icx", to: "usd")?.toString(decimal: 18, 2, false) ?? "-"), color: .gray179)
        } else {
            stepLimitLabel.size14(text: "100000".currencySeparated() + " / " + stepPrice.toString(decimal: 18, 18, true), color: .gray77)
            let fee = BigUInt(100_000) * stepPrice
            estimatedLabel.size14(text: fee.toString(decimal: 18, 18, true).currencySeparated(), color: .gray77)
            exchangedLabel.size14(text: "$ " + (fee.exchange(from: "icx", to: "usd")?.toString(decimal: 18, 2, false) ?? "-"), color: .gray179)
        }
    }
    
    func setStake(value modified: BigUInt, stepLimit: BigUInt, message: String) {
        let transaction = Manager.icon.setStake(from: self.wallet, value: modified, stepLimit: stepLimit)
        do {
            let signed = try SignedTransaction(transaction: transaction, privateKey: self.key)
            let result = Manager.icon.iconService.sendTransaction(signedTransaction: signed).execute()
            let hash = try result.get()
            Log("Hash - \(hash)")
            Alert.basic(title: String(format: "Stake.Alert.Complete.Message".localized, message), leftButtonTitle: "Common.Confirm".localized, cancelAction: {
                self.navigationController?.popViewController(animated: true)
                }).show()
            
            DispatchQueue.global().async {
//                let result = Manager.icon.getBalance(address: self.wallet.address)
//                Log("Balance: \(String(describing: result))")
//
//                // fetch prep info
//                Manager.iiss.getPRepInfo()
                Manager.balance.getAllBalances()
            }
        } catch {
            Log("Error - \(error)")
            Alert.basic(title: "Error.CommonError".localized, leftButtonTitle: "Common.Confirm".localized).show()
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let modified = self.modifiedStake, let staked = self.stakedInfo?.stake {
            Log("Modified - \(modified)")
            guard modified != staked else {
                return true
            }
            let question: String = {
                if modified > staked {
                    return "Stake"
                } else {
                    return "Unstake"
                }
            }()
            
            Alert.basic(title: "Stake.Alert.Discard.Title".localized, subtitle: String(format: "Stake.Alert.Discard.Message".localized, question), hasHeaderTitle: false, isOnlyOneButton: false, leftButtonTitle: "Common.No".localized, rightButtonTitle: "Common.Yes".localized, confirmAction: {
                self.slider.preventValidation = true
                self.navigationController?.popViewController(animated: true)
            }).show()
            
            return false
        } else {
            return true
        }
    }
}
