//
//  UnStakeViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 2019/10/17.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import ICONKit
import BigInt
import Foundation

class UnStakeViewController: BaseViewController {
    @IBOutlet weak var navBar: IXNavigationView!
    
    @IBOutlet weak var stakeTitleLabel: UILabel!
    @IBOutlet weak var unstakeTitleLabel: UILabel!
    @IBOutlet weak var unstakedPercentLabel: UILabel!
    
    // progress
    @IBOutlet weak var percentBoxView: UIView!
    @IBOutlet weak var stakeBar: UIView!
    @IBOutlet weak var unstakingBar: UIView!
    @IBOutlet weak var unstakeBar: UIView!
    
    @IBOutlet weak var stakeBarWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var unstakingBarWidthContraint: NSLayoutConstraint!
    
    @IBOutlet weak var sliderStakedLabel: UILabel!
    @IBOutlet weak var sliderUnstakedLabel: UILabel!
    
    @IBOutlet weak var unstakeTitle: UILabel!
    @IBOutlet weak var completeBlockTitle: UILabel!
    @IBOutlet weak var estimatedTimeTitle: UILabel!
    
    @IBOutlet weak var unstakeLabel: UILabel!
    @IBOutlet weak var completeBlockLabel: UILabel!
    @IBOutlet weak var estimatedTimeLabel: UILabel!
    
    @IBOutlet weak var adjustButton: UIButton!
    
    @IBOutlet weak var footerBoxView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    var wallet: ICXWallet!
    var key: PrivateKey!
    
    var stakedInfo: PRepStakeResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        guard let info = self.stakedInfo else { return }
        guard let unstake = info.unstake else { return }
        guard let unstakeDecimal = unstake.decimalNumber, let stakeDecimal = info.stake.decimalNumber, let balance = wallet.balance?.decimalNumber else { return }
        
        let totalBalance = balance + unstakeDecimal + stakeDecimal
        
        navBar.setTitle(wallet.name)
        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarBack")) {
            self.navigationController?.popToRootViewController(animated: true)
        }
        
        stakeTitleLabel.size16(text: "Stake", color: .gray77, weight: .medium)
        unstakeTitleLabel.size14(text: "UnStaked", color: .gray77, weight: .light)
        
        percentBoxView.corner(10)
        percentBoxView.clipsToBounds = true
        
        let stakedPercent: Float = {
            return (stakeDecimal / totalBalance).floatValue * 100
        }()
        
        let totalStakedPercent: Float = {
            let stake = stakeDecimal + unstakeDecimal
            return (stake / totalBalance).floatValue * 100
        }()
        
        let unstakedPercent: Float = {
            let unstake: Decimal = totalBalance - stakeDecimal - unstakeDecimal
            return (unstake / totalBalance).floatValue * 100
        }()
        
        let requestUnstakePercent: Float = {
            return (unstakeDecimal / totalBalance).floatValue * 100
        }()
        
        unstakedPercentLabel.size14(text: String(format: "%.1f", unstakedPercent) + "%", color: .gray77)
        
        sliderStakedLabel.size14(text: "Staked " + "\(info.stake.toString(decimal: 18, 4).currencySeparated()) ICX " + "(" + String(format: "%.1f", totalStakedPercent) + "%)", color: .mint1)
        
        sliderUnstakedLabel.size14(text: "┗ " + "Unstake.Request.Percent".localized + " \(info.unstake!.toString(decimal: 18, 4).currencySeparated()) ICX " + "(" + String(format: "%.1f", requestUnstakePercent) + "%)", color: .mint1)
        
        // bar
        let percentBoxWidth = percentBoxView.frame.width - 4
        
        let stakeBarPercent: CGFloat = percentBoxWidth * CGFloat(stakedPercent / 100.0)
        stakeBarWidthConstraint.constant = stakeBarPercent
        
        let unstakingBarPercent: CGFloat = percentBoxWidth * CGFloat(requestUnstakePercent / 100.0)
        unstakingBarWidthContraint.constant = unstakingBarPercent
        
        unstakeTitle.size12(text: "Unstake.Request.ICX".localized, color: .gray77, weight: .light)
        completeBlockTitle.size12(text: "Unstake.Block".localized, color: .gray77, weight: .light)
        estimatedTimeTitle.size12(text: "Unstake.EstimateLockPeriod".localized, color: .gray77, weight: .light)
        
        unstakeLabel.size14(text: info.unstake?.toString(decimal: 18, 4).currencySeparated() ?? "-", color: .gray77, align: .right)
        completeBlockLabel.size14(text: info.unstakeBlockHeight?.toString(decimal: 0).currencySeparated() ?? "-", color: .gray77, align: .right)
        
        guard let remainingBlocks = info.remainingBlocks else { return }
        estimatedTimeLabel.size14(text: self.calculateRemainingDate(unstakeLockPeriod: remainingBlocks), color: .gray77, align: .right)
        
        adjustButton.roundGray230()
        adjustButton.setTitle("Unstake.Edit".localized, for: .normal)
        
        adjustButton.rx.tap.subscribe { (_) in
            let stake = UIStoryboard(name: "Stake", bundle: nil).instantiateInitialViewController() as! StakeViewController
            stake.wallet = self.wallet
            stake.key = self.key
            
            self.navigationController?.popViewController(animated: true)
            self.navigationController?.pushViewController(stake, animated: true)
        }.disposed(by: disposeBag)
        
        footerBoxView.mintBox()
        footerLabel.size12(text: "Unstake.Desc".localized, color: .mint1)
        
        unstakingBar.alpha = 0
        
        // unstaking animation
        twinkle()
    }
    
    func twinkle() {
        UIView.animate(withDuration: 1.0, delay: 0.0, options: .curveEaseInOut, animations: {
            self.unstakingBar.alpha = 0.6
        }, completion: { _ in
            UIView.animate(withDuration: 0.6, delay: 0.0, options: .curveEaseInOut, animations: {
                self.unstakingBar.alpha = 0.3
            }, completion: { (isFinished) in
                if isFinished {
                    self.twinkle()
                }
            })
        })
    }
    
    func calculateRemainingDate(unstakeLockPeriod: BigUInt) -> String {
        let now = Date()
        let periodDouble = Double(unstakeLockPeriod)
        
        let time: TimeInterval = TimeInterval(periodDouble*2.0)
        let estimatedDate = Date(timeInterval: time, since: now)
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.includesTimeRemainingPhrase = true
        
        guard let result = formatter.string(from: now, to: estimatedDate) else {
            return "-"
        }
        return result
    }
}
