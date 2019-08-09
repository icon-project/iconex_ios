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
    
    var scrollIndex: Int = 0 {
        willSet {
            var leftTitle: String = "Common.Back".localized
            var rightTitle: String = "Common.Next".localized
            switch newValue {
            case 0:
                leftTitle = "Common.Cancel".localized
                self.rightButton.isEnabled = true
                
            case 2:
                rightTitle = "Common.Complete".localized
                self.rightButton.isEnabled = false
                
            default:
                leftTitle = "Common.Back".localized
                rightTitle = "Common.Next".localized
                self.rightButton.isEnabled = false
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
        
        stepScrollView.rx.didEndScrollingAnimation.subscribe(onNext: { [unowned self] in
            self.scrollIndex = (Int)(self.stepScrollView.contentOffset.x / self.view.frame.width)
        }).disposed(by: disposeBag)
        
        leftButton.rx.tap.subscribe(onNext: { [unowned self] in
            self.select.refresh()
            self.file.refresh()
            self.name.refresh()
            switch self.scrollIndex {
            case 0:
                self.dismiss(animated: true, completion: nil)
                
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
            case 2:
                self.finish()
                
            default:
                let value = (CGFloat)(self.scrollIndex + 1)
                let x = value * self.view.frame.width
                self.stepScrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
                self.file.resetData()
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
    
    override func refresh() {
        super.refresh()
        titleContainer.set(title: "LoadWallet.Title".localized)
        titleContainer.actionHandler = {
            self.dismiss(animated: true, completion: nil)
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
                    
                }
                
            case .bundle: break
            }
        } catch {
            Log("Error - \(error)")
        }
    }
}
