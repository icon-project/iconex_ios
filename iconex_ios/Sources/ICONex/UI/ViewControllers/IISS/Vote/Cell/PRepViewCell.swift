//
//  PRepViewCell.swift
//  iconex_ios
//
//  Created by a1ahn on 26/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PRepViewCell: UITableViewCell {
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var prepNameLabel: UILabel!
    @IBOutlet weak var totalVoteLabel: UILabel!
    @IBOutlet weak var totalVoteValue: UILabel!
    
    var disposeBag = DisposeBag()
    
    var active: Bool = true {
        willSet {
            if newValue {
                statusView.backgroundColor = .mint2
            } else {
                statusView.backgroundColor = .mint3
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        totalVoteLabel.size12(text: "Total Votes (%)", color: .gray128, weight: .light, align: .left)
        statusView.corner(statusView.frame.height / 2)
        statusView.border(1.0, .mint2)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
