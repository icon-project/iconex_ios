//
//  PasscodeViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 31/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import AudioToolbox
import LocalAuthentication
import CryptoSwift
import PanModal

class PasscodeViewController: BaseViewController {
    
    @IBOutlet weak var statusCoverView: UIView!
    @IBOutlet weak var navBar: IXNavigationView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bubbleStack: UIStackView!
    @IBOutlet weak var numberStack: UIStackView!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    var completeHandler: (() -> Void)? = nil
    
    var lockType: LockType = .activate
    
    var tmpPassword: String = ""
    var passcode: String = ""
    
    var isChecked: Bool = true
    var isConfirm: Bool = false
    
    override func initializeComponents() {
        super.initializeComponents()
        
        if self.lockType == .check {
            self.statusCoverView.isHidden = true
            self.navBar.isHidden = true
            
        } else {
            self.statusCoverView.isHidden = false
            self.navBar.isHidden = false
        }
        
        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarBack")) {
            self.navigationController?.popToRootViewController(animated: true)
        }
        
        switch self.lockType {
        case .activate:
            navBar.setTitle("LockSetting.Activate.NavBar.Title".localized)
        case .change:
            navBar.setTitle("LockSetting.Change.NavBar.Title".localized)
        case .deactivate:
            navBar.setTitle("LockSetting.Deactivate.NavBar.Title".localized)
        default: break
        }
        
        self.titleLabel.numberOfLines = 2
        
        setUpBindNumberView()
        setBubbleView()
        
        forgotPasswordButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let resetPassword = self.storyboard?.instantiateViewController(withIdentifier: "Reset") as! ResetPasswordViewController
                self.presentPanModal(resetPassword)
                
        }.disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        
        self.setPassStatus(status: .initial)
        
        if self.lockType == .check {
            forgotPasswordButton.setTitle("Passcode.Code.Forgot".localized, for: .normal)
            forgotPasswordButton.setTitleColor(.init(white: 1, alpha: 0.5), for: .normal)
            forgotPasswordButton.titleLabel?.textAlignment = .center
            forgotPasswordButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .light)
        }
        forgotPasswordButton.isHidden = lockType == .check ? false : true
        self.view.backgroundColor = lockType == .check ? .mint1 : .white
        
        setBubbleView()
        setNumberView()
        
        setUpAnimation()
        animateComponent()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        for line in numberStack.arrangedSubviews {
            let lineStack = line as! UIStackView
            
            for button in lineStack.arrangedSubviews {
                let btn = button as! UIButton
                
                btn.corner(btn.frame.height / 2)
                if self.lockType == .check {
                    btn.setBackgroundImage(UIImage(color: .init(white: 1, alpha: 0.2)), for: .highlighted)
                } else {
                    btn.setBackgroundImage(UIImage(color: UIColor(38, 38, 38, 0.03)), for: .highlighted)
                }
                
            }
        }
        
        if self.lockType == .check {
            let bio = LAContext().biometricType
            
            if UserDefaults.standard.bool(forKey: "useBio") {
                
                Tool.bioVerification(message: "", completion: { (state) in
                    switch state {
                        case .success:
                            self.dismiss(animated: true, completion: {
                                self.completeHandler?()
                            })
                        
                        
                        case .locked:
                            Alert.basic(title: bio.type == .faceID ? "LockSetting.FaceID.Locked".localized : "LockSetting.TouchID.Locked".localized, leftButtonTitle: "Common.Confirm".localized, confirmAction: nil).show()
                        
                        case .failed, .userCancel, .userFallback:
                            break
                        
                        case .notUsed:
                            Alert.basic(title: bio.type == .faceID ? "LockSetting.Alert.FaceID".localized : "LockSetting.Alert.TouchID".localized, leftButtonTitle: "Common.Confirm".localized).show()
                            UserDefaults.standard.removeObject(forKey: "useBio")
                            break
                        
                        default:
                            UserDefaults.standard.removeObject(forKey: "useBio")
                    }
                })
            } else {
                
            }
        }
    }
    
    func setUpAnimation() {
        self.titleLabel.alpha = 0
        self.bubbleStack.alpha = 0
        self.numberStack.alpha = 0
        self.forgotPasswordButton.alpha = 0
    }
    
    func animateComponent() {
        UIView.animate(withDuration: 0.6, delay: 0.0, options: .curveEaseInOut, animations: {
            self.titleLabel.alpha = 1.0
            self.bubbleStack.alpha = 1.0
            self.numberStack.alpha = 1.0
        }, completion: nil)
        
        UIView.animate(withDuration: 0.6, delay: 0.1, options: .curveEaseInOut, animations: {
            self.forgotPasswordButton.alpha = 1.0
        }, completion: nil)
    }
    
    private func setUpBindNumberView() {
        for line in numberStack.arrangedSubviews {
            let lineStack = line as! UIStackView
            
            for button in lineStack.arrangedSubviews {
                let btn = button as! UIButton
                
                btn.layer.cornerRadius = btn.frame.height/2
                    
                btn.rx.tap.asControlEvent()
                    .subscribe { _ in
                        if btn.tag == 99 && self.tmpPassword.count > 0 {
                            self.clearBubble(self.tmpPassword.count-1)
                            self.tmpPassword.removeLast()
                            
                        } else {
                            if self.tmpPassword.count < 6 {
                                guard let number = btn.currentTitle else { return }
                                
                                self.tmpPassword.append(number)
                                self.fillBubble(self.tmpPassword.count-1)
                                
                            }
                        }
                        
                        if self.tmpPassword.count == 6 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                                self.validatePasscode()
                            })
                        }
                    }.disposed(by: disposeBag)
            }
        }
    }
    
    private func setBubbleView() {
        for bubble in bubbleStack.arrangedSubviews {
            bubble.layer.cornerRadius = bubble.frame.width/2
            bubble.backgroundColor = .clear
            bubble.layer.borderWidth = 1
            
            if lockType == .check {
                bubble.layer.borderColor = UIColor.init(white: 1, alpha: 0.5).cgColor
            } else {
                bubble.layer.borderColor = UIColor.gray179.cgColor
            }
        }
    }
    
    private func setNumberView() {
        for (index1,line) in numberStack.arrangedSubviews.enumerated() {
            let lineStack = line as! UIStackView
            
            for (index2, button) in lineStack.arrangedSubviews.enumerated() {
                let btn = button as! UIButton
                
                if lockType == .check {
                    btn.setTitleColor(.white, for: .normal)
                    if index1 == 3 && index2 == 2 {
                        btn.setImage(UIImage(named: "btnKeypadDeleteW"), for: .normal)
                    }
                } else {
                    btn.setTitleColor(.gray77, for: .normal)
                    if index1 == 3 && index2 == 2 {
                        btn.setImage(UIImage(named: "btnKeypadDelete"), for: .normal)
                    }
                }
            }
        }
    }
    
    private func fillBubble(_ index: Int) {
        let arr = self.bubbleStack.arrangedSubviews
        
        arr[index].alpha = 0.0
        arr[index].center.y -= 5
        
        arr[index].border(0, .clear)
        if self.lockType == .check {
            arr[index].backgroundColor = .white
        } else {
            arr[index].backgroundColor = .gray77
        }
        
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
            arr[index].alpha = 1.0
            arr[index].center.y += 5
        }, completion: nil)
    }
    
    private func clearBubble(_ index: Int) {
        let arr = self.bubbleStack.arrangedSubviews
        arr[index].backgroundColor = .clear
        
        if lockType == .check {
            arr[index].border(1, UIColor.init(white: 1, alpha: 0.5))
        } else {
            arr[index].border(1, .gray179)
        }
    }
    
    private func clearBubbleAll() {
        for i in 0...5 {
            self.clearBubble(i)
        }
    }
    
    private func validatePasscode() {
        guard tmpPassword.count == 6 else { return }
        
        switch self.lockType {
        case .activate:
            if !self.isConfirm {
                self.setPassStatus(status: .renewCheck)
                
                self.isConfirm.toggle()
                self.passcode = tmpPassword
                self.clearBubbleAll()
                
            } else {
                if tmpPassword == self.passcode {
                    if Tool.createPasscode(code: self.passcode) {
                        self.reset()
                    }
                    if let navigationController = self.navigationController {
                        navigationController.popToRootViewController(animated: true)
                        
                    } else { // reset
                        self.dismiss(animated: true) {
                            mainViewModel.reload.onNext(true)
                            self.completeHandler?()
                        }
                    }
                } else {
                    self.setPassStatus(status: .renewFail)
                    
                    self.reset()
                }
            }
        case .change:
            if self.isChecked {
                if Tool.verifyPasscode(code: tmpPassword) {
                    self.setPassStatus(status: .new)
                    self.isChecked.toggle()
                } else {
                    self.setPassStatus(status: .invalid)
                }
                self.clearBubbleAll()
            } else {
                if !self.isConfirm {
                    self.clearBubbleAll()
                    
                    if Tool.verifyPasscode(code: tmpPassword) {
                        self.setPassStatus(status: .same)
                    } else {
                        self.setPassStatus(status: .renewCheck)
                        
                        self.passcode = tmpPassword
                        self.isConfirm.toggle()
                    }
                    
                } else {
                    if self.passcode == tmpPassword {
                        if Tool.createPasscode(code: self.passcode) {
                            self.reset()
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    } else {
                        self.setPassStatus(status: .renewFail)
                        clearBubbleAll()
                        passcode.removeAll()
                        isConfirm = false
                    }
                }
            }
            
        case .deactivate:
            if Tool.verifyPasscode(code: tmpPassword) {
                Tool.removePasscode()
                Tool.removeBio()
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                self.setPassStatus(status: .invalid)
                self.reset()
            }
        case .check:
            if Tool.verifyPasscode(code: tmpPassword) {
                self.reset()
                self.dismiss(animated: true, completion: {
                    app.usingLock = false
                    self.completeHandler?()
                })
            } else {
                self.setPassStatus(status: .invalid)
                
                self.passcode.removeAll()
                
                let animationX = CAKeyframeAnimation(keyPath: "transform.translation.x")
                animationX.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                animationX.duration = 0.05
                animationX.repeatCount = 2
                animationX.values = [8.0, -3.0, 8.0, -3.0]
                
                let animationY = CAKeyframeAnimation(keyPath: "transform.translation.y")
                animationY.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                animationY.duration = 0.05
                animationY.repeatCount = 2
                animationY.values = [8.0, -3.0, 8.0, -3.0]
                
                for i in self.bubbleStack.arrangedSubviews {
                    i.layer.add(animationX, forKey: "transform.translation.x")
                    i.layer.add(animationY, forKey: "transform.translation.y")
                }
                
                // vibrate - Error
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                
                UIView.animate(withDuration: 0.8, delay: 0.0, options: .curveEaseInOut , animations: {
                    self.clearBubbleAll()
                }, completion: nil)
            }
        }
        self.tmpPassword.removeAll()
    }
    
    func reset() {
        self.clearBubbleAll()
        
        self.passcode.removeAll()
        self.isConfirm = false
        self.isChecked = true
    }
    
    private func setPassStatus(status: PasscodeStatus) {
        let type = self.lockType
        
        let titleString: String = {
            switch type {
            case .check where status == .initial: return "Passcode.Code.Enter".localized
            case .check where status == .invalid: return "Passcode.Code.Retry".localized
                
            case .activate where status == .initial: return "LockScreen.Setting.Passcode.Header".localized
            case .activate where status == .title: return "LockScreen.Setting.Title".localized
            case .activate where status == .renewCheck: return "LockScreen.Setting.Passcode.Header_2".localized
            case .activate where status == .renewFail: return "LockScreen.Setting.Passcode.Change.Error".localized
                
            case .change where status == .initial: return "LockScreen.Setting.Passcode.Change.Current".localized
            case .change where status == .title: return "LockScreen.Setting.ChangeCode.Title".localized
            case .change where status == .new: return "LockScreen.Setting.Passcode.Change.New".localized
            case .change where status == .renewCheck: return "LockScreen.Setting.Passcode.Change.Renew".localized
            case .change where status == .renewFail: return "LockScreen.Setting.Passcode.Change.Error".localized
            case .change where status == .same: return "LockScreen.Setting.Passcode.Same".localized
            case .change where status == .invalid: return "LockScreen.Setting.Passcode.Header_Error".localized
                
            case .deactivate where status == .initial: return "LockScreen.Setting.Passcode.Change.Current".localized
            case .deactivate where status == .title: return "Passcode.Code.Enter".localized
            case .deactivate where status == .invalid: return "LockScreen.Setting.Passcode.Header_Error".localized
            default: return ""
            }
        }()
        titleLabel.size18(text: titleString, color: lockType == .check ? UIColor.init(white: 1, alpha: 0.5) : .gray77, align: .center, lineBreakMode: .byWordWrapping)
    }
}

public enum LockType {
    case activate, deactivate, change, check
}

public enum PasscodeStatus {
    case initial, title, new, renewCheck, renewFail, invalid, same
}
