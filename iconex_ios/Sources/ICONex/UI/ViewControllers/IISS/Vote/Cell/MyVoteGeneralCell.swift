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
    @IBOutlet weak var voteHeader: UILabel!
    @IBOutlet weak var slideView: UIView!
    @IBOutlet weak var votedWidth: NSLayoutConstraint!
    @IBOutlet weak var votedLabel: UILabel!
    @IBOutlet weak var availableLabel: UILabel!
    @IBOutlet weak var votedICXLabel: UILabel!
    @IBOutlet weak var availableICXLabel: UILabel!
    @IBOutlet weak var votedValueLabel: UILabel!
    @IBOutlet weak var availableValueLabel: UILabel!
    
    var cellBag = DisposeBag()
    
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
        
        voteViewModel.voteCount.subscribe(onNext: { (count) in
            self.voteHeader.size16(text: "Vote (\(count)/10)", color: .gray77, weight: .medium, align: .left)
        }).disposed(by: cellBag)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cellBag = DisposeBag()
    }
}
