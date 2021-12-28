//
//  LaunchViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit

class LaunchViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        let appearance = ToastView.appearance()
//        appearance.bottomOffsetPortrait = {
//            if #available(iOS 11.0, *) {
//                return 50 + view.safeAreaInsets.bottom
//            }
//            return 50.0
//        }()
        
        #if DEBUG
        print("####### DEBUG #######")
        #endif
        
        
        guard Configuration.systemCheck() else {
            guard let app = UIApplication.shared.delegate as? AppDelegate, let root = app.window?.rootViewController else {
                exit(0)
            }
            
            let halt = Alert.Basic(message: "Error.SystemCheck.Failed".localized)
            halt.handler = {
                exit(0)
            }
            root.present(halt, animated: false, completion: nil)
            return
        }
        guard Configuration.integrityCheck() else {
            guard let app = UIApplication.shared.delegate as? AppDelegate, let root = app.window?.rootViewController else {
                exit(0)
            }
            
            let halt = Alert.Basic(message: "Error.SystemCheck.Failed".localized + " (2)")
            halt.handler = {
                exit(0)
            }
            root.present(halt, animated: false, completion: nil)
            return
        }
        guard Configuration.debuggerCheck() else {
            guard let app = UIApplication.shared.delegate as? AppDelegate, let root = app.window?.rootViewController else {
                exit(0)
            }
            
            let halt = Alert.Basic(message: "Error.SystemCheck.Failed".localized + " (3)")
            halt.handler = {
                exit(0)
            }
            root.present(halt, animated: false, completion: nil)
            return
        }
        
        
        
        for token in WManager.tokenTypes() {
            Exchange.addToken(token.symbol)
        }
        
        Balance.getWalletsBalance()
        Exchange.getExchangeList()
        
        guard UserDefaults.standard.bool(forKey: "confirmPermissions") == true else {
            openPermission()
            return
        }
        
        let app = UIApplication.shared.delegate as! AppDelegate
        app.checkVersion()
    }
    
    func openPermission() {
        let permission = UIStoryboard(name: "Loading", bundle: nil).instantiateViewController(withIdentifier: "PermissionView")
        self.present(permission, animated: true, completion: nil)
    }
}
