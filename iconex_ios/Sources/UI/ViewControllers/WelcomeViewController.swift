//
//  WelcomeViewController.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var buttonCreateWallet: UIButton!
    @IBOutlet weak var buttonLoadWallet: UIButton!
    
    @IBOutlet weak var page1Label: UILabel!
    @IBOutlet weak var page2Label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initializeUI() {
        page1Label.text = Localized(key: "Welcome.Instruction.1")
        page2Label.text = Localized(key: "Welcome.Instruction.2")
        
        buttonCreateWallet.setTitle(Localized(key: "Wallet.Create"), for: .normal)
        buttonCreateWallet.rounded()
        buttonCreateWallet.border(1, UIColor.white)
        buttonLoadWallet.setTitle(Localized(key: "Wallet.Load"), for: .normal)
        buttonLoadWallet.rounded()
        buttonLoadWallet.border(1, UIColor.white)
        
        pageControl.numberOfPages = 2
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x == 0 {
            pageControl.currentPage = 0
        } else {
            pageControl.currentPage = 1
        }
    }
}
