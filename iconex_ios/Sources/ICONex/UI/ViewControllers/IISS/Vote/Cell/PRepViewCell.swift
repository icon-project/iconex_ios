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
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var prepNameLabel: UILabel!
    @IBOutlet weak var prepTypeLabel: UILabel!
    @IBOutlet weak var totalVoteLabel: UILabel!
    @IBOutlet weak var totalVoteValue: UILabel!
    @IBOutlet weak var totalVotePercent: UILabel!
    @IBOutlet weak var tooltipContainer: UIView!
    @IBOutlet weak var prepTooltip: UIView!
    @IBOutlet weak var prepTooltipLabel: UILabel!
    @IBOutlet weak var prepTooltipButton: UIButton!
    
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
        
        addButton.setImage(#imageLiteral(resourceName: "icAddListEnabled"), for: .normal)
        addButton.setImage(#imageLiteral(resourceName: "icAddListDisabled"), for: .selected)
        
        prepTooltip.corner(8)
        prepTooltipLabel.setLinespace(spacing: 3.5)
        prepTooltipLabel.text = "PRepView.ToolTip.Exist".localized
        
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0, y: 4))
        bezierPath.addLine(to: CGPoint(x:8, y: 0))
        bezierPath.addLine(to: CGPoint(x: 8, y: 8))
        bezierPath.close()
        
        let triangle = CAShapeLayer()
        triangle.path = bezierPath.cgPath
        triangle.frame = CGRect(x: 0, y: 0, width: 8, height: 8)
        triangle.fillColor = UIColor(38, 38, 38, 0.9).cgColor
        
        let triView = UIView()
        triView.backgroundColor = .clear
        triView.translatesAutoresizingMaskIntoConstraints = false
        triView.layer.addSublayer(triangle)
        tooltipContainer.addSubview(triView)
        triView.leadingAnchor.constraint(equalTo: tooltipContainer.leadingAnchor, constant: -8).isActive = true
        triView.widthAnchor.constraint(equalToConstant: 8).isActive = true
        triView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        triView.centerYAnchor.constraint(equalTo: prepTooltip.centerYAnchor).isActive = true
        tooltipContainer.isHidden = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        rankLabel.isHidden = false
        prepTypeLabel.isHidden = false
        totalVotePercent.isHidden = false
        tooltipContainer.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
