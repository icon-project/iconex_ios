//
//  IXUtils.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift
import BigInt
import Web3swift
import CryptoSwift
import ICONKit

struct Tool {
    static func calculatePrice(decimal: Int = 18, currency: String, balance: BigUInt) -> String {
        guard let exchange = Manager.exchange.exchangeInfoList[currency]?.price else { return "-" }
        
        let bigExchange = stringToBigUInt(inputText: exchange, decimal: decimal, fixed: true) ?? 0
        let calculated = bigExchange * balance / BigUInt(10).power(decimal)
        
        let price = calculated.toString(decimal: decimal, 2).currencySeparated()
        return price
    }
    
    static func calculate(decimal: Int = 18, currency: String, balance: BigUInt) -> BigUInt {
        guard let exchange = Manager.exchange.exchangeInfoList[currency]?.price else { return "-" }

        let bigExchange = stringToBigUInt(inputText: exchange, decimal: decimal, fixed: true) ?? 0
        let calculated = bigExchange * balance / BigUInt(10).power(decimal)

        return calculated
    }
    
    static func stringToBigUInt(inputText: String, decimal: Int = 18, fixed: Bool = false) -> BigUInt? {
        var groupingSeparator = Tool.groupingSeparator
        var decimalSeparator = Tool.decimalSeparator
        
        if fixed {
            groupingSeparator = ","
            decimalSeparator = "."
        }
        
        let strip = inputText.replacingOccurrences(of: groupingSeparator, with: "")
        let comp = strip.components(separatedBy: decimalSeparator)
        
        var result: BigUInt?
        if comp.count < 2 {
            guard let first = comp.first, let quotient = BigUInt(first) else {
                return nil
            }
            
            let completed = quotient * BigUInt(10).power(decimal)
            result = completed
        } else {
            guard let first = comp.first, let second = comp.last, let quotient = BigUInt(first, radix: 10), let remainder = BigUInt(second, radix: 10) else {
                return nil
            }
            let completed = (quotient * BigUInt(10).power(decimal)) + (remainder * BigUInt(10).power(decimal - second.count))
            result = completed
        }
        
        return result
    }
    
    static var decimalSeparator: String {
        var separator = "."
        let formatter = NumberFormatter()
        guard let id = Locale.current.collatorIdentifier else { return "." }
        formatter.locale = Locale(identifier: id)
        
        if let localizedSeparator = formatter.decimalSeparator {
            separator = localizedSeparator
        }
        
        return separator
    }
    
    static var groupingSeparator: String {
        var separator = ","
        let formatter = NumberFormatter()
        guard let id = Locale.current.collatorIdentifier else { return "." }
        formatter.locale = Locale(identifier: id)
        
        if let localizedSeparator = formatter.groupingSeparator {
            separator = localizedSeparator
        }
        
        return separator
    }
    
    static func rotateAnimation(inView: UIView) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0.0
        animation.toValue = CGFloat(.pi * 2.0)
        animation.duration = 1.0
        animation.repeatCount = Float.greatestFiniteMagnitude
        animation.isRemovedOnCompletion = false
        
        inView.layer.add(animation, forKey: "rotation")
    }
    
    static func rotateReverseAnimation(inView: UIView) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = CGFloat(.pi * 2.0)
        animation.toValue = 0.0
        animation.duration = 1.0
        animation.repeatCount = Float.greatestFiniteMagnitude
        animation.isRemovedOnCompletion = false
        
        inView.layer.add(animation, forKey: "rotation")
    }
    
    static func isPasscode() -> Bool {
        guard (UserDefaults.standard.string(forKey: "u8djdnuEe2xIddfkD") != nil) else { return false }
        guard (UserDefaults.standard.string(forKey: "aExd73E0dxvdQrx") != nil) else { return false }
        
        return UserDefaults.standard.bool(forKey: "useLock")
    }
    
    static func createPasscode(code: String) -> Bool {
        let uuid = UUID().uuidString
        let uuidArray = Array(uuid.utf8)
        let word = Array(code.utf8)
        do {
            let encryptedData = try HMAC(key: uuidArray, variant: .sha256).authenticate(word)
            let encrypted = encryptedData.toHexString()
            
            UserDefaults.standard.set(uuid, forKey: "u8djdnuEe2xIddfkD")
            UserDefaults.standard.set(encrypted, forKey: "aExd73E0dxvdQrx")
            UserDefaults.standard.set(true, forKey: "useLock")
            UserDefaults.standard.synchronize()
        } catch {
            return false
        }
        return true
    }
    
    static func verifyPasscode(code: String) -> Bool {
        guard let uuid = UserDefaults.standard.string(forKey: "u8djdnuEe2xIddfkD") else { return false }
        guard let saved = UserDefaults.standard.string(forKey: "aExd73E0dxvdQrx") else { return false }
        let uuidArray = Array(uuid.utf8)
        let word = Array(code.utf8)
        do {
            let encryptedData = try HMAC(key: uuidArray, variant: .sha256).authenticate(word)
            let encrypted = encryptedData.toHexString()
            
            if saved == encrypted { return true }
        } catch {
            return false
        }
        return false
    }
    
    static func removePasscode() {
        UserDefaults.standard.removeObject(forKey: "u8djdnuEe2xIddfkD")
        UserDefaults.standard.removeObject(forKey: "aExd73E0dxvdQrx")
        UserDefaults.standard.removeObject(forKey: "useLock")
        UserDefaults.standard.synchronize()
    }
    
    static func removeTouchID() {
        UserDefaults.standard.removeObject(forKey: "domain")
        UserDefaults.standard.removeObject(forKey: "useBio")
        UserDefaults.standard.synchronize()
    }
    
    static func toast(message: String) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        
        guard let window = app.window else { return }
        
//        window.makeToast(message)        
    }
    
    static func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
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
}

func scaleQRCode(origin: CIImage) -> UIImage {
    let scaled = origin.transformed(by: CGAffineTransform(scaleX: 3.0, y: 3.0))
    
    return UIImage(ciImage: scaled, scale: UIScreen.main.scale, orientation: .up)
}

// about RxSwift
func keyboardHeight() -> Observable<CGFloat> {
    return Observable
        .from([
            NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
                .map { notification -> CGFloat in
                    (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height ?? 0
            },
            NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
                .map { _ -> CGFloat in
                    0
            }
            ])
        .merge()
}

func exchangeListDidChanged() -> Observable<Notification> {
    return Observable
        .from([NotificationCenter.default.rx.notification(NSNotification.Name(rawValue: "kNotificationExchangeListDidChanged"))])
        .merge()
}

func balanceListDidChanged() -> Observable<(Notification)> {
    return Observable
        .from([
            NotificationCenter.default.rx.notification(NSNotification.Name(rawValue: "kNotificationBalanceListDidChanged"))])
        .merge()
}

func exchangeIndicatorChanged() -> Observable<Notification> {
    return Observable
        .from([NotificationCenter.default.rx.notification(NSNotification.Name("kNotificationExchangeIndicatorChanged"))])
        .merge()
}

func languageDidChanged() -> Observable<Notification> {
    return Observable
        .from([NotificationCenter.default.rx.notification(NSNotification.Name("kNotificationLanguageDidChanged"))])
        .merge()
}

func copyString(message: String) {
    UIPasteboard.general.string = message

    let feedback = UINotificationFeedbackGenerator()
    feedback.prepare()
    feedback.notificationOccurred(.success)
}

func getID() -> String {
    let size = 3
    var randomBytes = Array<UInt8>(repeating: 0, count: size)
    _ = SecRandomCopyBytes(kSecRandomDefault, size, &randomBytes)
    let id = Data(randomBytes).toHexString()
    
    return id
}

func Localized(key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

func bzz() {
    let feedback = UIImpactFeedbackGenerator(style: .light)
    feedback.impactOccurred()
}

func bzzz() {
    let feedback = UIImpactFeedbackGenerator(style: .medium)
    feedback.impactOccurred()
}

func bzzzz() {
    let feedback = UIImpactFeedbackGenerator(style: .heavy)
    feedback.impactOccurred()
}

//struct Alert {
//    public enum EditingMode {
//        case add, edit
//    }
//    
//    static func Basic(message: String, alignment: NSTextAlignment = .center) -> BasicActionViewController {
//        let basic = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "BasicActionView") as! BasicActionViewController
//        basic.message = message
//        basic.setAlignment(alignment)
//        return basic
//    }
//    
//    static func Basic(attributed: NSAttributedString) -> BasicActionViewController {
//        let basic = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "BasicActionView") as! BasicActionViewController
//        basic.attrMessage = attributed
//        
//        return basic
//    }
//    
//    static func Confirm(message: String, cancel: String? = "Common.No".localized, confirm: String? = "Common.Yes".localized, handler: (() -> Void)?, _ cancelHandler: (() -> Void)? = nil) -> ConfirmActionViewController {
//        let confirmAction = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "ConfirmActionView") as! ConfirmActionViewController
//        confirmAction.message = message
//        confirmAction.addConfirm(action: handler)
//        confirmAction.cancel = cancelHandler
//        confirmAction.confirmTitle = confirm
//        confirmAction.cancelTitle = cancel
//        return confirmAction
//    }
//    
//    static func shareBackup(filePath: URL) {
//        
//    }
//    
//    static func editingAddress(name: String? = nil, address: String? = nil, mode: EditingMode, type: String, handler: (() -> Void)?) -> EditingAddressViewController {
//        let add = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "EditingAddressView") as! EditingAddressViewController
//        add.name = name
//        add.address = address
//        add.type = type
//        add.mode = mode
//        add.handler = handler
//        
//        return add
//    }
//    
//    static func transactionDetail(txHash: String) -> TransactionDetailViewController {
//        let detail = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "TransactionDetailView") as! TransactionDetailViewController
//        detail.txHash = txHash
//        
//        return detail
//    }
//    
//    static func checkPassword(walletInfo: WalletInfo, action: @escaping (_ isSuccess: Bool, _ privateKey: String) -> Void) -> WalletPasswordViewController{
//        let auth = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "WalletPasswordView") as! WalletPasswordViewController
//        auth.walletInfo = walletInfo
//        auth.addConfirm(completion: action)
//        
//        return auth
//    }
//    
//    static func TokenManage(walletInfo: WalletInfo) -> UINavigationController {
//        let token = UIStoryboard(name: "Menu", bundle: nil).instantiateViewController(withIdentifier: "TokenListNav") as! TokenListViewController
//        token.walletInfo = walletInfo
//        
//        let nav = UINavigationController(rootViewController: token)
//        nav.isNavigationBarHidden = true
//        return nav
//    }
//    
//    static func PrivateInfo(walletInfo: WalletInfo) -> WalletPrivateInfoViewController {
//        let info = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "WalletPrivateInfo") as! WalletPrivateInfoViewController
//        info.wallet = WManager.loadWalletBy(info: walletInfo)
//        
//        return info
//    }
//    
//    static func NetworkProvider(source: UIViewController, completion: (() -> Void)?) {
//        let selectable = UIStoryboard(name: "ActionControls", bundle: nil).instantiateViewController(withIdentifier: "SelectableActionController") as! SelectableActionController
//        selectable.handler = { index in
//            UserDefaults.standard.set(index, forKey: "Provider")
//            UserDefaults.standard.synchronize()
//            
//            if let compl = completion {
//                compl()
//            }
//        }
//        selectable.present(from: source, title: "AppInfo.SelectNetwork".localized, items: ["Mainnet", "Testnet", "Yeouido (여의도)"])
//    }
//    
//    static func DeveloperNetworkProvider(source: UIViewController, completion: (() -> Void)?) {
//        let selectable = UIStoryboard(name: "ActionControls", bundle: nil).instantiateViewController(withIdentifier: "SelectableActionController") as! SelectableActionController
//        selectable.handler = { index in
//            switch index {
//            case 0:
//                ConnManager.provider = ICONService(provider: "https://wallet.icon.foundation/api/v3", nid: "0x1")
//            case 1:
//                ConnManager.provider = ICONService(provider: "https://testwallet.icon.foundation/api/v3", nid: "0x2")
//            case 2:
//                ConnManager.provider = ICONService(provider: "https://bicon.net.solidwallet.io/api/v3", nid: "0x3")
//            default:
//                ConnManager.provider = ICONService(provider: "https://wallet.icon.foundation/api/v3", nid: "0x1")
//            }
//            
//            if let compl = completion {
//                compl()
//            }
//        }
//        selectable.present(from: source, title: "AppInfo.SelectNetwork".localized, items: ["Mainnet", "Testnet", "Yeouido (여의도)"])
//    }
//}
