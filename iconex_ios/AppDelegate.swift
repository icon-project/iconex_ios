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
    
    var connect: UIViewController?

    var all: String?
    var necessary: String?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        ////////////////////////////////////
        // Define Connection Host
        ////////////////////////////////////
        
        Configuration.setDebug()
        
        if let languages = UserDefaults.standard.array(forKey: "AppleLanguages"), let appleLan = languages.first as? String {
            Log.Debug("languages\n\(languages)")
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
            Log.Debug(contents)
            
            for content in contents {
                try FileManager.default.removeItem(atPath: path.appendingPathComponent(content).path)
            }
            
            let removed = try FileManager.default.contentsOfDirectory(atPath: path.path)
            Log.Debug(removed)
        } catch {
            Log.Debug(error)
        }
        
        if let options = launchOptions, let url = options[.url] as? URL {
            Conn.setMessage(source: url)
        }
        
        NSSetUncaughtExceptionHandler { (exception) in
            Log.Error("CRASH =======================")
            Log.Error("\(exception)")
            Log.Error("Stack trace ========================")
            Log.Error("\(exception.callStackSymbols)")
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
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        guard Configuration.systemCheck(), Configuration.integrityCheck(), Configuration.debuggerCheck() else {
            
            if let root = window?.rootViewController {
                
                let halt = Alert.Basic(message: "Error.SystemCheck.Failed".localized)
                halt.handler = {
                    exit(0)
                }
                root.present(halt, animated: false, completion: nil)
                
            }
            return
        }
        
        if Conn.needTranslate {
            toConnect()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Conn.setMessage(source: url)
//        toConnect()
        return true
    }

    func changeLanguage(language: String) {
//        UserDefaults.standard.set([language], forKey: "AppleLanguages")
        UserDefaults.standard.set(language, forKey: "selectedLanguage")
        UserDefaults.standard.synchronize()
        Bundle.setLanguage(language)
        
        NotificationCenter.default.post(name: NSNotification.Name("kNotificationLanguageDidChanged"), object: nil)
    }

    func checkVersion(_ completion: (() -> Void)? = nil) {
        var tracker: Tracker {
            switch Config.host {
            case .main:
                return Tracker.main()
                
            case .dev:
                return Tracker.dev()
                
            case .yeouido:
                return Tracker.local()
            }
        }
        let versionURL = URL(string: tracker.provider)!.appendingPathComponent("app/ios.json")
        let request = URLRequest(url: versionURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        Alamofire.request(request).responseJSON(queue: DispatchQueue.global(qos: .utility)) { (dataResponse) in
            
            DispatchQueue.main.async {
                switch dataResponse.result {
                case .success:
                    guard case let json as [String: Any] = dataResponse.result.value, let result = json["result"] as? String else {
                        
                        let retry = UIStoryboard(name: "Loading", bundle: nil).instantiateViewController(withIdentifier: "RetryView")
                        self.window?.rootViewController = retry
                        return
                    }
                    Log.Debug("Version: \(json)")
                    if result == "OK" {
                        let data = json["data"] as! [String: String]
                        self.all = data["all"]
                        self.necessary = data["necessary"]
                    }
                    self.retry()
                    
                case .failure(let error):
                    Log.Debug("Error \(error)")
                    if let comp = completion {
                        comp()
                        return
                    } else {
                        let retry = UIStoryboard(name: "Loading", bundle: nil).instantiateViewController(withIdentifier: "RetryView")
                        self.window?.rootViewController = retry
                        return
                    }
                }
            }
        }
    }
    
    private func go() {
        Exchange.getExchangeList()
        Balance.getWalletsBalance()
        
        let list = WManager.walletInfoList
        
        let app = UIApplication.shared.delegate as! AppDelegate
        
        if list.count > 0 {
            if Tools.isPasscode() {
                let passcode = UIStoryboard(name: "Loading", bundle: nil).instantiateViewController(withIdentifier: "PasscodeView")
                app.window?.rootViewController = passcode
            } else {
                let main = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                app.window?.rootViewController = main
            }
        } else {
            let welcome = UIStoryboard(name: "Loading", bundle: nil).instantiateViewController(withIdentifier: "WelcomeView")
            app.window?.rootViewController = welcome
        }
    }
    
    private func retry() {
            if let version = self.necessary {
                let myVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
                
                if version > myVersion {
                    let message = "Version.Message".localized
                    Alert.Confirm(message: message, cancel: "Common.Cancel".localized, confirm: "Version.Update".localized, handler: {
                        UIApplication.shared.open(URL(string: "itms-apps://itunes.apple.com/app/iconex-icon-wallet/id1368441529?mt=8")!, options: [:], completionHandler: { _ in
                            exit(0)
                        })
                    }, {
                        exit(0)
                    }).show(self.window!.rootViewController!)
                } else {
                    
                    go()
                    
                }
            } else {
                
            }
    }
    
    func fileShare(filepath: URL, _ sender: UIView? = nil) {
        
        let activity = UIActivityViewController(activityItems: [filepath], applicationActivities: nil)
        activity.excludedActivityTypes = [.postToFacebook, .postToVimeo, .postToWeibo, .postToFlickr, .postToTwitter, .postToTencentWeibo, .addToReadingList]
        if let top = topViewController() {
            DispatchQueue.main.async {
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    activity.popoverPresentationController?.sourceView = sender
                    activity.popoverPresentationController?.permittedArrowDirections = .up
                    if let originSource = sender {
                        activity.popoverPresentationController?.sourceRect = originSource.bounds
                    }
                }
                
                top.present(activity, animated: true, completion: nil)
                
            }
        }
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
        dismissHierachy(controller: self.connect, completion: {
            if let connect = self.connect {
                if let nav = connect.presentingViewController as? UINavigationController {
                    nav.viewControllers[0].dismiss(animated: false, completion: {
                        self.connect = nil
                    })
                } else {
                    connect.presentingViewController?.dismiss(animated: false, completion: {
                        self.connect = nil
                    })
                }
            }
        })
    }
    
    func toConnect() {
        let connect = UIStoryboard(name: "Connect", bundle: nil).instantiateInitialViewController()
        
        self.connect = connect
        if let top = self.topViewController() {
            Log.Debug("Present - \(top)")
            top.present(connect!, animated: true, completion: nil)
        }
    }
    
    func dismissHierachy(controller: UIViewController?, completion: (() -> Void)?) {
        if let presented = controller?.presentedViewController {
            dismissHierachy(controller: presented, completion: completion)
        }
        controller?.dismiss(animated: false, completion: completion)
    }
}

