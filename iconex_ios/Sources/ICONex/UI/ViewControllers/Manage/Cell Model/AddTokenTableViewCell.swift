//
//  AddTokenTableViewCell.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 27/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift

class AddTokenTableViewCell: UITableViewCell {
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var contractLabel: UILabel!
    @IBOutlet weak var expandButton: UIButton!
    
    @IBOutlet weak var cellHeight: NSLayoutConstraint!
    
    var isExpanded: Bool = false {
        willSet {
            cellHeight.constant = newValue ? 100 : 60
            expandButton.isSelected = newValue
        }
    }
    
    var tokenState: TokenState = .normal {
        willSet {
            switch newValue {
            case .normal:
                self.checkButton.isEnabled = true
                self.checkButton.isSelected = false
            case .saved: self.checkButton.isEnabled = false
            case .selected: self.checkButton.isSelected = true // ????
            }
        }
    }
    
    var cellBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization codes
        cellHeight.constant = 60
        checkButton.setImage(#imageLiteral(resourceName: "btnCheckOff"), for: .normal)
        checkButton.setImage(#imageLiteral(resourceName: "btnCheckDisabled"), for: .disabled)
        checkButton.setImage(#imageLiteral(resourceName: "btnCheckOn"), for: .selected)
        
        expandButton.setImage(#imageLiteral(resourceName: "icArrowListOpen"), for: .normal)
        expandButton.setImage(#imageLiteral(resourceName: "icArrowUp"), for: .selected)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cellBag = DisposeBag()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

public enum TokenState { // 저장 안됨, 저장 됨, 선택됨
    case normal, saved, selected
}
