//
//  MainMenuViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

public enum MainMenuItem {
    case createWallet
    case importWallet
    case exportWallet
    case lockScreen
    case language
    case appInfo
    case terms
}

protocol MainMenuDelegate {
    func mainMenuSelected(selected: MainMenuItem)
}

class MainMenuViewController: UIViewController {

    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var walletMakeLabel: UILabel!
    @IBOutlet weak var walletMakeButton: UIButton!
    @IBOutlet weak var walletImportLabel: UILabel!
    @IBOutlet weak var walletImportButton: UIButton!
    @IBOutlet weak var walletExportLabel: UILabel!
    @IBOutlet weak var walletExportButton: UIButton!
    @IBOutlet weak var lockLabel: UILabel!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var languageButton: UIButton!
    @IBOutlet weak var versionTitle: UILabel!
    @IBOutlet weak var versionButton: UIButton!
    @IBOutlet weak var newVersion: UIView!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var termsLabel: UILabel!
    @IBOutlet weak var termsButton: UIButton!
    
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    
    var delegate: MainMenuDelegate?
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initialize() {
        self.modalPresentationStyle = .overFullScreen
        
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.close()
        }).disposed(by: disposeBag)
        
        walletMakeButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.close {
                guard let delegate = self?.delegate else {
                    return
                }
                delegate.mainMenuSelected(selected: .createWallet)
            }
        }).disposed(by: disposeBag)
        
        walletImportButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.close {
                guard let delegate = self?.delegate else {
                    return
                }
                delegate.mainMenuSelected(selected: MainMenuItem.importWallet)
            }
        }).disposed(by: disposeBag)
        
        walletExportButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.close {
                guard let delegate = self?.delegate else {
                    return
                }
                delegate.mainMenuSelected(selected: MainMenuItem.exportWallet)
            }
        }).disposed(by: disposeBag)
        
        lockButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.close {
                guard let delegate = self?.delegate else {
                    return
                }
                delegate.mainMenuSelected(selected: MainMenuItem.lockScreen)
            }
        }).disposed(by: disposeBag)
        
        languageButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.close {
                guard let delegate = self?.delegate else {
                    return
                }
                delegate.mainMenuSelected(selected: MainMenuItem.language)
            }
        }).disposed(by: disposeBag)
        
        versionButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.close {
                guard let delegate = self?.delegate else {
                    return
                }
                delegate.mainMenuSelected(selected: MainMenuItem.appInfo)
            }
        }).disposed(by: disposeBag)
        
        termsButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.close {
                guard let delegate = self?.delegate else {
                    return
                }
                delegate.mainMenuSelected(selected: MainMenuItem.terms)
            }
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        walletMakeLabel.text = "Side.Create".localized
        walletImportLabel.text = "Side.Import".localized
        walletExportLabel.text = "Side.BundleExport".localized
        lockLabel.text = "Side.ScreenLock".localized
        languageLabel.text = "Side.Language".localized
        versionTitle.text = "Side.Version".localized
        termsLabel.text = "Side.Disclaimer".localized
        
        var text = ""
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            text += " \(version)"
        }
        if let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            text += ".\(buildVersion)"
        }
        versionLabel.text = text
        
        newVersion.layer.cornerRadius = newVersion.frame.height / 2
    }
    
    @IBAction func tapGesture(_ sender: Any) {
        close()
    }
}

extension MainMenuViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.15, animations: {
            self.view.alpha = 1.0
        }) { (bool) in
            self.leftConstraint.constant = 0
            UIView.animate(withDuration: 0.15, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkVersion()
    }
    
    func checkVersion() {
        let app = UIApplication.shared.delegate as! AppDelegate
        if let version = app.all, let myVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String {
            newVersion.isHidden = !(version > myVersion)
            versionLabel.text = myVersion
        } else {
            newVersion.isHidden = true
        }
    }
    
    func present(from: UIViewController, delegate: MainMenuDelegate?) {
        self.view.alpha = 0.0
        
        from.present(self, animated: false) {
            self.leftConstraint.constant = -275
        }
        
    }
    
    func close(completion: (() -> Void)? = nil) {
        self.leftConstraint.constant = -275
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 0
            self.view.layoutIfNeeded()
        }) { (bool) in
            self.dismiss(animated: false, completion: {
                guard let handler = completion else {
                    return
                }
                
                handler()
            })
        }
    }
}

extension MainMenuDelegate where Self: MainViewController {
    func mainMenuSelected(selected: MainMenuItem) {
        switch selected {
        case .createWallet:
            let createStep = UIStoryboard(name: "Loading", bundle: nil).instantiateViewController(withIdentifier: "CreateStepView") as! CreateStepViewController
            createStep.isLaunched = false
            self.present(createStep, animated: true, completion: nil)
            
        case .importWallet:
            let importStep = UIStoryboard(name: "Loading", bundle: nil).instantiateViewController(withIdentifier: "ImportStepView") as! ImportStepViewController
            self.present(importStep, animated: true, completion: nil)
            
        case .exportWallet:
            let export = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WalletExportView") as! WalletExportViewController
            let nav = UINavigationController(rootViewController: export)
            nav.isNavigationBarHidden = true
            self.present(nav, animated: true, completion: nil)

        case .lockScreen:
            let lock = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "LockSettingView")
            let nav = UINavigationController(rootViewController: lock)
            nav.isNavigationBarHidden = true
            self.present(nav, animated: true, completion: nil)

        case .language:
            let language = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "LanguageSelectView")
            self.present(language, animated: true, completion: nil)
            
        case .appInfo:
            let appInfo = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "AppInfoView")
            let nav = UINavigationController(rootViewController: appInfo)
            nav.isNavigationBarHidden = true
            self.present(nav, animated: true, completion: nil)

        case .terms:
            let disclaimer = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "DisclaimerView")
            self.present(disclaimer, animated: true, completion: nil)

        }
    }
}

extension MainViewController: MainMenuDelegate {
    
}
