//
//  IntroViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 29/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import Alamofire

class IntroViewController: BaseViewController {
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var satellite: UIImageView!
    @IBOutlet weak var logoLabel: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    private var _animated: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        iconImage.alpha = 0.0
        satellite.alpha = 0.0
        logoLabel.alpha = 0.0
        indicator.isHidden = true
    }
    
    override func refresh() {
        super.refresh()
        view.backgroundColor = .mint1
        iconImage.image = #imageLiteral(resourceName: "imgLogoIcon0256W")
        satellite.image = #imageLiteral(resourceName: "imgLogoIcon0170W")
        logoLabel.size12(text: "@2019 ICON Foundation", color: UIColor(255, 255, 255, 0.5))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !UserDefaults.standard.bool(forKey: "permission") {
            let perm = UIStoryboard(name: "Intro", bundle: nil).instantiateViewController(withIdentifier: "PermissionView") as! PermissionViewController
            perm.action = {
                
            }
            perm.pop()
        } else {
            if !_animated {
                _animated = true
                startAlpha()
            } else {
                go()
            }
        }
    }
    
    func startAlpha() {
        UIView.animate(withDuration: 0.45, delay: 0.5, options: .curveLinear, animations: {
            self.iconImage.alpha = 1.0
            self.satellite.alpha = 1.0
            self.logoLabel.alpha = 1.0
        }, completion: { _ in
            self.startRotate()
        })
    }
    
    func startRotate() {
        UIView.animate(withDuration: 0.65, delay: 0.5, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.0, options: .curveEaseIn, animations: {
            self.iconImage.transform = CGAffineTransform(rotationAngle: .pi)
            self.satellite.transform = CGAffineTransform(rotationAngle: -3.14159256)
        }, completion : { _ in
            self.startHide()
        })
    }
    
    func startHide() {
        UIView.animate(withDuration: 0.4, delay: 0.5, animations: {
            self.iconImage.alpha = 0.0
            self.satellite.alpha = 0.0
            self.logoLabel.alpha = 0.0
        }, completion: { _ in
            self.iconImage.transform = .identity
            self.satellite.transform = .identity
            
            self.getVersion({
                self.go()
            })
            
        })
    }
    
    func getVersion(_ completion: (() -> Void)? = nil) {
        indicator.isHidden = false
        var tracker: Tracker {
            switch Config.host {
            case .main:
                return Tracker.main()
                
            case .euljiro:
                return Tracker.euljiro()
                
            case .yeouido:
                return Tracker.yeouido()
                
            default:
                return Tracker.euljiro()
            }
        }
        let versionURL = URL(string: tracker.provider)!.appendingPathComponent("app/ios.json")
        let request = URLRequest(url: versionURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        Alamofire.request(request).responseJSON(queue: DispatchQueue.global(qos: .utility)) { (dataResponse) in
            
            DispatchQueue.main.async {
                self.indicator.isHidden = true
                switch dataResponse.result {
                case .success:
                    guard case let json as [String: Any] = dataResponse.result.value, let result = json["result"] as? String else {
                        #warning("retry 구현")
                        return
                    }
                    Log("Version: \(json)")
                    if result == "OK" {
                        let data = json["data"] as! [String: String]
                        app.all = data["all"]
                        app.necessary = data["necessary"]
                    }
                    self.checkVersion()
                    
                case .failure(let error):
                    Log("Error \(error)")
                    if let comp = completion {
                        comp()
                        return
                    } else {
                        #warning("retry 구현")
                        return
                    }
                }
            }
        }
    }
    
    private func go() {
        Manager.exchange.getExchangeList()
        Manager.balance.getAllBalances()
        
        let list = Manager.wallet.walletList
        if list.count == 0 {
            let start = UIStoryboard(name: "Intro", bundle: nil).instantiateViewController(withIdentifier: "StartView")
            app.change(root: start)
        } else {
            if Tool.isPasscode() {
                let passcodeVC = UIStoryboard(name: "Passcode", bundle: nil).instantiateViewController(withIdentifier: "Passcode") as! PasscodeViewController
                passcodeVC.lockType = .check
                app.change(root: passcodeVC)
            } else if !Tool.isPasscode() && Conn.isConnect {
                let connect = UIStoryboard(name: "Connect", bundle: nil).instantiateInitialViewController() as! ConnectViewController
                app.window?.rootViewController = connect
                app.change(root: connect)
            } else {
                app.toMain()
            }
        }
        
        
    }
    
    private func checkVersion() {
        if let version = app.necessary {
            let myVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
            
            if version > myVersion {
                let message = "Version.Message".localized
//                    Alert.Confirm(message: message, cancel: "Common.Cancel".localized, confirm: "Version.Update".localized, handler: {
//                        UIApplication.shared.open(URL(string: "itms-apps://itunes.apple.com/app/iconex-icon-wallet/id1368441529?mt=8")!, options: [:], completionHandler: { _ in
//                            exit(0)
//                        })
//                    }, {
//                        exit(0)
//                    }).show(self.window!.rootViewController!)
            } else {
                
                go()
                
            }
        } else {
            
        }
    }
    
}
