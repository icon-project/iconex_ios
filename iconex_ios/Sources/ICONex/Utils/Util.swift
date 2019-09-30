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
import LocalAuthentication

struct Tool {
    public enum LAStatus {
        case success
        case failed
        case userCancel
        case locked
        case notUsed
        case notSupported
        case userFallback
        case notAvailable
        case passcodeNotSet
    }
    
    static func calculatePrice(decimal: Int = 18, currency: String, balance: BigUInt) -> String {
        guard let exchange = Manager.exchange.exchangeInfoList[currency]?.price else { return "-" }
        
        let bigExchange = stringToBigUInt(inputText: exchange, decimal: decimal, fixed: true) ?? 0
        let calculated = bigExchange * balance / BigUInt(10).power(decimal)
        
        let price = calculated.toString(decimal: decimal, 2).currencySeparated()
        return price
    }
    
    static func calculate(decimal: Int = 18, currency: String, balance: BigUInt) -> BigUInt? {
        guard let exchange = Manager.exchange.exchangeInfoList[currency]?.price else { return nil }

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
    
    static func bioVerification(message: String, completion: @escaping ((_ state: LAStatus) -> Void)) {
        let context = LAContext()
        var reason = ""
        
        switch context.biometricType.type {
        case .touchID:
            reason = "LockScreen.Setting.Bio.Use.FaceID".localized
        case .faceID:
            reason = "LockScreen.Setting.Bio.Use.FaceID".localized
        case .none:
            break
            
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (isSuccess, error) in
            
            var state = LAStatus.success
            
            if isSuccess {
                if let domain = context.evaluatedPolicyDomainState {
                    UserDefaults.standard.set(domain, forKey: "domain")
                    UserDefaults.standard.synchronize()
                    
                    Log("save users domain.", .debug)
                }
            } else {
                switch error!._code {
                case LAError.Code.systemCancel.rawValue, LAError.Code.userCancel.rawValue:
                    state = .userCancel
                    break
                    
                case LAError.Code.authenticationFailed.rawValue:
                    state = .failed
                    break
                    
                case LAError.Code.passcodeNotSet.rawValue, LAError.Code.biometryNotEnrolled.rawValue:
                    state = .notUsed
                    break
                    
                case LAError.Code.biometryNotAvailable.rawValue:
                    state = .notSupported
                    break
                    
                case LAError.Code.userFallback.rawValue:
                    state = .userFallback
                    break
                    
                default:
                    if (error!._code == LAError.Code.appCancel.rawValue) {
                        state = .userCancel
                    } else if (error!._code == LAError.Code.biometryLockout.rawValue) {
                        state = .locked
                    } else {
                        state = .userCancel
                    }
                    
                    break
                }
            }
            DispatchQueue.main.async {
                completion(state)
            }
        }
    }
    
    static func canVerificateBiometry() -> LAStatus {
        let context = LAContext()
        
        var errorPointer: NSError?
        let _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &errorPointer)
        
        guard let error = errorPointer as? LAError else {
            return .success
        }
        
        switch error {
        case LAError.biometryLockout:
            return LAStatus.locked
            
        case LAError.biometryNotEnrolled:
            return LAStatus.notUsed
            
        case LAError.biometryNotAvailable:
            return LAStatus.notAvailable
            
        case LAError.passcodeNotSet:
            return LAStatus.passcodeNotSet
            
        default:
            return LAStatus.notSupported
        }
    }
    
    
    static func bioMetryChanged() -> Bool {
        let context = LAContext()
        
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        
        guard let oldDomain = UserDefaults.standard.data(forKey: "domain") else {
            return false
        }
        
        guard let newDomain = context.evaluatedPolicyDomainState else {
            return false
        }
        
        let changed = oldDomain != newDomain
        
        Log("TouchID domain status: \(changed)", .debug)
        
        return changed
    }
    
    static func invalidateBiometry() {
        let context = LAContext()
        
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        
        guard let newDomain = context.evaluatedPolicyDomainState else {
            return
        }
        
        UserDefaults.standard.set(newDomain, forKey: "domain")
        UserDefaults.standard.synchronize()
        
        Log("TouchID domain saved.", .debug)
    }
    
    static func removeBio() {
        UserDefaults.standard.removeObject(forKey: "domain")
        UserDefaults.standard.removeObject(forKey: "useBio")
        UserDefaults.standard.synchronize()
    }
    
    static func removePasscode() {
        UserDefaults.standard.removeObject(forKey: "u8djdnuEe2xIddfkD")
        UserDefaults.standard.removeObject(forKey: "aExd73E0dxvdQrx")
        UserDefaults.standard.removeObject(forKey: "useLock")
        UserDefaults.standard.synchronize()
    }
    
    static func toast(message: String) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        
        guard let window = app.window else { return }
        let toastView = UIView.makeToast(message)
        toastView.alpha = 0.0
        window.addSubview(toastView)
        
        toastView.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 20).isActive = true
        toastView.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20).isActive = true
        toastView.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -46).isActive = true
        
        UIView.animate(withDuration: 0.7, delay: 0.0, options: .curveEaseOut, animations: {
            toastView.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseIn, animations: {
                toastView.alpha = 0.0
            }) { _ in
                toastView.removeFromSuperview()
            }
        })
    }
    
    static func voteToast(count: Int) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        
        guard let window = app.window else { return }
        let voteToast = UIView.makeVoteToast(count: count)
        voteToast.alpha = 0.0
        window.addSubview(voteToast)
        
        voteToast.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 20).isActive = true
        voteToast.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20).isActive = true
        voteToast.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -46).isActive = true
        
        UIView.animate(withDuration: 0.7, delay: 0.0, options: .curveEaseOut, animations: {
            voteToast.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseIn, animations: {
                voteToast.alpha = 0.0
            }) { _ in
                voteToast.removeFromSuperview()
            }
        })
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
