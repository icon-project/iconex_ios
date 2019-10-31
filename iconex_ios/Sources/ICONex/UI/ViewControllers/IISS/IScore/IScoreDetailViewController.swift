//
//  IScoreDetailViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 13/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import BigInt
import ICONKit
import RxSwift
import RxCocoa

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
    
    var key: PrivateKey!
    
    var refreshControl: UIRefreshControl? = UIRefreshControl()
    
    private var iscore: IScoreClaimInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        IScoreHeader1.size16(text: "IScoreDetail.Header1".localized, color: .gray77, weight: .medium, align: .left)
        IScoreHeader2.size16(text: "IScoreDetail.Header2".localized, color: .gray77, weight: .medium, align: .left)
        descContainer.border(0.5, .gray230)
        descContainer.corner(8)
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
        descValue1.adjustsFontSizeToFitWidth = true
        descValue2.size14(text: "-", color: UIColor(51, 51, 51), weight: .regular, align: .right)
        exchangedValue.size12(text: "$ -", color: .gray179, weight: .regular, align: .right)
        
        claimButton.isEnabled = false
        
        contentScroll.refreshControl = refreshControl
        refreshControl?.beginRefreshing()
        refreshControl?.addTarget(self, action: #selector(run), for: .valueChanged)
        
        claimButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                guard let info = self.iscore else { return }
                
                let stepPrice: BigUInt? = {
                    guard let stepPrice = Manager.icon.stepPrice else {
                        return Manager.icon.getStepPrice()
                    }
                    return stepPrice
                }()
                
                guard let balance = Manager.icon.getBalance(wallet: self.wallet), let price = stepPrice else {
                    Toast.toast(message: "Error.CommonError".localized)
                    return
                }
                
                let estimatedFee = info.stepLimit * price
                
                if estimatedFee > balance {
                    Alert.basic(title: "Send.Error.InsufficientFee.ICX".localized, leftButtonTitle: "Common.Confirm".localized).show()
                    return
                }
                
                Alert.iScore(iscoreInfo: info, confirmAction: {
                    DispatchQueue.global().async {
                        
                        let response = Manager.icon.claimIScore(from: self.wallet, limit: info.stepLimit, privateKey: self.key)
                        
                        DispatchQueue.main.async {
                            if response != nil {
                                Log("txHash - \(response!)")
                                Manager.balance.getAllBalances()
                                Toast.toast(message: "ISCoreDetail.ClaimSuccess".localized)
                                self.navigationController?.popToRootViewController(animated: true)
                            } else {
                                Toast.toast(message: "Error.CommonError".localized)
                            }
                        }
                    }
                    
                }).show()
            }).disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        
        navBar.setTitle(wallet.name)
        if refreshControl != nil {
            run()
        }
    }
    
    @objc func run() {
        DispatchQueue.global().async {
            let response = Manager.icon.queryIScore(from: self.wallet)
            
            
            let call = CallTransaction()
            call.from = self.wallet.address
            call.to = CONST.iiss
            call.method("claimIScore")
            call.params([:])
            call.nid = Manager.icon.iconService.nid
            
            let result = Manager.icon.iconService.estimateStep(transaction: call).execute()
            let estimatedStep: BigUInt? = {
                do {
                    let value = try result.get()
                    return value
                } catch {
                    Log("Error - \(error)")
                    return nil
                }
            }()
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                [weak self] in
                self?.refreshControl?.endRefreshing()
                
                if let resp = response {
                    self?.currentIScoreValue.set(text: resp.iscore.toString(decimal: 18, 15), size: 24, height: 24, color: .mint1, weight: .regular, align: .right)
                    
                    self?.receiveICXValue.set(text: (resp.iscore != 0 ? resp.iscore / 1000 : 0).toString(decimal: 18, 8), size: 24, height: 24, color: .mint1, weight: .regular, align: .right)
                    
                    let estimated = (estimatedStep ?? 0) * (Manager.icon.stepPrice ?? 0)
                    
                    self?.descValue1.size14(text: (estimatedStep ?? 0).toString(decimal: 0).currencySeparated() + " / " + (Manager.icon.stepPrice ?? 0).toString(decimal: 18, 18, true).currencySeparated(), color: UIColor(51, 51, 51), weight: .regular, align: .right)
                    self?.descValue2.size14(text: estimated.toString(decimal: 18, 18, true).currencySeparated(), color: UIColor(51, 51, 51), weight: .regular, align: .right)
                    self?.exchangedValue.size12(text: "$ " + (estimated.exchange(from: "icx", to: "usd")?.toString(decimal: 18, 2, false).currencySeparated() ?? "-"), color: .gray179, weight: .regular, align: .right)
                    
                    let stepPrice = Manager.icon.stepPrice?.toString(decimal: 18, 18, true).currencySeparated() ?? "-"
                    
                    let iscoreInfo = IScoreClaimInfo(currentIScore: resp.iscore.toString(decimal: 18, 15), youcanReceive: (resp.iscore != 0 ? resp.iscore / 1000 : 0).toString(decimal: 18, 8), stepLimit: estimatedStep ?? BigUInt.zero, stepPrice: stepPrice, estimatedFee: estimated.toString(decimal: 18, 18, true).currencySeparated(), estimateUSD:  "$ " + (estimated.exchange(from: "icx", to: "usd")?.toString(decimal: 18, 2, false).currencySeparated() ?? "-"))
                    
                    self?.iscore = iscoreInfo
                    
                    self?.claimButton.isEnabled = true
                } else {
                    Alert.basic(title: "Error.Fail.Downloading".localized, leftButtonTitle: "Common.Confirm".localized).show()
                    self?.claimButton.isEnabled = false
                    
                }
            }
        }
    }
}
