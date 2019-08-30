//
//  SideMenuViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 14/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class SideMenuViewController: BaseViewController {
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var dismissView: UIView!
    
    @IBOutlet weak var logoPlanet: UIImageView!
    @IBOutlet weak var logoSatellite: UIImageView!
    
    @IBOutlet weak var topStackView: UIStackView!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    
    @IBOutlet weak var lineView: UIView!
    
    @IBOutlet weak var bottomStackView: UIStackView!
    @IBOutlet weak var button4: UIButton!
    @IBOutlet weak var button5: UIButton!
    @IBOutlet weak var button6: UIButton!
    
    private var isAnimated: Bool = false
    
    let gradient = CAGradientLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = menuView.bounds
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        // init
        self.view.backgroundColor = .clear
        self.backView.backgroundColor = UIColor.init(white: 0, alpha: 0.0)
        
        gradient.colors = [UIColor.mint1.cgColor, UIColor.gray245.cgColor]
        gradient.locations = [0.5, 1.0]
        menuView.layer.insertSublayer(gradient, at: 0)
        gradient.frame = menuView.bounds
        
        self.menuView.frame.origin.x = -self.menuView.frame.width
        self.lineView.alpha = 0
        self.topStackView.frame.origin.y += 10
        self.bottomStackView.frame.origin.y += 10
        self.topStackView.alpha = 0
        self.bottomStackView.alpha = 0
        self.logoPlanet.alpha = 0
        self.logoSatellite.alpha = 0
        
        let tapGesture = UITapGestureRecognizer()
        self.dismissView.addGestureRecognizer(tapGesture)
        
        tapGesture.rx.event.subscribe { (_) in
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.menuView.frame.origin.x = -self.menuView.frame.width
                self.backView.backgroundColor = UIColor.init(white: 0, alpha: 0.0) // ??
            }, completion: { (_) in
                self.dismiss(animated: true, completion: nil)
            })
            
        }.disposed(by: disposeBag)
        
        button1.setTitle("Side.Create".localized, for: .normal)
        button2.setTitle("Side.Load".localized, for: .normal)
        button3.setTitle("Side.Export".localized, for: .normal)
        button4.setTitle("Side.Lock".localized, for: .normal)
        button5.setTitle("Side.Version".localized, for: .normal)
        button6.setTitle("Side.Disclaimer".localized, for: .normal)
        
        button1.setTitleColor(.white, for: .normal)
        button2.setTitleColor(.white, for: .normal)
        button3.setTitleColor(.white, for: .normal)
        button4.setTitleColor(.white, for: .normal)
        button5.setTitleColor(.white, for: .normal)
        button6.setTitleColor(.white, for: .normal)
        
        // Create
        button1.rx.tap.asControlEvent().subscribe { (_) in
            let createVC = UIStoryboard.init(name: "CreateWallet", bundle: nil).instantiateInitialViewController() as! CreateWalletViewController
            createVC.pop()
        }.disposed(by: disposeBag)
        
        // Load
        button2.rx.tap.asControlEvent().subscribe { (_) in
            let loadVC = UIStoryboard.init(name: "LoadWallet", bundle: nil).instantiateInitialViewController() as! LoadWalletViewController
            loadVC.pop()
        }.disposed(by: disposeBag)
        
        // Export
        button3.rx.tap.asControlEvent().subscribe { (_) in
            
        }.disposed(by: disposeBag)
        
        // Lock
        button4.rx.tap.asControlEvent().subscribe { (_) in
            
        }.disposed(by: disposeBag)
        
        // Version
        button5.rx.tap.asControlEvent().subscribe { (_) in
            
        }.disposed(by: disposeBag)
        
        // Disclaimer
        button6.rx.tap.asControlEvent().subscribe { (_) in
            
        }.disposed(by: disposeBag)
        
    }
    
    override func refresh() {
        super.refresh()
        
        if !isAnimated {
            self.isAnimated.toggle()
            showAnimate()
        }
    }
    
    func showAnimate() {
        UIView.animate(withDuration: 0.3, animations: {
            self.backView.backgroundColor = UIColor.init(white: 0, alpha: 0.4)
        }, completion: nil)
        
        UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseInOut, animations: {
            self.menuView.frame.origin.x = 0
        })
        
        UIView.animate(withDuration: 0.3, delay: 0.7, options: .curveEaseInOut, animations: {
            self.lineView.alpha = 0.5
        })
        
        UIView.animate(withDuration: 0.4, delay: 0.6, options: .curveEaseInOut, animations: {
            self.topStackView.frame.origin.y -= 10
            self.bottomStackView.frame.origin.y -= 10
            self.topStackView.alpha = 1
            self.bottomStackView.alpha = 1
            self.logoPlanet.alpha = 1
            self.logoSatellite.alpha = 1
        })
        
        
        UIView.animate(withDuration: 0.4, delay: 2.7, options: .curveEaseInOut, animations: {
            self.logoPlanet.transform = CGAffineTransform(rotationAngle: .pi)
            self.logoSatellite.transform = CGAffineTransform(rotationAngle: -3.14159256)
        })
    }
}

class SideButton: UIButton {
    override var isHighlighted: Bool {
        willSet {
           self.backgroundColor = newValue ? UIColor.init(white: 1, alpha: 0.1) : .clear
        }
    }
}