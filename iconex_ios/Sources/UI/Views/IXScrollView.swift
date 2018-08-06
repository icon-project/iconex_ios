//
//  IXScrollView.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit

protocol ICXItemChangeDelegate {
    func indexForMainWallet() -> Int
    func changingOffset(x: CGFloat)
    func currentContraint() -> CGFloat
}

class IXScrollView: UIScrollView, UIScrollViewDelegate {

    var changeDelegate: ICXItemChangeDelegate?
    var currentIndex: Int = 0
    
    var navSelected: Int = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        loadWallets()
        self.delegate = self
    }
    
    func loadWallets(_ mode: Int? = nil) {
        if let selected = mode {
            navSelected = selected
        }
        
        for view in subviews {
            view.removeFromSuperview()
        }
        self.contentOffset = CGPoint(x: 0, y: 0)
        
        if navSelected == 0 {
            let list = WManager.walletInfoList
            var count: CGFloat = 0
            for info in list {
                var frame = self.bounds
                frame.size.width = UIScreen.main.bounds.width
                frame.origin.x = count * frame.width
                frame.origin.y = 0
                let walletView = Bundle.main.loadNibNamed("MainWalletView", owner: nil, options: nil)![0] as! MainWalletView
                walletView.setWalletInfo(walletInfo: info)
                walletView.frame = frame
                walletView.autoresizingMask = [.flexibleHeight]
                self.addSubview(walletView)
                count += 1
            }
            let size = CGSize(width: UIScreen.main.bounds.width * count, height: self.frame.height)
            self.contentSize = size
        } else {
            let list = WManager.walletTypes()
            var count: CGFloat = 0
            for type in list {
                var frame = self.bounds
                frame.size.width = UIScreen.main.bounds.width
                frame.origin.x = count * frame.width
                frame.origin.y = 0
                let walletView = Bundle.main.loadNibNamed("MainWalletView", owner: nil, options: nil)![0] as! MainWalletView
                walletView.autoresizingMask = [.flexibleHeight]
                guard let info = WManager.coinInfoListBy(coin: COINTYPE(rawValue: type)!) else {
                    continue
                }
                walletView.setWalletInfo(coin: info)
                walletView.frame = frame
                self.addSubview(walletView)
                count += 1
            }
            let tokens = WManager.tokenTypes()
            for token in tokens {
                var frame = self.bounds
                frame.size.width = UIScreen.main.bounds.width
                frame.origin.x = count * frame.width
                frame.origin.y = 0
                let walletView = Bundle.main.loadNibNamed("MainWalletView", owner: nil, options: nil)![0] as! MainWalletView
                walletView.autoresizingMask = [.flexibleHeight]
                walletView.setWalletInfo(token: token)
                walletView.frame = frame
                self.addSubview(walletView)
                count += 1
            }
            let size = CGSize(width: UIScreen.main.bounds.width * count, height: self.frame.height)
            self.contentSize = size
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let delegate = changeDelegate else { return }
        delegate.changingOffset(x: scrollView.contentOffset.x)
    }
    
    func topChanged(value: CGFloat) {
        for view in subviews {
            let walletView = view as! MainWalletView
            walletView.mainConstraintChanged(value: value)
        }
    }
    
}
