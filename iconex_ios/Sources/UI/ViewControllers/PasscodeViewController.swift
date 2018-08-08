//
//  PasscodeViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit

class PasscodeViewController: UIViewController {

    @IBOutlet weak var secureContainer: UIView!
    @IBOutlet weak var numpadContainer: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var lostButton: UIButton!
    
    private var isInitiated = false
    
    private var __passcode: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.initializeUI()
    }

    func initializeUI() {
        
        for view in self.numpadContainer.subviews {
            guard let button = view.subviews.first as? UIButton else {
                continue
            }
            let backImage = UIImage(color: UIColor(hex: 0xffffff, alpha: 0.2))
            button.layer.masksToBounds = true
            button.layer.cornerRadius = button.layer.frame.size.height / 2
            button.setBackgroundImage(backImage, for: .highlighted)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 32)
            
            if button.tag == 11 {
                button.addTarget(self, action: #selector(clickedDelete(_:)), for: .touchUpInside)
            } else {
                button.addTarget(self, action: #selector(clickedNumber(_:)), for: .touchUpInside)
            }
        }
        
        let size = CGSize(width: 12, height: 12)
        
        for i in 0..<6 {
            let x = i * 16 + i * Int(size.width)
            
            let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: x , y: 0), size: size))
            imageView.layer.masksToBounds = true
            imageView.layer.borderWidth = 2.0
            imageView.layer.borderColor = UIColor.white.cgColor
            imageView.layer.cornerRadius = size.height / 2
            
            let highlighted = UIImage(color: UIColor.white)
            let normal = UIImage(color: UIColor.clear)
            
            imageView.image = normal
            imageView.highlightedImage = highlighted
            
            self.secureContainer.addSubview(imageView)
        }
        
        headerLabel.text = "Passcode.Code.Enter".localized
        lostButton.setTitle("Passcode.Code.Forgot".localized, for: .normal)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !isInitiated { checkTouchID() }
    }
    
    func checkTouchID() {
        isInitiated = true
        if Tools.isTouchIDEnabled {
//            if !Tools.touchIDChanged() {
                Tools.touchIDVerification(message: "") { (status) in
                    switch status {
                    case .success:
                        let main = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                        let app = UIApplication.shared.delegate as! AppDelegate
                        app.window?.rootViewController = main
                        break
                        
                    default:
                        break
                    }
                }
//            } else {
//                Alert.Basic(message: "Touch ID 변경 감지").show(self)
//            }
        }
    }
    
    @objc func clickedNumber(_ sender: UIButton) {
        if __passcode.length < 6 {
            __passcode = __passcode + "\(sender.tag)"
            
            if __passcode.length == 6 {
                if Tools.verifyPasscode(code: __passcode) {
                    let main = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                    let app = UIApplication.shared.delegate as! AppDelegate
                    app.window?.rootViewController = main
                } else {
                    headerLabel.text = "Passcode.Code.Retry".localized
                    __passcode = ""
                }
            }
        }
        
        self.refresh()
    }
    
    @objc func clickedDelete(_ sender: UIButton) {
        if __passcode.length > 0 {
            __passcode = String(__passcode.prefix(__passcode.length - 1))
        }
        self.refresh()
    }
    
    func refresh() {

        for i in 0..<6 {
            let imageView = self.secureContainer.subviews[i] as! UIImageView
            if i < __passcode.length {
                imageView.isHighlighted = true
            } else {
                imageView.isHighlighted = false
            }
        }
    }
}
