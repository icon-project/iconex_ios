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
    
    var wallet: ICXWallet!
    
    var key: PrivateKey!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        navBar.setTitle(wallet.name)
        navBar.setLeft {
            self.navigationController?.popViewController(animated: true)
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
        
        scrollView?.refreshControl = self.refreshControl
        refreshControl?.beginRefreshing()
        
        
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
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    if let delegated = delegatedInfo, let staked = stakedInfo {
                        let totalDelegated = delegated.totalDelegated
                        let stakeValue = staked.stake
                        let votedValue = totalDelegated - delegated.votingPower
                        
                        self.slider.isEnabled = true
                        self.slider.setRange(total: balance - totalDelegated, staked: stakeValue, voted: votedValue)
                        self.unstakedLabel.size14(text: (balance - stakeValue).toString(decimal: 18, 4, false).currencySeparated(), color: .gray77, weight: .regular, align: .right)
                    } else {
                        self.slider.isEnabled = false
                    }
                    self.refreshControl?.endRefreshing()
                    self.refreshControl = nil
                    self.scrollView?.refreshControl = nil
                }
            }
        }
        
        
    }
}
