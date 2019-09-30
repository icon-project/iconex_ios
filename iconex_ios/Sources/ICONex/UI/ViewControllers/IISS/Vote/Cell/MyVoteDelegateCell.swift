//
//  MyVoteDelegateCell.swift
//  iconex_ios
//
//  Created by a1ahn on 27/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MyVoteDelegateCell: UITableViewCell {
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var dotView: UIView!
    @IBOutlet weak var prepName: UILabel!
    @IBOutlet weak var prepInfo: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var totalVotedValue: UILabel!
    
    @IBOutlet weak var myVotesTitleLabel: UILabel!
    @IBOutlet weak var myvotesValueLabel: UILabel!
    
    @IBOutlet weak var sliderBoxView: UIView!
    @IBOutlet weak var sliderContainer: UIView!
    @IBOutlet weak var myVotesLabel: UILabel!
    @IBOutlet weak var fieldContainer: UIView!
    @IBOutlet weak var myVotesField: IXTextField!
    @IBOutlet weak var myVotesUnitLabel: UILabel!
    @IBOutlet weak var maxTitleLabel: UILabel!
    @IBOutlet weak var myVotesMax: UILabel!
    
    @IBOutlet weak var barContainer: UIView!
    @IBOutlet weak var minBar: UIView!
    @IBOutlet weak var maxBar: UIView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var minWidth: NSLayoutConstraint!
    
    var disposeBag = DisposeBag()
    
    var current: Float = 0.0 {
        willSet {
            guard newValue >= 0.0 else { return }
            minWidth.constant = barContainer.frame.width * CGFloat(newValue) / 100.0
        }
    }
    
    var myVoteMaxValue: String = "0%" {
        willSet {
            myVotesMax.text = newValue
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        dotView.corner(dotView.frame.height / 2)
        subtitleLabel.size12(text: "Total Votes (%)", color: .gray128, weight: .light, align: .left)
        myVotesTitleLabel.size12(text: "My Votes (%)", color: .gray128, weight: .light, align: .left)
        
        sliderContainer.border(0.5, .gray230)
        sliderContainer.corner(8)
        sliderContainer.backgroundColor = .gray252
        
        myVotesLabel.size14(text: "My Votes (%)", color: .mint1)
        
        fieldContainer.border(0.5, .gray230)
        fieldContainer.corner(4)
        
        myVotesField.tintColor = .mint1
        myVotesField.textColor = .mint1
        myVotesField.keyboardType = .decimalPad
        
        maxTitleLabel.text = "MAX"
        myVotesMax.textColor = .gray77
        myVotesMax.text = "(0 %)"
        
        minBar.corner(minBar.frame.height / 2)
        minBar.backgroundColor = .mint2
        maxBar.corner(maxBar.frame.height / 2)
        maxBar.backgroundColor = .gray77
        
        slider.setThumbImage(#imageLiteral(resourceName: "icControlerEnabled"), for: .normal)
        slider.setThumbImage(#imageLiteral(resourceName: "icControlerAtive"), for: .highlighted)
        
        addButton.setImage(#imageLiteral(resourceName: "icDeleteListDisabled"), for: .normal)
        addButton.setImage(#imageLiteral(resourceName: "icDeleteList"), for: .highlighted)
        
        current = 0
        
        // set textfield
        myVotesField.canPaste = false
        myVotesField.delegate = self
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

extension MyVoteDelegateCell: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch string {
        case Tool.decimalSeparator:
            return Array(textField.text!).filter({ String($0) == Tool.decimalSeparator }).count < 1
        default:
            guard let former = textField.text as NSString? else { return false }
            let text = former.replacingCharacters(in: range, with: string)
            let split = text.components(separatedBy: ".")
            if let below = split.last {
                
                if below.count <= 4 {
                    return true
                }
                return false
            }
            return false

        }
    }
}
