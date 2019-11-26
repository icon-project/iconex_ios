//
//  LoadWalletViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 05/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import ICONKit
import Web3swift

protocol loadWalletSequence {
    var loader: WalletLoader? { get }
    func selectedMode() -> LoadFileMode
    func set(mode: LoadFileMode)
    func set(loader: WalletLoader?)
    func set(name: String)
    func validated()
    func invalidated()
}

class LoadWalletViewController: PopableViewController {
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    @IBOutlet weak var stepImage1: UIImageView!
    @IBOutlet weak var stepLabel1: UILabel!
    @IBOutlet weak var leftLine: UIView!
    @IBOutlet weak var stepImage2: UIImageView!
    @IBOutlet weak var stepLabel2: UILabel!
    @IBOutlet weak var rightLine: UIView!
    @IBOutlet weak var stepImage3: UIImageView!
    @IBOutlet weak var stepLabel3: UILabel!
    
    @IBOutlet weak var contentStack: UIStackView!
    
    @IBOutlet weak var stepScrollView: UIScrollView!
    
    private var select: LoadSelectViewController!
    private var file: LoadFileViewController!
    private var name: LoadNameViewController!
    
    private var _loadMode: LoadFileMode = .loadFile {
        didSet {
            file.refresh()
        }
    }
    
    private var _loader: WalletLoader?
    
    var loader: WalletLoader? { return _loader }
    
    var doneAction: (() -> Void)? = nil
    
    var scrollIndex: Int = 0 {
        willSet {
            var leftTitle: String = "Common.Back".localized
            var rightTitle: String = "Common.Next".localized
            switch newValue {
            case 0:
                leftTitle = "Common.Cancel".localized
                self.rightButton.isEnabled = true
                stepImage1.image = #imageLiteral(resourceName: "icStep01On")
                stepLabel1.textColor = .mint1
                stepLabel2.textColor = .gray230
                stepLabel3.textColor = .gray230
                stepImage2.image = #imageLiteral(resourceName: "icStep02Off")
                stepImage3.image = #imageLiteral(resourceName: "icStep03Off")
                leftLine.backgroundColor = .gray230
                rightLine.backgroundColor = .gray230
                
            case 2:
                rightTitle = "Common.Complete".localized
                if self._loadMode == .loadFile && self._loader?.bundle != nil {
                    self.rightButton.isEnabled = true
                } else {
                    self.rightButton.isEnabled = false
                }
                stepLabel1.textColor = .mint1
                stepLabel2.textColor = .mint1
                stepLabel3.textColor = .mint1
                stepImage1.image = #imageLiteral(resourceName: "icStepCheck")
                stepImage2.image = #imageLiteral(resourceName: "icStepCheck")
                stepImage3.image = #imageLiteral(resourceName: "icStep03On")
                leftLine.backgroundColor = .mint1
                rightLine.backgroundColor = .mint1
                
            default:
                leftTitle = "Common.Back".localized
                rightTitle = "Common.Next".localized
                self.rightButton.isEnabled = false
                stepLabel1.textColor = .mint1
                stepLabel2.textColor = .mint1
                stepLabel3.textColor = .gray230
                stepImage1.image = #imageLiteral(resourceName: "icStepCheck")
                stepImage2.image = #imageLiteral(resourceName: "icStep02On")
                stepImage3.image = #imageLiteral(resourceName: "icStep03Off")
                leftLine.backgroundColor = .mint1
                rightLine.backgroundColor = .gray230
                
            }
            leftButton.setTitle(leftTitle, for: .normal)
            rightButton.setTitle(rightTitle, for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        self.stepLabel1.text = "LoadWallet.Display.Step1.Title".localized
        self.stepLabel2.text = "LoadWallet.Display.Step2.Title".localized
        self.stepLabel3.text = "LoadWallet.Display.Step3.Title".localized
        
        stepScrollView.rx.didEndScrollingAnimation.subscribe(onNext: { [unowned self] in
            self.scrollIndex = (Int)(self.stepScrollView.contentOffset.x / self.view.frame.width)
        }).disposed(by: disposeBag)
        
        leftButton.rx.tap.subscribe(onNext: { [unowned self] in
            self.select.refresh()
            self.file.refresh()
            self.name.refresh()
            switch self.scrollIndex {
            case 0:
                self.closeCurrent()
                
            default:
                let value = (CGFloat)(self.scrollIndex - 1)
                let x = value * self.view.frame.width
                self.stepScrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
                self.file.resetData()
            }
        }).disposed(by: disposeBag)
        
        rightButton.rx.tap.subscribe(onNext: { [unowned self] in
            self.select.refresh()
            self.file.refresh()
            self.name.refresh()
            switch self.scrollIndex {
            case 1:
                guard self._loader != nil else { return }
                self.scrollNext()
                
            case 2:
                self.finish()
                
            default: self.scrollNext()
                
            }
        }).disposed(by: disposeBag)
        
        for controller in children {
            if let select = controller as? LoadSelectViewController {
                select.delegate = self
                self.select = select
            } else if let file = controller as? LoadFileViewController {
                file.delegate = self
                self.file = file
            } else if let name = controller as? LoadNameViewController {
                name.delegate = self
                self.name = name
            }
        }
        
        scrollIndex = 0
    }
    
    func scrollNext() {
        let value = (CGFloat)(self.scrollIndex + 1)
        let x = value * self.view.frame.width
        self.stepScrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
        self.file.resetData()
    }
    
    override func refresh() {
        super.refresh()
        titleContainer.set(title: "LoadWallet.Title".localized)
        titleContainer.actionHandler = {
            self.closeCurrent()
        }
        
        leftButton.round02()
        rightButton.lightMintRounded()
        
    }
}

extension LoadWalletViewController: loadWalletSequence {
    func invalidated() {
        rightButton.isEnabled = false
    }
    
    func validated() {
        rightButton.isEnabled = true
    }
    
    func set(mode: LoadFileMode) {
        _loadMode = mode
        rightButton.isEnabled = true
    }
    
    func set(loader: WalletLoader?) {
        _loader = loader
    }
    
    func selectedMode() -> LoadFileMode {
        return _loadMode
    }
    
    func set(name: String) {
        _loader?.name = name
    }
}

extension LoadWalletViewController {
    func closeCurrent() {
        if scrollIndex != 0 {
            Alert.basic(title: "LoadWallet.Alert.Cancel".localized, subtitle: nil, hasHeaderTitle: false, isOnlyOneButton: false, leftButtonTitle: "Common.No".localized, rightButtonTitle: "Common.Yes".localized) {
                self.dismiss(animated: true, completion: nil)
            }.show()
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func finish() {
        guard let loader = _loader else { return }
        do {
            switch loader.type {
            case .wallet:
                guard let keystore = loader.keystore, let name = loader.name else { return }
                var wallet: BaseWalletConvertible
                if keystore.coinType != nil {
                    wallet = ICXWallet(name: name, keystore: keystore)
                } else {
                    wallet = ETHWallet(name: name, keystore: keystore)
                }
                try wallet.save()
                
            case .privateKey:
                guard let keyString = loader.value as? String, let name = loader.name, let pwd = loader.password else { return }
                if file.selectedType == "icx" {
                    
                    let key = PrivateKey(hex: Data(hex: keyString))
                    let icx = Wallet(privateKey: key)
                    try icx.generateKeystore(password: pwd)
                    let keystore = try icx.keystore!.convert()
                    let icxWallet = ICXWallet(name: name, keystore: keystore)
                    
                    try icxWallet.save()
                    
                } else {
                    let keystore = try ETHWallet.generateETHKeyStore(privateKey: PrivateKey(hex: Data(hex: keyString)), password: pwd)
                    let eth = ETHWallet(name: name, keystore: keystore)
                    try eth.save()
                }
                
            case .bundle:
                guard let bundleList = loader.bundle else { return }
                for bundleSet in bundleList {
                    let address = bundleSet.keys.first!
                    let bundle = bundleSet[address]!
                    let data = bundle.priv.data(using: .utf8)!
                    if bundle.type == "icx" {
                        guard let icx = ICXWallet(name: bundle.name, rawData: data, created: bundle.createdAt?.toDate()) else { continue }
                        
                        do {
                            try icx.save()
                            
                            if let tokensBundle = bundle.tokens {
                                for tk in tokensBundle {
                                    let token = Token(name: tk.name, parent: address, contract: tk.address, parentType: "icx", symbol: tk.symbol, decimal: tk.decimals, created: tk.createdAt.toDate() ?? Date())
                                    Manager.exchange.addToken(tk.symbol)
                                    try icx.addToken(token: token)
                                }
                            }
                        } catch {
                            Log(error)
                            Log("Error occurred while save icx wallet...")
                        }
                    } else {
                        guard let eth = ETHWallet(name: bundle.name, rawData: data, created: bundle.createdAt?.toDate()) else { continue }
                        do {
                            try eth.save()
                            
                            if let tokensBundle = bundle.tokens {
                                for tk in tokensBundle {
                                    let token = Token(name: tk.name, parent: address, contract: tk.address, parentType: "eth", symbol: tk.symbol, decimal: tk.decimals, created: tk.createdAt.toDate() ?? Date())
                                    Manager.exchange.addToken(tk.symbol)
                                    try eth.addToken(token: token)
                                }
                            }
                        } catch {
                            Log(error)
                            Log("Error occurred while save eth wallet...")
                        }
                    }
                }
                
            }
        } catch {
            Log("Error - \(error)")
        }
        Manager.balance.getAllBalances()
        
        if loader.type == .bundle {
            Alert.basic(title: "Alert.Bundle.Import.Success".localized, leftButtonTitle: "Common.Confirm".localized, cancelAction: {
                self.close()
            }).show()
        } else {
            close()
        }
    }
    
    func close() {
        self.dismiss(animated: true, completion: {
            self.doneAction?()
        })
    }
}
