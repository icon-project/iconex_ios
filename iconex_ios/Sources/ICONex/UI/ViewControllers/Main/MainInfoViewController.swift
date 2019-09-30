//
//  MainInfoViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 30/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MainInfoViewController: PopableViewController {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        let color = UIColor.gray77
        let titleFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let bodyFont = UIFont.systemFont(ofSize: 14, weight: .light)
        let lineBreak = NSAttributedString(string: "\n")
        
        let generalTitle = NSAttributedString(string: "Main.Info.About.Title1".localized, attributes: [.foregroundColor: color, .font: titleFont])
        let generalDesc = NSAttributedString(string: "Main.Info.About.Desc1".localized, attributes: [.foregroundColor: color, .font: bodyFont])
        let stakeTitle = NSAttributedString(string: "Main.Info.About.Title2".localized, attributes: [.foregroundColor: color, .font: titleFont])
        let stakeDesc = NSAttributedString(string: "Main.Info.About.Desc2".localized, attributes: [.foregroundColor: color, .font: bodyFont])
        let voteTitle = NSAttributedString(string: "Main.Info.About.Title3".localized, attributes: [.foregroundColor: color, .font: titleFont])
        let voteDesc = NSAttributedString(string: "Main.Info.About.Desc3".localized, attributes: [.foregroundColor: color, .font: bodyFont])
        let iscoreTitle = NSAttributedString(string: "Main.Info.About.Title4".localized, attributes: [.foregroundColor: color, .font: titleFont])
        let iscoreDesc = NSAttributedString(string: "Main.Info.About.Desc4".localized, attributes: [.foregroundColor: color, .font: bodyFont])
        
        let mut = NSMutableAttributedString(attributedString: generalTitle)
        mut.append(lineBreak)
        mut.append(generalDesc)
        mut.append(lineBreak)
        mut.append(lineBreak)
        mut.append(stakeTitle)
        mut.append(lineBreak)
        mut.append(stakeDesc)
        mut.append(lineBreak)
        mut.append(lineBreak)
        mut.append(voteTitle)
        mut.append(lineBreak)
        mut.append(voteDesc)
        mut.append(lineBreak)
        mut.append(lineBreak)
        mut.append(iscoreTitle)
        mut.append(lineBreak)
        mut.append(iscoreDesc)
        mut.append(lineBreak)
        
        textView.attributedText = mut
        
        titleContainer.set(title: "About")
        titleContainer.actionHandler = {
            self.dismiss(animated: true, completion: nil)
        }
        
        closeButton.gray77round()
        closeButton.setTitle("Common.Close".localized, for: .normal)
        closeButton.rx.tap.subscribe(onNext: {
            self.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }
}
