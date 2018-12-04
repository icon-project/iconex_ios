//
//  MainViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

enum SwipeDirection {
    case left
    case right
    case center
}

class MainViewController: BaseViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate {

    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var topInfoButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var navSelectorContainer: UIView!
    @IBOutlet weak var navSelector1: UIButton!
    @IBOutlet weak var navSelector2: UIButton!
    @IBOutlet weak var balanceInfoLabel: UILabel!
    @IBOutlet weak var totalBalanceLabel: UILabel!
    @IBOutlet weak var totalLoader: UIImageView!
    @IBOutlet weak var usdButton: UIButton!
    @IBOutlet weak var btcButton: UIButton!
    @IBOutlet weak var ethButton: UIButton!
    
    @IBOutlet weak var walletTagScroll: UIScrollView!
    @IBOutlet weak var walletScroll: UIScrollView!
    @IBOutlet weak var walletStack: UIStackView!
    
    var startPoint: CGFloat = 0
    var lastOffset: CGFloat = 0
    var fixedHeight: CGFloat = 0
    var currentIndex: Int = 0
    private var navSelected: Int = 0 {
        willSet {
            if newValue == 0 {
                navSelector1.isSelected = true
                navSelector2.isSelected = false
            } else {
                navSelector1.isSelected = false
                navSelector2.isSelected = true
            }
            Preference.shared.navSelected = newValue
        }
    }
    
    private var selectedExchange: Int = 0 {
        willSet {
            switch newValue {
            case 0:
                usdButton.isSelected = true
                btcButton.isSelected = false
                ethButton.isSelected = false
                EManager.currentExchange = "usd"
                
            case 1:
                usdButton.isSelected = false
                btcButton.isSelected = true
                ethButton.isSelected = false
                EManager.currentExchange = "btc"
                
            case 2:
                usdButton.isSelected = false
                btcButton.isSelected = false
                ethButton.isSelected = true
                EManager.currentExchange = "eth"
                
            default:
                break
            }
            
            if WManager.isBalanceLoadCompleted {
                self.totalLoader.isHidden = true
                self.totalBalanceLabel.isHidden = false
                let exchanged = String(format: EManager.currentExchange == "usd" ? "%.2f" : "%.4f", WManager.getTotalBalances())
                let attr = NSAttributedString(string: exchanged.currencySeparated(), attributes: [.kern: -2.0])
                self.totalBalanceLabel.attributedText = attr
            } else {
                self.totalLoader.isHidden = false
                self.totalBalanceLabel.isHidden = true
                Tools.rotateAnimation(inView: self.totalLoader)
            }
        }
        
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "kNotificationExchangeIndicatorChanged"), object: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        languageChanged()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        WManager.getWalletsBalance()
        loadWallets()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fixedHeight = heightConstraint.constant
        
        if WManager.isBalanceLoadCompleted {
            self.totalLoader.isHidden = true
            self.totalBalanceLabel.isHidden = false
            let exchanged = String(format: EManager.currentExchange == "usd" ? "%.2f" : "%.4f", WManager.getTotalBalances())
            let attr = NSAttributedString(string: exchanged.currencySeparated(), attributes: [.kern: -2.0])
            self.totalBalanceLabel.attributedText = attr
        } else {
            self.totalLoader.isHidden = false
            self.totalBalanceLabel.isHidden = true
            Tools.rotateAnimation(inView: self.totalLoader)
        }
    }
    
    func initialize() {
        topInfoButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                Alert.Basic(message: "Alert.TotalAssetInfo".localized).show(self)
            }).disposed(by: disposeBag)
        
        navSelector1.rx.controlEvent(UIControlEvents.touchDown).subscribe(onNext: { [unowned self] in
            self.navSelector1.cancelTracking(with: nil)
            self.navSelected = 0
            self.currentIndex = 0
            self.loadWallets()
            
        }).disposed(by: disposeBag)
        
        navSelector2.rx.controlEvent(UIControlEvents.touchDown).subscribe(onNext: { [unowned self] in
            self.navSelector2.cancelTracking(with: nil)
            self.navSelected = 1
            self.currentIndex = 0
            self.loadWallets()
            
        }).disposed(by: disposeBag)
        
        usdButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.selectedExchange = 0
        }).disposed(by: disposeBag)
        
        btcButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.selectedExchange = 1
        }).disposed(by: disposeBag)
        
        ethButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.selectedExchange = 2
        }).disposed(by: disposeBag)
        
        walletScroll.rx.didEndDecelerating.observeOn(MainScheduler.instance).subscribe(onNext: {
            let index = Int(self.walletScroll.contentOffset.x / UIScreen.main.bounds.width)
            self.scrollWallet(to: index)
            self.currentIndex = index
        }).disposed(by: disposeBag)
        
        
        menuButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { 
            let menu = UIStoryboard(name: "Menu", bundle: nil).instantiateViewController(withIdentifier: "MainMenu") as! MainMenuViewController
            menu.delegate = self
            menu.present(from: self, delegate: nil)
        }).disposed(by: disposeBag)
        
        exchangeListDidChanged().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                if WManager.isBalanceLoadCompleted {
                    self.totalLoader.isHidden = true
                    self.totalBalanceLabel.isHidden = false
                    let exchanged = String(format: EManager.currentExchange == "usd" ? "%.2f" : "%.4f", WManager.getTotalBalances())
                    let attr = NSAttributedString(string: exchanged.currencySeparated(), attributes: [.kern: -2.0])
                    self.totalBalanceLabel.attributedText = attr
                } else {
                    self.totalLoader.isHidden = false
                    self.totalBalanceLabel.isHidden = true
                    Tools.rotateAnimation(inView: self.totalLoader)
                }
            }).disposed(by: disposeBag)
        
        balanceListDidChanged().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                if WManager.isBalanceLoadCompleted {
                    self.totalLoader.isHidden = true
                    self.totalBalanceLabel.isHidden = false
                    let exchanged = String(format: EManager.currentExchange == "usd" ? "%.2f" : "%.4f", WManager.getTotalBalances())
                    let attr = NSAttributedString(string: exchanged.currencySeparated(), attributes: [.kern: -2.0])
                    self.totalBalanceLabel.attributedText = attr
                } else {
                    self.totalLoader.isHidden = false
                    self.totalBalanceLabel.isHidden = true
                    Tools.rotateAnimation(inView: self.totalLoader)
                }
            }).disposed(by: disposeBag)
    }
    
    override func languageChanged() {
        balanceInfoLabel.textColor = UIColor(255, 255, 255, 0.5)
        balanceInfoLabel.text = "Main.TotalAssets".localized
        totalBalanceLabel.attributedText = NSAttributedString(string: "-")
        
        fixedHeight = heightConstraint.constant
        
        navSelectorContainer.corner(navSelectorContainer.frame.height / 2)
        navSelectorContainer.border(1, UIColor.white)
        
        navSelector1.setTitleColor(UIColor.white, for: .normal)
        navSelector1.setTitleColor(UIColor.lightTheme.background.normal, for: .selected)
        navSelector1.setBackgroundImage(color: UIColor.lightTheme.background.normal, state: .normal)
        navSelector1.setBackgroundImage(color: UIColor.clear, state: .highlighted)
        navSelector1.setBackgroundImage(color: UIColor.white, state: .selected)
        navSelector1.setTitle("Main.Sort.Wallet".localized, for: .normal)
        navSelector1.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        navSelector2.setTitleColor(UIColor.white, for: .normal)
        navSelector2.setTitleColor(UIColor.lightTheme.background.normal, for: .selected)
        navSelector2.setBackgroundImage(color: UIColor.lightTheme.background.normal, state: .normal)
        navSelector2.setBackgroundImage(color: UIColor.clear, state: .highlighted)
        navSelector2.setBackgroundImage(color: UIColor.white, state: .selected)
        navSelector2.setTitle("Main.Sort.Coins".localized, for: .normal)
        navSelector2.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        
        usdButton.setTitleColor(UIColor(255, 255, 255, 0.5), for: .normal)
        usdButton.setTitleColor(UIColor.lightTheme.background.normal, for: .selected)
        usdButton.setTitle("USD", for: .normal)
        usdButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        usdButton.setBackgroundImage(color: UIColor.clear, state: .normal)
        usdButton.setBackgroundImage(color: UIColor.clear, state: .highlighted)
        usdButton.setBackgroundImage(color: UIColor.white, state: .selected)
        usdButton.corner(usdButton.frame.size.height / 2)
        btcButton.setTitleColor(UIColor(255, 255, 255, 0.5), for: .normal)
        btcButton.setTitleColor(UIColor.lightTheme.background.normal, for: .selected)
        btcButton.setTitle("BTC", for: .normal)
        btcButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        btcButton.setBackgroundImage(color: UIColor.clear, state: .normal)
        btcButton.setBackgroundImage(color: UIColor.clear, state: .highlighted)
        btcButton.setBackgroundImage(color: UIColor.white, state: .selected)
        btcButton.corner(btcButton.frame.size.height / 2)
        ethButton.setTitleColor(UIColor(255, 255, 255, 0.5), for: .normal)
        ethButton.setTitleColor(UIColor.lightTheme.background.normal, for: .selected)
        ethButton.setTitle("ETH", for: .normal)
        ethButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        ethButton.setBackgroundImage(color: UIColor.clear, state: .normal)
        ethButton.setBackgroundImage(color: UIColor.clear, state: .highlighted)
        ethButton.setBackgroundImage(color: UIColor.white, state: .selected)
        ethButton.corner(ethButton.frame.size.height / 2)
        
        self.navSelected = 0
        self.selectedExchange = 0
        self.currentIndex = 0
    }
    
    func loadWallets() {
        setWalletTag()
        setWallet()
        
        scrollWallet(to: self.currentIndex)
    }
    
    func setWalletTag() {
        let leading: CGFloat = 16
        let margin: CGFloat = 4
        
        var x: CGFloat = leading
        
        for view in walletTagScroll.subviews {
            view.removeFromSuperview()
        }
        
        if navSelected != 0 {
            let count = WManager.countOfWalletType
            
            for i in 0..<count {
                let type = WManager.walletTypes()[i]
                var coinName = ""
                if type == "icx" {
                    coinName = "ICON"
                } else if type == "eth" {
                    coinName = "Ethereum"
                }
                
                var expectedSize = coinName.boundingRect(size: CGSize(width: 999, height: 16), font: UIFont.systemFont(ofSize: 14))
                expectedSize.width = expectedSize.width + 40
                
                let button = makeShortCut(frame: CGRect(x: x, y: CGFloat(15.0), width: expectedSize.width, height: CGFloat(26)), tag: i, title: coinName)
                
                walletTagScroll.addSubview(button)
                
                x = x + expectedSize.width + margin
            }
            
            let tokens = WManager.tokenTypes()
            for i in 0..<tokens.count {
                let item = tokens[i]
                var walletName = item.symbol.uppercased() + " Token"
                if item.symbol.lowercased() == "icx" {
                    walletName = "ICON Token"
                }
                
                var expectedSize = walletName.boundingRect(size: CGSize(width: 999, height: 16), font: UIFont.systemFont(ofSize: 14))
                expectedSize.width = expectedSize.width + 40
                
                let button = makeShortCut(frame: CGRect(x: x, y: CGFloat(15.0), width: expectedSize.width, height: CGFloat(26)), tag: count + i, title: walletName)
                
                walletTagScroll.addSubview(button)
                
                x = x + expectedSize.width + margin
            }
            x = x + margin
            
            walletTagScroll.contentSize = CGSize(width: x, height: walletTagScroll.frame.size.height)
        } else {
            
            let lists = WManager.walletInfoList
            let count = lists.count
            
            for i in 0..<count {
                let item = lists[i]
                
                var walletName: String = ""
                if item.type == .icx {
                    let wallet = WManager.loadWalletBy(info: item) as! ICXWallet
                    walletName = wallet.alias!
                } else if item.type == .eth {
                    let wallet = WManager.loadWalletBy(info: item) as! ETHWallet
                    walletName = wallet.alias!
                }
                
                var expectedSize = walletName.boundingRect(size: CGSize(width: 999, height: 16), font: UIFont.systemFont(ofSize: 14))
                expectedSize.width = expectedSize.width + 40
                
                let button = makeShortCut(frame: CGRect(x: x, y: CGFloat(15.0), width: expectedSize.width, height: CGFloat(26)), tag: i, title: walletName)
                
                walletTagScroll.addSubview(button)
                
                x = x + expectedSize.width + margin
                
            }
            x = x + margin
            
            walletTagScroll.contentSize = CGSize(width: x, height: walletTagScroll.frame.size.height)
        }
    }
    
    func setWallet() {
        let width = walletScroll.frame.width
        for view in walletStack.subviews {
            view.removeFromSuperview()
        }
        if navSelected == 0 {
            let list = WManager.walletInfoList
            
            var count: CGFloat = 0
            for info in list {
                let walletView = Bundle.main.loadNibNamed("MainWalletView", owner: nil, options: nil)![0] as! MainWalletView
                walletView.setWalletInfo(walletInfo: info)
                walletView.translatesAutoresizingMaskIntoConstraints = false
                walletView.addConstraints([
                    NSLayoutConstraint(item: walletView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width)
                    ])
                walletStack.addArrangedSubview(walletView)
                count += 1
            }
        } else {
            let list = WManager.walletTypes()
            var count: CGFloat = 0
            for type in list {
                let walletView = Bundle.main.loadNibNamed("MainWalletView", owner: nil, options: nil)![0] as! MainWalletView
                guard let info = WManager.coinInfoListBy(coin: COINTYPE(rawValue: type)!) else {
                    continue
                }
                walletView.setWalletInfo(coin: info)
                walletView.translatesAutoresizingMaskIntoConstraints = false
                walletView.addConstraints([
                    NSLayoutConstraint(item: walletView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width)
                    ])
                walletStack.addArrangedSubview(walletView)
                count += 1
            }
            let tokens = WManager.tokenTypes()
            for token in tokens {
                let walletView = Bundle.main.loadNibNamed("MainWalletView", owner: nil, options: nil)![0] as! MainWalletView
                walletView.setWalletInfo(token: token)
                walletView.translatesAutoresizingMaskIntoConstraints = false
                walletView.addConstraints([
                    NSLayoutConstraint(item: walletView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width)
                    ])
                walletStack.addArrangedSubview(walletView)
                count += 1
            }
        }
    }
    
    func makeShortCut(frame: CGRect, tag: Int, title: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.frame = frame
        button.tag = tag
        button.setTitle(title, for: .normal)
        button.setBackgroundImage(color: UIColor.clear, state: .normal)
        button.setTitleColor(UIColor(255, 255, 255, 0.5), for: .normal)
        button.setBackgroundImage(color: UIColor.white, state: .selected)
        button.setTitleColor(UIColor.lightTheme.background.normal, for: .selected)
        button.addTarget(self, action: #selector(clickedWalletItem(_ :)), for: .touchUpInside)
        button.rounded()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return button
    }
    
    func scrollWallet(to: Int) {
        var rect: CGRect = .zero
        for sub in walletTagScroll.subviews {
            let button = sub as! UIButton
            if button.tag == to {
                button.isSelected = true
                rect = button.frame
            } else {
                button.isSelected = false
            }
        }

        let visible = CGRect(x: rect.origin.x - rect.size.width / 2, y: 0, width: rect.size.width * 2, height: rect.size.height)
        walletTagScroll.scrollRectToVisible(visible, animated: true)
        
        walletScroll.scrollRectToVisible(CGRect(x: CGFloat(to) * walletScroll.frame.width, y: 0, width: walletScroll.frame.width, height: walletScroll.frame.height), animated: true)
    }
    
    @IBAction func gesture(_ recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: view)
        
        switch recognizer.state {
        case .began:
            startPoint = point.y - topConstraint.constant
            
        case .changed:
            let value = point.y - startPoint
            if value > 0 {
                heightConstraint.constant = fixedHeight + min(value, fixedHeight) / 2
                topConstraint.constant = 0
            } else {
                let value = min(0, max(value, -228 + 20))
                topConstraint.constant = value
            }
            
        default:
            var value = point.y - startPoint
            
            if value > 0 {
                heightConstraint.constant = fixedHeight
            } else {
                if value > -120 {
                    value = 0
                } else {
                    value = -228 + 20
                }
                topConstraint.constant = value
            }

            UIView.animate(withDuration: 0.25, animations: {
                self.view.layoutIfNeeded()
            })
            
        }
    }
    
    @objc func clickedWalletItem(_ sender: UIButton) {
        scrollWallet(to: sender.tag)
        self.currentIndex = sender.tag
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
}

extension MainViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return Transition.FlipPopTransition(originFrame: view.frame)
    }
}

