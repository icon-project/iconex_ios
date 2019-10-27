//
//  AppDelegate.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import ICONKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var connect: ConnectViewController?
    var appVersion: String {
        return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }

    var all: String?
    var necessary: String?
    
    var usingLock: Bool = false
    
    func setRedirect(source: URL) {
        do {
            guard let components = URLComponents(url: source, resolvingAgainstBaseURL: false) else {
                throw ConnectError.invalidRequest
            }
//            if let host = components.host {
//                guard host.lowercased() == "developer" else { return }
//
//                Conn.isConnect = true
//                return
//            }
            
            guard let queries = components.queryItems else {
                throw ConnectError.invalidRequest
            }
            guard let dataQuery = queries.filter({ $0.name == "data" }).first, let dataParam = dataQuery.value else {
                throw ConnectError.invalidRequest

            }
            guard let data = Data(base64Encoded: dataParam) else {
                throw ConnectError.invalidBase64
            }

            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let redirect = json["redirect"] as? String else {
                throw ConnectError.invalidJSON
            }
            guard let conURL = URL(string: redirect) else {
                throw ConnectError.invalidJSON
            }

            Conn.redirect = conURL
            Conn.isConnect = true
        } catch {
            Log("Error - \(error)")
        }
        
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        ////////////////////////////////////
        // Define Connection Host
        ////////////////////////////////////
        
        Configuration.setDebug()
        
        if let languages = UserDefaults.standard.array(forKey: "AppleLanguages"), let appleLan = languages.first as? String {
            Log("languages\n\(languages)")
            if appleLan != "ko-KR" {
                Bundle.setLanguage("en")
            } else {
                Bundle.setLanguage("ko")
            }
        }
        
        ////////////////////////////////////
        // Realm Configurations & Migration
        ////////////////////////////////////
        let config = Realm.Configuration(
            schemaVersion: 9,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 9 {
                    
                }
        })
        
        Realm.Configuration.defaultConfiguration = config
        
        var path = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        path = path.appendingPathComponent("ICONex")
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: path.path)
            Log(contents)
            
            for content in contents {
                try FileManager.default.removeItem(atPath: path.appendingPathComponent(content).path)
            }
            
            let removed = try FileManager.default.contentsOfDirectory(atPath: path.path)
            Log(removed)
        } catch {
            Log(error)
        }
        
        NSSetUncaughtExceptionHandler { (exception) in
            Log("CRASH =======================")
            Log("\(exception)")
            Log("Stack trace ========================")
            Log("\(exception.callStackSymbols)")
        }
        
        Manager.wallet.walletList.forEach {
            Log("Wallet - \($0.address) \($0.name)")
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        Log("Entering background...")
        if Tool.isPasscode() {
            UserDefaults.standard.set(Date(), forKey: "sleep")
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        guard Configuration.systemCheck(), Configuration.integrityCheck(), Configuration.debuggerCheck() else {

            Alert.basic(title: "Error.SystemCheck.Failed".localized, subtitle: nil, hasHeaderTitle: false, isOnlyOneButton: true, leftButtonTitle: nil, rightButtonTitle: "Common.Confirm".localized, cancelAction: nil) {
                exit(0)
                }.show()
            return
        }
        
        if let date = UserDefaults.standard.object(forKey: "sleep") as? Date {
            let time = Int(Date().timeIntervalSince1970 - date.timeIntervalSince1970)
            
            if time >= 5 * 60 {
                presentLock()
            } else {
                if !usingLock && !Tool.isPasscode() && Conn.isConnect {
                    toConnect()
                }
            }
        } else {
            if !usingLock && !Tool.isPasscode() && Conn.isConnect {
                toConnect()
            }
        }
        UserDefaults.standard.removeObject(forKey: "sleep")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        setRedirect(source: url)
        Conn.setMessage(source: url)
        if Conn.isConnect && (!Tool.isPasscode() || Conn.auth) {
            Manager.balance.getAllBalances()
            toConnect()
        }
        Conn.isConnect = true
        return true
    }
    
    func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
    
    func toMain() {
        self.window?.rootViewController?.dismiss(animated: false, completion: {
            self.connect = nil
        })
        if let nav = self.window?.rootViewController, let _ = nav.children.first as? MainViewController {
            
        } else {
            let main = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
            change(root: main)
        }
    }
    
    func toConnect() {
        let connect = UIStoryboard(name: "Connect", bundle: nil).instantiateInitialViewController() as! ConnectViewController
        connect.modalPresentationStyle = .fullScreen
        self.connect = connect
         app.topViewController()?.present(connect, animated: true, completion: nil)
    }
    
    func change(root: UIViewController) {
        window?.backgroundColor = .mint1
        UIView.transition(with: window!, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.window?.rootViewController = root
        }, completion: nil)
    }
    
    func presentLock(_ handler: (() -> Void)? = nil) {
        guard usingLock == false else { return }
        let passcodeVC = UIStoryboard(name: "Passcode", bundle: nil).instantiateViewController(withIdentifier: "Passcode") as! PasscodeViewController
        passcodeVC.lockType = .check
        passcodeVC.modalPresentationStyle = .fullScreen
        passcodeVC.completeHandler = handler
        usingLock = true
        app.topViewController()?.present(passcodeVC, animated: true, completion: nil)
    }
}

let app = UIApplication.shared.delegate as! AppDelegate
