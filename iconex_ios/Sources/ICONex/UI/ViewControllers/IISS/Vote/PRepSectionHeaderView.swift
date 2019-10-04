//
//  PRepSectionHeaderView.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 25/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PRepSectionHeaderView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var orderButton: UIButton!
    @IBOutlet weak var totalVotesButton: UIButton!
    
    var orderType: OrderType = .rankDescending {
        willSet {
            switch newValue {
            case .rankDescending:
                self.rankLabel.text = "Rank ↑"
                self.nameLabel.text = "Name"
                
                // color
                self.rankLabel.textColor = .gray77
                self.nameLabel.textColor = .gray179
                
            case .rankAscending:
                self.rankLabel.text = "Rank ↓"
                
            case .nameDescending:
                self.rankLabel.text = "Rank"
                self.nameLabel.text = "Name ↑"
                
                self.rankLabel.textColor = .gray179
                self.nameLabel.textColor = .gray77
                
            case .nameAscending:
                self.nameLabel.text = "Name ↓"
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func xibSetup() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "PRepSectionHeaderView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        
        totalVotesButton.setTitle("Total Votes", for: .normal)
        totalVotesButton.setTitleColor(.gray179, for: .normal)
        totalVotesButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .light)
        
        self.rankLabel.text = "Rank ↑"
        self.nameLabel.text = "Name"
        
        // color
        self.rankLabel.textColor = .gray77
        self.nameLabel.textColor = .gray179
    }
}
