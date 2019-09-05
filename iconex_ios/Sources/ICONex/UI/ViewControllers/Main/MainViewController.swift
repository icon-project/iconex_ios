//
//  MainViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 02/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import BigInt

enum MainGesture {
    case cardUp, cardDown
}

private let Header_Height: CGFloat = 148

class MainViewController: BaseViewController, Floatable {
    @IBOutlet weak var navBar: IXNavigationView!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentTop: NSLayoutConstraint!
    @IBOutlet weak var backHeight: NSLayoutConstraint!
    @IBOutlet weak var contentHeight: NSLayoutConstraint!
    @IBOutlet weak var contentBottom: NSLayoutConstraint!
    @IBOutlet weak var cardTop: NSLayoutConstraint!
    
    // balance and power
    @IBOutlet weak var balanceAssetTitle: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var balanceLabel: UILabel!
    
    @IBOutlet weak var powerAssetTitle: UILabel!
    @IBOutlet weak var powerLabel: UILabel!
    
    // custom page control
    @IBOutlet weak var balancePageView: UIView!
    @IBOutlet weak var powerPageView: UIView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionFlowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var assetScrollView: UIScrollView!
    @IBOutlet weak var activityControl: UIActivityIndicatorView!
    
    @IBOutlet weak var balanceActivityIndicator: UIActivityIndicatorView!
    
    private var startPoint: CGPoint = .zero
    private var beforePoint: CGPoint = .zero
    private var isBigCard: Bool = false
    
    private let gradient = CAGradientLayer()
    
    var walletList = [BaseWalletConvertible]() {
        didSet {
            contentTop.constant = 0
            backHeight.constant = Header_Height
            contentBottom.constant = 0
        }
    }
    
    var selectedWallet: ICXWallet?
    
    var coinTokenList = [String: [BaseWalletConvertible]]()
    
    var symbolList = [String]()
    var tokenList: [Token] = DB.allTokenList()
    
    var isWalletMode: Bool = true {
        willSet {
            DispatchQueue.main.async {
                self.collectionView.setContentOffset(CGPoint.zero, animated: true)
                self.collectionView.reloadData()
            }
            
            navBar.setTitle(newValue ? "Main.Nav.Title.1".localized : "Main.Nav.Title.2".localized, isMain: true)
            
            guard !walletList.isEmpty else { return }
            pageControl.rx.numberOfPages.onNext(newValue ? self.walletList.count : self.symbolList.count)
        }
    }
    
    var currencyUnit: BalanceUnit = .USD {
        willSet {
            self.unitLabel.text = newValue.symbol
            mainViewModel.currencyUnit.onNext(newValue)
        }
    }
    
    var isCardUp: Bool = true
    
    // Floater
    var floater: Floater = {
        return Floater(type: .vote)
    }()
    
    override func initializeComponents() {
        super.initializeComponents()
        
        view.backgroundColor = .gray245
        backView.backgroundColor = UIColor(245, 245, 245)
        gradient.colors = [UIColor.mint1.cgColor, UIColor.gray245.cgColor]
        gradient.locations = [0.0, 1.0]
        gradientView.layer.addSublayer(gradient)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        self.contentView.addGestureRecognizer(panGesture)
        
        navBar.setTitle("Main.Nav.Title.1".localized, isMain: true)
        
        // nav toggle button
        navBar.setToggleButton {
            self.isWalletMode.toggle()
        }
        
        mainViewModel.reload
            .subscribe { (_) in
                var tmp = [String]()
                DispatchQueue.main.async {
                    self.balanceLabel.alpha = 0
                    self.balanceActivityIndicator.startAnimating()
                }
                
                self.walletList = Manager.wallet.walletList
                
                DispatchQueue.global().async {
                    Manager.balance.getAllBalances()
                }
                
                let list = Manager.balance.calculateExchangeTotalBalance()
                mainViewModel.balaneList.onNext(list)
                
                // COIN
                for type in Manager.wallet.types { // icx, eth....
                    guard let wallet = DB.walletListBy(type: type) else { return }
                    self.coinTokenList[type] = wallet
//                    self.symbolList.append(type)
                    tmp.append(type)
                }
                
                // TOKEN
                for token in self.tokenList {
                    self.coinTokenList[token.symbol] = DB.walletListBy(token: token)
//                    self.symbolList.append(token.symbol)
                    tmp.append(token.symbol)
                }
                
                self.symbolList = tmp
                
                DispatchQueue.main.async {
                    self.activityControl.stopAnimating()
                }
                
            }.disposed(by: disposeBag)
        
        mainViewModel.noti
            .observeOn(MainScheduler.instance)
            .subscribe { (_) in
                self.collectionView.reloadData()
        }.disposed(by: disposeBag)
        
        let balanceObservable = mainViewModel.totalExchangedBalance.share(replay: 1)
        
        balanceObservable
            .distinctUntilChanged()
            .bind(to: balanceLabel.rx.text)
            .disposed(by: disposeBag)
        
        balanceObservable
            .observeOn(MainScheduler.instance)
            .subscribe { (_) in
                DispatchQueue.main.async {
                    self.balanceLabel.alpha = 1
                    self.balanceActivityIndicator.stopAnimating()
                }
        }.disposed(by: disposeBag)
        
        // scrollview
        // 1
        balanceAssetTitle.text = "Main.Balance.Title".localized
        unitLabel.text = "USD"
        
        // 2
        powerAssetTitle.size16(text: "Main.Power.Title".localized, color: .init(white: 1, alpha: 0.6), weight: .light, align: .right)
        powerLabel.setBalanceAttr(text: "90.8%")
        
        toggleButton.rx.tap.asControlEvent().subscribe { (_) in
            switch self.currencyUnit {
            case .USD: self.currencyUnit = .BTC
            case .BTC: self.currencyUnit = .ETH
            case .ETH: self.currencyUnit = .USD
            default: return
            }
        }.disposed(by: disposeBag)
        
        pageControl.currentPageIndicatorTintColor = UIColor.init(white: 0, alpha: 0.7)
        pageControl.pageIndicatorTintColor = UIColor.init(white: 0, alpha: 0.2)
        pageControl.rx.numberOfPages.onNext(self.walletList.count)
        
        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarMenu")) {
            let menuVC = self.storyboard?.instantiateViewController(withIdentifier: "Menu") as! SideMenuViewController
            menuVC.modalPresentationStyle = .overFullScreen
            menuVC.modalTransitionStyle = .crossDissolve
            menuVC.action1 = {
                let createVC = UIStoryboard.init(name: "CreateWallet", bundle: nil).instantiateInitialViewController() as! CreateWalletViewController
                createVC.pop()
            }
            menuVC.action2 = {
                let loadVC = UIStoryboard.init(name: "LoadWallet", bundle: nil).instantiateInitialViewController() as! LoadWalletViewController
                loadVC.pop()
            }
            menuVC.action3 = {
                let exportVC = UIStoryboard(name: "Export", bundle: nil).instantiateInitialViewController() as! ExportMainViewController
                exportVC.pop()
            }
            menuVC.action4 = {
                
            }
            menuVC.action5 = {
                let version = UIStoryboard(name: "AppInfo", bundle: nil).instantiateInitialViewController()!
                self.navigationController?.pushViewController(version, animated: true)
            }
            menuVC.action6 = {
                let disclaimer = UIStoryboard(name: "Disclaimer", bundle: nil).instantiateInitialViewController() as! DisclaimerViewController
                disclaimer.pop()
            }
            self.present(menuVC, animated: true, completion: nil)
        }
        
        navBar.setRight(image: #imageLiteral(resourceName: "icInfoW")) {
            
        }
        
        balanceActivityIndicator.startAnimating()
        
        self.walletList = Manager.wallet.walletList
        
        self.balanceLabel.alpha = 0
        
        balancePageView.setCurrentPage()
        powerPageView.setNonCurrentPage()
        
        // custom pageControl
        assetScrollView.rx.contentOffset
            .subscribe(onNext: { (offset) in
                if offset.x == 0 {
                    self.balancePageView.setCurrentPage()
                    self.powerPageView.setNonCurrentPage()
                    
                    
                } else if offset.x == self.view.frame.width {
                    self.powerPageView.setCurrentPage()
                    self.balancePageView.setNonCurrentPage()
                }
                
            }).disposed(by: disposeBag)
        
        collectionView.rx.didEndDecelerating
            .subscribe(onNext: {
                if self.isWalletMode {
                    self.checkFloater()
                }
                
            }).disposed(by: disposeBag)
        
        self.collectionView.allowsSelection = false
        
        self.pageControl.rx.numberOfPages.onNext(self.walletList.count)
        
        collectionView.rx.didScroll.asControlEvent()
            .subscribe { (_) in
                let pageWidth = self.collectionView.frame.width
                let currentPage = Int((self.collectionView.contentOffset.x + pageWidth / 2) / pageWidth)
                self.pageControl.rx.currentPage.onNext(currentPage)
        }.disposed(by: disposeBag)
        
        floater.delegate = self
        floater.button.rx.tap
            .subscribe(onNext: {
                if let wallet = self.selectedWallet {
                    self.floater.showMenu(wallet: wallet, self)
                }
            }).disposed(by: disposeBag)
        
        selectedWallet = walletList.first as? ICXWallet
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        // Floater
        if selectedWallet != nil {
            attach()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        detach()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = gradientView.bounds
    }

    func checkFloater() {
        let items = self.collectionView.indexPathsForVisibleItems
        
        let x = self.collectionView.panGestureRecognizer.translation(in: self.collectionView.superview).x
        let path = items.first!
        Log("IndexPath - \(path) - \(self.floater.isAttached) \(x)")
        if let icx = self.walletList[path.row] as? ICXWallet {
            self.selectedWallet = icx
            self.attach()
        } else {
            self.selectedWallet = nil
            self.detach()
        }
    }
}

extension MainViewController {
    @objc func panGesture(_ recon: UIPanGestureRecognizer) {
        let point = recon.location(in: view)
        let offset = startPoint - point
        
        switch recon.state {
        case .began:
            startPoint = point
            
        case .changed:
            
            // up
            if offset.y >= 0 {
                /// Going up
                if !isBigCard {
                    if Header_Height >= offset.y {
                        cardTop.constant = -offset.y
                    }
                }
                
            } else { // down
                // refresh
                if cardTop.constant == 0 && !isBigCard {
                    if offset.y < -50 {
                        activityControl.startAnimating()
                    }
                    
                    if offset.y > -100 {
                        contentTop.constant = abs(offset.y)
                        backHeight.constant = Header_Height + abs(offset.y)
                        contentBottom.constant = abs(offset.y)
                    }

                } else { // cardview down
                    if isBigCard {
                        if offset.y >= -Header_Height {
                            cardTop.constant = -Header_Height+abs(offset.y)
                        }
                    }
                }
            }
            
        default:
            if offset.y > 0 { // up
                if cardTop.constant < -Header_Height / 2 {
                    self.cardTop.constant = -Header_Height
                    self.isBigCard = true
                    
                    navBar.hideToggleImageView(true)
                    
                } else {
                    self.cardTop.constant = 0
                    self.isBigCard = false
                    
                }

            } else { // down
                // refresh
                if cardTop.constant == 0 {
                    mainViewModel.reload.onNext(true)
//                    self.activityControl.stopAnimating()

                } else {
                    if cardTop.constant > -Header_Height/2 {
                        self.cardTop.constant = 0
                        self.isBigCard = false
                        
                        navBar.hideToggleImageView(false)
                        
                    } else {
                        self.cardTop.constant = -Header_Height
                        self.isBigCard = true
                    }
                }
            }
            mainViewModel.isBigCard.onNext(self.isBigCard)
        }
        
        collectionView.collectionViewLayout.invalidateLayout()
        self.view.layoutIfNeeded()
    }
}

extension CGPoint {
    static func - (lhd: CGPoint, rhd: CGPoint) -> CGPoint {
        return CGPoint(x: lhd.x - rhd.x, y: lhd.y - rhd.y)
    }
}

extension MainViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isWalletMode {
            return walletList.count
        } else {
            return Manager.wallet.types.count + tokenList.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cardCell", for: indexPath) as! MainCollectionViewCell
        cell.layer.cornerRadius = 18
        
        if isWalletMode {
            let wallet = walletList[indexPath.row]
            cell.buttonStack.isHidden = false
            cell.nicknameLabel.text = wallet.name
            cell.info = wallet
            
            if let _ = wallet as? ETHWallet {
                cell.scanButton.isHidden = true
//                cell.symbol
            } else {
                cell.scanButton.isHidden = false
            }
            
        } else {
            cell.buttonStack.isHidden = true
            // icx, eth, ITD
            let cellCoinToken = self.symbolList[indexPath.row]
            
            cell.symbol = cellCoinToken
            
            if let token = DB.tokenListBy(symbol: cellCoinToken).first {
                cell.contractAddress = token.contractAddress
                cell.tokenDecimal = token.decimal
            }
            
            cell.coinTokens = self.coinTokenList[cellCoinToken]
            
            switch indexPath.row {
            case 0:
                cell.nicknameLabel.text = CoinType.icx.fullName
            case 1:
                cell.nicknameLabel.text = CoinType.eth.fullName
            default:
                let realIndex = indexPath.row - Manager.wallet.types.count
                cell.fullName = self.tokenList[realIndex].name
                cell.nicknameLabel.text = self.tokenList[realIndex].name
            }
        }
        
        cell.handler = {
//            self.refresh()
        }
        return cell
    }
}

extension MainViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
}
