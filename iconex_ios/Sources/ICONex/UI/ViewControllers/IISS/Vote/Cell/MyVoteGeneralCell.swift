//
//  MyVoteGeneralCell.swift
//  iconex_ios
//
//  Created by a1ahn on 22/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

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
        
        Log("totalDelegated \(voted) power \(votingPower)")
        
        if voted == 0 {
            votedWidth.constant = 0
            votedLabel.size14(text: "Voted 0.0%", color: .mint1, weight: .light)
            availableLabel.size14(text: "Available 100.0%", color: .gray77, weight: .light)
        } else {
            let rate = voted.decimalNumber! / total.decimalNumber!
            votedWidth.constant = slideView.frame.width * CGFloat(rate.floatValue)
            votedLabel.size14(text: "Voted " + String(format: "%.1f", rate.floatValue), color: .mint1, weight: .light)
            availableLabel.size14(text: "Available " + String(format: "%.1f", 1.0 - rate.floatValue), color: .gray77, weight: .light)
        }
        
        
        
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
