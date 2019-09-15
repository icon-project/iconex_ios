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
    
    var wallet: ICXWallet!
    
    var key: PrivateKey!
    
    private var modifiedStake: BigUInt? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        navBar.setTitle(wallet.name)
        navBar.setLeft {
            if let modified = self.modifiedStake {
                Log("Modified - \(modified)")
                Alert.basic(title: "Stake.Alert.Discard.Title".localized, subtitle: "Stake.Alert.Discard.Message".localized, hasHeaderTitle: false, isOnlyOneButton: false, leftButtonTitle: "Common.Cancel".localized, rightButtonTitle: "Common.Confirm".localized, confirmAction: {
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
            .observeOn(MainScheduler.asyncInstance)
            .distinctUntilChanged()
            .debounce(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { current in
                self.modifiedStake = current
                Log("CURRENT \(current)")
                self.getEstimateFee()
        }).disposed(by: disposeBag)
        
        submitButton.isEnabled = false
        scrollView?.refreshControl = self.refreshControl
        refreshControl?.beginRefreshing()
        
        submitButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                guard let staked = self.stakedInfo?.stake,
                    let modified = self.modifiedStake,
                let limit = self.estimatedStep,
                let stepPrice = Manager.icon.stepPrice
                else { return }
                
                let fee = limit * stepPrice
                
                if staked > modified {
                    // unstake
                    let unstake = StakeInfo(timeRequired: "Stake.Value.TimeRequired.Untake".localized, stepLimit: limit.toString(decimal: 0, 0, false).currencySeparated(), estimatedFee: fee.toString(decimal: 18, 18, true), estimatedFeeUSD: (fee.exchange(from: "icx", to: "usd", decimal: 18)?.toString(decimal: 18, 2, false) ?? "-"))
                    Alert.unstake(unstakeInfo: unstake, confirmAction: {
                        self.setStake(value: modified, stepLimit: limit)
                    }).show()
                } else {
                    // stake
                    let unstake = StakeInfo(timeRequired: "Stake.Value.TimeRequired.Stake".localized, stepLimit: limit.toString(decimal: 0, 0, false).currencySeparated(), estimatedFee: fee.toString(decimal: 18, 18, true), estimatedFeeUSD: (fee.exchange(from: "icx", to: "usd", decimal: 18)?.toString(decimal: 18, 2, false) ?? "-"))
                    Alert.stake(stakeInfo: unstake, confirmAction: {
                        self.setStake(value: modified, stepLimit: limit)
                    }).show()
                }
            }).disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        if refreshControl != nil {
            guard let balance = wallet.balance else {
                balanceLabel.size14(text: "-")
                return
            }
            balanceLabel.size14(text: balance.toString(decimal: 18, 4, false).currencySeparated(), color: .gray77, weight: .regular, align: .right)
            
            DispatchQueue.global().async {
                let delegatedInfo = Manager.icon.getDelegation(wallet: self.wallet)
                let stakedInfo = Manager.icon.getStake(from: self.wallet)
                self.delegateInfo = delegatedInfo
                self.stakedInfo = stakedInfo
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    if let delegated = delegatedInfo, let staked = stakedInfo {
                        Log("Info - \(balance) + \(staked.stake) + \(staked.unstake ?? 0) = \(balance + staked.stake + (staked.unstake ?? 0))")
                        let totalValue = balance + staked.stake + (staked.unstake ?? 0)
                        
                        let totalDelegated = delegated.totalDelegated
                        let stakeValue = staked.stake
                        let votedValue = delegated.totalDelegated
                        
                        Log("Total = \(totalValue)\nStaked = \(stakeValue)\nVoted = \(delegated.totalDelegated)")
                        
                        if let totalNum = totalValue.decimalNumber ,let stakeNum = stakeValue.decimalNumber, let votedNum = votedValue.decimalNumber {
                            
                            let stakeRate: Decimal = {
                                if stakeNum == 0 {
                                    return 0
                                } else {
                                    return stakeNum / totalNum
                                }
                            }()

                            let voteRate: Decimal = {
                                if votedNum == 0 {
                                    return 0
                                } else {
                                    return votedNum / stakeNum
                                }
                            }()
                            
                            self.slider.isEnabled = true
                            
                            self.stakeProgress.staked = stakeRate.floatValue
                            self.stakeProgress.voted = voteRate.floatValue
                            
                            
                            
                            self.slider.setRange(total: totalValue, staked: stakeValue, voted: totalDelegated)
                        } else {
                            self.slider.isEnabled = false
                            self.slider.setRange(total: 0)
                        }
                        
                        self.unstakedLabel.size14(text: (totalValue - stakeValue).toString(decimal: 18, 4, false).currencySeparated(), color: .gray77, weight: .regular, align: .right)
                    } else {
                        self.slider.isEnabled = false
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
            return }
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
            }
        }
    }
    
    func refreshFeeInfo() {
        guard let stepPrice = Manager.icon.stepPrice, let modified = modifiedStake, let stakedInfo = stakedInfo else {
            timeLabel.size14(text: "-", color: .gray77)
            stepLimitLabel.size14(text: "-", color: .gray77)
            estimatedLabel.size14(text: "-", color: .gray77)
            submitButton.isEnabled = false
            return
        }
        
        submitButton.isEnabled = true
        
        if modified > stakedInfo.stake {
            timeLabel.size14(text: "Stake.Value.TimeRequired.Stake".localized, color: .gray77)
        } else if modified < stakedInfo.stake {
            timeLabel.size14(text: "Stake.Value.TimeRequired.Unstake".localized, color: .gray77)
        } else {
            timeLabel.size14(text: "-", color: .gray77)
            submitButton.isEnabled = false
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
    
    func setStake(value modified: BigUInt, stepLimit: BigUInt) {
        let transaction = Manager.icon.setStake(from: self.wallet, value: modified, stepLimit: stepLimit)
        do {
            let signed = try SignedTransaction(transaction: transaction, privateKey: self.key)
            let result = Manager.icon.iconService.sendTransaction(signedTransaction: signed).execute()
            let hash = try result.get()
            Log("Hash - \(hash)")
            Tool.toast(message: "Send.Success".localized)
        } catch {
            Log("Error - \(error)")
            Tool.toast(message: "Error.CommonError".localized)
        }
    }
}
