//
//  TestViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 23/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TestViewController: BaseViewController {
    
    @IBOutlet weak var testButton: UIButton!
    @IBOutlet weak var testButton2: UIButton!
    @IBOutlet weak var testButton3: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        testButton.rx.tap.subscribe(onNext: {
            guard let wallet = Manager.wallet.walletList.first as? ICXWallet else { return }
            let stake = UIStoryboard(name: "Stake", bundle: nil).instantiateInitialViewController() as! StakeViewController
            stake.wallet = wallet
            self.navigationController?.pushViewController(stake, animated: true)
        }).disposed(by: disposeBag)
        
        testButton2.rx.tap.subscribe(onNext: {
            guard let wallet = Manager.wallet.walletList.first as? ICXWallet else { return }
            let iscore = UIStoryboard(name: "IScore", bundle: nil).instantiateInitialViewController() as! IScoreDetailViewController
            iscore.wallet = wallet
            self.navigationController?.pushViewController(iscore, animated: true)
        }).disposed(by: disposeBag)
        
        testButton3.rx.tap.subscribe(onNext: {
            guard let wallet = Manager.wallet.walletList.first as? ICXWallet else { return }
            let vote = UIStoryboard(name: "Vote", bundle: nil).instantiateInitialViewController() as! VoteMainViewController
            vote.wallet = wallet
            self.navigationController?.pushViewController(vote, animated: true)
        }).disposed(by: disposeBag)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
