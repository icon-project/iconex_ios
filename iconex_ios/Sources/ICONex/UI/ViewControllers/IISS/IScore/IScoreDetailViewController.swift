//
//  IScoreDetailViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 13/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import BigInt

class IScoreDetailViewController: BaseViewController {
    @IBOutlet weak var navBar: IXNavigationView!
    @IBOutlet weak var contentScroll: UIScrollView!
    @IBOutlet weak var IScoreHeader1: UILabel!
    @IBOutlet weak var currentIScoreValue: UILabel!
    @IBOutlet weak var IScoreHeader2: UILabel!
    @IBOutlet weak var receiveICXValue: UILabel!
    @IBOutlet weak var descContainer: UIView!
    @IBOutlet weak var descHeader1: UILabel!
    @IBOutlet weak var descValue1: UILabel!
    @IBOutlet weak var descHeader2: UILabel!
    @IBOutlet weak var descValue2: UILabel!
    @IBOutlet weak var exchangedValue: UILabel!
    @IBOutlet weak var bottomContainer: UIView!
    @IBOutlet weak var claimButton: UIButton!
    
    var wallet: ICXWallet!
    
    var refreshControl: UIRefreshControl? = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        IScoreHeader1.size16(text: "IScoreDetail.Header1".localized, color: .gray77, weight: .medium, align: .left)
        IScoreHeader2.size16(text: "IScoreDetail.Header2".localized, color: .gray77, weight: .medium, align: .left)
        descContainer.border(0.5, .gray230)
        descContainer.backgroundColor = .gray250
        descHeader1.size12(text: "IScoreDetail.DescHeader1".localized, color: .gray128, weight: .light, align: .left)
        descHeader2.size12(text: "IScoreDetail.DescHeader2".localized, color: .gray128, weight: .light, align: .left)
        
        claimButton.lightMintRounded()
        claimButton.setTitle("IScoreDetail.Claim".localized, for: .normal)
        
        navBar.setLeft {
            self.navigationController?.popViewController(animated: true)
        }
        
        currentIScoreValue.set(text: "-", size: 24, height: 24, color: .mint1, weight: .regular, align: .right)
        receiveICXValue.set(text: "-", size: 24, height: 24, color: .mint1, weight: .regular, align: .right)
        descValue1.size14(text: BigUInt(100_000).toString(decimal: 0).currencySeparated() + " / " + BigUInt(100_000).convert(unit: .gLoop).toString(decimal: 18, 18, true).currencySeparated(), color: UIColor(51, 51, 51), weight: .regular, align: .right)
        descValue2.size14(text: "", color: UIColor(51, 51, 51), weight: .regular, align: .right)
        exchangedValue.size12(text: "$", color: .gray179, weight: .regular, align: .right)
        
        claimButton.isEnabled = false
        
        contentScroll.refreshControl = refreshControl
        refreshControl?.beginRefreshing()
        
    }
    
    override func refresh() {
        super.refresh()
        
        navBar.setTitle(wallet.name)
        if refreshControl != nil {
            run()
        }
        let score = Manager.icon.iconService.getScoreAPI(scoreAddress: CONST.iiss).execute()
        switch score {
        case .success(let result):
            result.forEach { Log("API - \($0.name)") }
            
        case .failure(let error):
            Log("Error - \(error)")
        }
        
    }
    
    func run() {
        DispatchQueue.global().async {
            let response = Manager.icon.queryIScore(from: self.wallet)
            DispatchQueue.main.async { [weak self] in
                if let resp = response {
                    self?.currentIScoreValue.set(text: resp.iscore.toString(decimal: 18), size: 24, height: 24, color: .mint1, weight: .regular, align: .right)
                }
                self?.refreshControl?.endRefreshing()
                self?.refreshControl = nil
                self?.contentScroll.refreshControl = nil
            }
        }
    }
}
