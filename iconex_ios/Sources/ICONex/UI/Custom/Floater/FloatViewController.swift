//
//  FloatViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 28/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class FloatViewController: BaseViewController {
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var roundedButton: UIButton!
    
    @IBOutlet weak var menuContainer: UIView!
    @IBOutlet weak var headerButton: UIButton!
    @IBOutlet weak var mainMenu: UIView!
    @IBOutlet weak var menuButton1: UIButton!
    @IBOutlet weak var menuButton2: UIButton!
    @IBOutlet weak var menuButton3: UIButton!
    
    private let gradient = CAGradientLayer()
    
    var type: FloaterType = .wallet
    
    var headerAction: (() -> Void)?
    var itemAction1: (() -> Void)?
    var itemAction2: (() -> Void)?
    var itemAction3: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        gradient.colors = [UIColor(255, 255, 255, 0).cgColor, UIColor.white.cgColor]
        gradient.locations = [0.0, 1.0]
        dimView.layer.addSublayer(gradient)
        view.sendSubviewToBack(dimView)
        
        roundedButton.setBackgroundImage(color: UIColor(65, 65, 65), state: .normal)
        roundedButton.corner(roundedButton.frame.height / 2)
        roundedButton.setImage(#imageLiteral(resourceName: "icAppbarCloseW"), for: .normal)
        
        headerButton.corner(8)
        decorateButton(headerButton)
        
        mainMenu.corner(8)
        decorateButton(menuButton1)
        decorateButton(menuButton2)
        decorateButton(menuButton3)
        
        switch type {
        case .vote:
            headerButton.isHidden = false
            menuButton3.isHidden = false
            headerButton.setTitle("Floater.Vote.PReps".localized, for: .normal)
            menuButton1.setImage(nil, for: .normal)
            menuButton1.setTitle("Floater.Vote.Stake".localized, for: .normal)
            menuButton2.setImage(nil, for: .normal)
            menuButton2.setTitle("Floater.Vote.Vote".localized, for: .normal)
            menuButton3.setImage(nil, for: .normal)
            menuButton3.setTitle("Floater.Vote.IScore".localized, for: .normal)
            headerButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.beginHide(action: {
                        self?.headerAction?()
                    })
                }).disposed(by: disposeBag)
            
        case .wallet:
            headerButton.isHidden = true
            menuButton3.isHidden = true
            menuButton1.setImage(#imageLiteral(resourceName: "icWalletDeposit"), for: .normal)
            menuButton1.setTitle("Floater.Wallet.Deposit".localized, for: .normal)
            menuButton2.setImage(#imageLiteral(resourceName: "icWalletSend"), for: .normal)
            menuButton2.setTitle("Floater.Wallet.Send".localized, for: .normal)
            
        default:
            break
        }
        menuButton1.rx.tap.subscribe(onNext: { [weak self] in
            self?.beginHide(action: {
                self?.itemAction1?()
            })
        }).disposed(by: disposeBag)
        menuButton2.rx.tap.subscribe(onNext: { [weak self] in
            self?.beginHide(action: {
                self?.itemAction2?()
            })
        }).disposed(by: disposeBag)
        menuButton3.rx.tap.subscribe(onNext: { [weak self] in
            self?.beginHide(action: {
                self?.itemAction3?()
            })
        }).disposed(by: disposeBag)
        
        dimView.alpha = 0.0
        menuContainer.alpha = 0.0
        
        roundedButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.beginHide()
            }).disposed(by: disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = dimView.bounds
    }
    
    func pop() {
        app.topViewController()?.present(self, animated: false, completion: {
            self.beginShow()
        })
    }
    
    func beginShow() {
        self.menuContainer.transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(withDuration: 0.1) {
            self.dimView.alpha = 1.0
            self.menuContainer.alpha = 1.0
            self.menuContainer.transform = .identity
        }
    }
    
    func beginHide(action: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.1, animations: {
            self.dimView.alpha = 0.0
            self.menuContainer.alpha = 0.0
            self.menuContainer.transform = CGAffineTransform(translationX: 0, y: 20)
        }) { _ in
            self.dismiss(animated: false, completion: {
                action?()
            })
        }
    }
}

extension FloatViewController {
    func decorateButton(_ btn: UIButton) {
        btn.setBackgroundImage(color: UIColor(38, 38, 38, 0.9), state: .normal)
        btn.setBackgroundImage(color: UIColor(38, 38, 38), state: .highlighted)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
    }
}
