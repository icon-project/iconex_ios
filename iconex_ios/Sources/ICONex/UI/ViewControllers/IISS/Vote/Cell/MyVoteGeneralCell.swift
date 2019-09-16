//
//  MyVoteGeneralCell.swift
//  iconex_ios
//
//  Created by a1ahn on 22/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MyVoteGeneralCell: UITableViewCell {
    @IBOutlet private weak var voteHeader: UILabel!
    @IBOutlet private weak var slideView: UIView!
    @IBOutlet private weak var votedWidth: NSLayoutConstraint!
    @IBOutlet private weak var votedLabel: UILabel!
    @IBOutlet private weak var availableLabel: UILabel!
    @IBOutlet private weak var votedICXLabel: UILabel!
    @IBOutlet private weak var availableICXLabel: UILabel!
    @IBOutlet private weak var votedValueLabel: UILabel!
    @IBOutlet private weak var availableValueLabel: UILabel!
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        slideView.corner(slideView.frame.height / 2)
        votedICXLabel.size12(text: "Voted (VP)", color: .gray77, weight: .light, align: .left)
        availableICXLabel.size12(text: "Available (VP)", color: .gray77, weight: .light, align: .left)
        voteHeader.size16(text: "Vote (0/10)", color: .gray77, weight: .light, align: .left)
        votedLabel.size14(text: "Voted -", color: .mint1, weight: .light, align: .left)
        availableLabel.size14(text: "Available -", color: .gray77, weight: .light, align: .right)
        votedValueLabel.size14(text: "-", color: .gray77, weight: .light, align: .right)
        availableValueLabel.size14(text: "-", color: .gray77, weight: .light, align: .right)
    }

    func set(info: TotalDelegation) {
        voteHeader.size16(text: "Vote (\(info.delegations.count)/10)", color: .gray77, weight: .medium, align: .left)
        let votingPower = info.votingPower
        let voted = info.totalDelegated
        let total = info.totalDelegated + votingPower
        
        voteViewModel.available.subscribe(onNext: { [weak self] (availablePower) in
            let powerDecimal = availablePower.decimalNumber ?? 0
            let totalDecimal = total.decimalNumber ?? 0
            
            let rate = powerDecimal / totalDecimal
            
            self?.votedWidth.constant = self?.slideView.frame.width ?? 0 * CGFloat(1.0 - rate.floatValue)
            
            let percent = rate * 100
            self?.votedLabel.size14(text: "Voted " + String(format: "%.1f", 100.0 - percent.floatValue) + "%", color: .mint1, weight: .light)
            self?.availableLabel.size14(text: "Available " + String(format: "%.1f", percent.floatValue) + "%", color: .gray77, weight: .light)
        }).disposed(by: disposeBag)
        
        votedValueLabel.size14(text: voted.toString(decimal: 18, 4, false), color: .gray77, weight: .light, align: .right)
        availableValueLabel.size14(text: votingPower.toString(decimal: 18, 4, false), color: .gray77, weight: .light, align: .right)
        
        guard votingPower != 0, total != 0 else {
            votedWidth.constant = 0
            return
        }
        let ratio = votingPower / total
        Log("ration = \(ratio)")
        
    }
}
