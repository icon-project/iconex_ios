//
//  StartViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 01/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class StartViewController: BaseViewController {
    @IBOutlet weak var scroll: UIScrollView!
    @IBOutlet weak var pageImage1: UIImageView!
    @IBOutlet weak var pageLabel1: UILabel!
    @IBOutlet weak var pageImage2: UIImageView!
    @IBOutlet weak var pageLabel2: UILabel!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var page: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        page.isUserInteractionEnabled = false
        
        scroll.rx.didEndDecelerating.subscribe(onNext: { [unowned self] in
            self.page.currentPage = (Int)(self.scroll.contentOffset.x / self.scroll.frame.width)
        }).disposed(by: disposeBag)
        
        createButton.rx.tap.subscribe(onNext: {
            let create = UIStoryboard(name: "CreateWallet", bundle: nil).instantiateInitialViewController() as! CreateWalletViewController
            create.doneAction = {
                Manager.balance.getAllBalances()
                app.toMain()
            }
            create.pop()
        }).disposed(by: disposeBag)
        
        loadButton.rx.tap.subscribe(onNext: {
            let load = UIStoryboard(name: "LoadWallet", bundle: nil).instantiateInitialViewController() as! LoadWalletViewController
            load.doneAction = {
                app.toMain()
            }
            load.pop()
        }).disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        view.backgroundColor = .mint1
        pageImage1.image = #imageLiteral(resourceName: "imgHomescreen01")
        pageImage2.image = #imageLiteral(resourceName: "imgHomescreen02")
        pageLabel1.size14(text: "Start.Instruction.1".localized, color: .white, weight: .light, align: .center)
        pageLabel2.size14(text: "Start.Instruction.2".localized, color: .white, weight: .light, align: .center)
        
        createButton.mint()
        createButton.corner(12)
        createButton.setTitle("Start.CreateWallet".localized, for: .normal)
        loadButton.mint()
        loadButton.corner(12)
        loadButton.setTitle("Start.LoadWallet".localized, for: .normal)
        
        page.currentPageIndicatorTintColor = .white
        page.pageIndicatorTintColor = UIColor(255, 255, 255, 0.4)
    }
}
