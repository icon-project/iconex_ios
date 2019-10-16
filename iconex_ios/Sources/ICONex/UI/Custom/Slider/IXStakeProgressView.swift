//
//  IXProgressView.swift
//  iconex_ios
//
//  Created by a1ahn on 20/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import BigInt

@IBDesignable
class IXStakeProgressView: UIView {
    
    var minTextColor: UIColor = .mint1
    var maxTextColor: UIColor = .gray77
    
    var backBarColor: UIColor = .gray77
    var stakedColor: UIColor = .mint2
    var votedColor: UIColor = .mint3
    
    var staked: Float = 0.0 {
        willSet {
            stakedLabel.size14(text: "Staked " + String(format: "%.1f", newValue * 100) + "%" , color: minTextColor, weight: .light, align: .left)
            unstakedLabel.size14(text: "Unstaked " + String(format: "%.1f", (1 - newValue) * 100) + "%", color: maxTextColor, weight: .light, align: .right)
        }
        
        didSet {
            refreshBar()
        }
    }
    var voted: Float = 0.0 {
        willSet {
            votedLabel.size12(text: String(format: "→ Voted %.1f", newValue * 100) + "%", color: minTextColor, weight: .light, align: .left)
        }
        
        didSet {
            refreshBar()
        }
    }
    
    @IBOutlet private weak var backBar: UIView!
    @IBOutlet private weak var stakedBar: UIView!
    @IBOutlet private weak var votedBar: UIView!
    @IBOutlet private weak var stakedLabel: UILabel!
    @IBOutlet private weak var unstakedLabel: UILabel!
    @IBOutlet private weak var votedLabel: UILabel!
    @IBOutlet weak var stakedWidth: NSLayoutConstraint!
    @IBOutlet weak var votedWidth: NSLayoutConstraint!
    
    var contentView: UIView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        xibSetup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        xibSetup()
        contentView?.prepareForInterfaceBuilder()
    }
    
    func xibSetup() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "IXStakeProgressView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        
        backBar.backgroundColor = backBarColor
        stakedBar.backgroundColor = stakedColor
        votedBar.backgroundColor = votedColor
        backBar.corner(backBar.frame.height / 2)
        stakedBar.corner(stakedBar.frame.height / 2)
        votedBar.corner(votedBar.frame.height / 2)
        votedBar.border(2, stakedColor)
    }
    
    func refreshBar() {
        stakedWidth.constant = self.frame.width * CGFloat(staked)
        votedWidth.constant = self.frame.width * CGFloat(voted)
    }
}
