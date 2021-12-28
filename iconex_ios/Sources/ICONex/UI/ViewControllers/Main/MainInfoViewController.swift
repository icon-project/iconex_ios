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
//    @IBOutlet weak var textView: UITextView!
    private var textView: UITextView!
    @IBOutlet weak var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = false
        tv.showsVerticalScrollIndicator = false
        tv.showsHorizontalScrollIndicator = false
        tv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tv)
        tv.topAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: 30).isActive = true
        tv.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30).isActive = true
        tv.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30).isActive = true
        tv.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -66).isActive = true
        tv.bottomAnchor.constraint(equalTo: actionContainer.topAnchor).isActive = true
        self.textView = tv
        
        let color = UIColor.gray77
        let titleFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        let bodyFont = UIFont.systemFont(ofSize: 14, weight: .light)
        let lineBreak = NSAttributedString(string: "\n")
        
        let generalTitle = NSAttributedString(string: "Main.Info.About.AllAssets.Title".localized, attributes: [.foregroundColor: color, .font: titleFont])
        let generalDesc = NSAttributedString(string: "Main.Info.About.AllAssets.Desc".localized, attributes: [.foregroundColor: color, .font: bodyFont])
        let prepTitle = NSAttributedString(string: "Main.Info.About.Prep.Title".localized, attributes: [.foregroundColor: color, .font: titleFont])
        let prepDesc = NSAttributedString(string: "Main.Info.About.Prep.Desc".localized, attributes: [.foregroundColor: color, .font: bodyFont])
        let stakeTitle = NSAttributedString(string: "Main.Info.About.Stake.Title".localized, attributes: [.foregroundColor: color, .font: titleFont])
        let stakeDesc = NSAttributedString(string: "Main.Info.About.Stake.Desc".localized, attributes: [.foregroundColor: color, .font: bodyFont])
        let voteTitle = NSAttributedString(string: "Main.Info.About.Vote.Title".localized, attributes: [.foregroundColor: color, .font: titleFont])
        let voteDesc = NSAttributedString(string: "Main.Info.About.Vote.Desc".localized, attributes: [.foregroundColor: color, .font: bodyFont])
        let iscoreTitle = NSAttributedString(string: "Main.Info.About.IScore.Title".localized, attributes: [.foregroundColor: color, .font: titleFont])
        let iscoreDesc = NSAttributedString(string: "Main.Info.About.IScore.Desc".localized, attributes: [.foregroundColor: color, .font: bodyFont])
        
        let mut = NSMutableAttributedString(attributedString: generalTitle)
        mut.append(lineBreak)
        mut.append(generalDesc)
        mut.append(lineBreak)
        mut.append(lineBreak)
        mut.append(prepTitle)
        mut.append(lineBreak)
        mut.append(prepDesc)
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
        
        closeButton.round02()
        closeButton.setTitle("Common.Close".localized, for: .normal)
        closeButton.rx.tap.subscribe(onNext: {
            self.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }
}
