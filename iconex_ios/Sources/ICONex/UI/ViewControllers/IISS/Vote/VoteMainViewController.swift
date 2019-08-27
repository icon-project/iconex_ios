//
//  VoteMainViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 22/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol VoteMainDelegate {
    var wallet: ICXWallet! { get set }
    func headerSelected(index: Int)
}

class VoteMainViewController: BaseViewController, VoteMainDelegate {
    @IBOutlet weak var navBar: IXNavigationView!
    @IBOutlet weak var prepContainer: UIView!
    @IBOutlet weak var myvoteContainer: UIView!
    @IBOutlet weak var buttonConatiner: UIView!
    @IBOutlet weak var voteButton: UIButton!
    @IBOutlet weak var bottomHeight: NSLayoutConstraint!
    
    var wallet: ICXWallet!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        navBar.setTitle(wallet.name)
        navBar.setLeft {
            self.navigationController?.popViewController(animated: true)
        }
        
        prepContainer.isHidden = true
        myvoteContainer.isHidden = false
        
        buttonConatiner.backgroundColor = .gray252
        voteButton.lightMintRounded()
        voteButton.setTitle("Vote", for: .normal)
        voteButton.isEnabled = false
        
        children.forEach({
            if let myVote = $0 as? MyVoteViewController {
                myVote.delegate = self
            } else if let prep = $0 as? PRepsViewController {
                prep.delegate = self
            }
        })
    }
}

extension VoteMainViewController {
    func headerSelected(index: Int) {
        prepContainer.isHidden = index == 0
        myvoteContainer.isHidden = index != 0
        bottomHeight.constant = index == 0 ? 66 : 0
    }
}
