//
//  MainViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 02/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

private let Header_Height: CGFloat = 148

class MainViewController: BaseViewController {
    @IBOutlet weak var testButton: UIButton!
    @IBOutlet weak var testButton2: UIButton!
    @IBOutlet weak var navBar: IXNavigationView!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentTop: NSLayoutConstraint!
    @IBOutlet weak var backHeight: NSLayoutConstraint!
    @IBOutlet weak var contentHeight: NSLayoutConstraint!
    @IBOutlet weak var contentBottom: NSLayoutConstraint!
    
    @IBOutlet weak var stackMultiplier: NSLayoutConstraint!
    
    private var startPoint: CGPoint = .zero
    
    private let gradient = CAGradientLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        view.backgroundColor = .mint1
        backView.backgroundColor = UIColor(245, 245, 245)
        gradient.colors = [UIColor.mint1.cgColor, UIColor.gray245.cgColor]
        gradient.locations = [0.0, 1.0]
        gradientView.layer.addSublayer(gradient)
        
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        self.contentView.addGestureRecognizer(panGesture)
        
//        testButton.rx.tap.subscribe(onNext: {
//            let main = UIStoryboard(name: "LoadWallet", bundle: nil).instantiateInitialViewController()!
//
//            self.navigationController?.pushViewController(main, animated: true)
//        }).disposed(by: disposeBag)
//
//        testButton2.rx.tap.subscribe(onNext: {
//            guard let wallet = Manager.wallet.walletList.first as? ICXWallet else { return }
//            let iscore = UIStoryboard(name: "IScore", bundle: nil).instantiateInitialViewController() as! IScoreDetailViewController
//            iscore.wallet = wallet
//            self.navigationController?.pushViewController(iscore, animated: true)
//        }).disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        
        navBar.setTitle("타이틀")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = gradientView.bounds
    }

}

extension MainViewController {
    @objc func panGesture(_ recon: UIPanGestureRecognizer) {
        let point = recon.location(in: view)
        let offset = startPoint - point
        
        switch recon.state {
        case .began:
            Log("Start - \(point.x),  \(point.y)")
            startPoint = point
            
        case .changed:
            Log("Point - \(point.y), Offset - \(offset.y)")
            if offset.y > 0 {
                /// Going up
                if Header_Height > offset.y {
                    contentTop.constant = -offset.y
                }
            } else {
                contentHeight.constant = Header_Height + abs(offset.y)
                backHeight.constant = Header_Height + abs(offset.y)
                contentBottom.constant = abs(offset.y)
            }
            
        default:
            if offset.y > 0 {
                
                if contentTop.constant < -Header_Height / 2 {
                    contentTop.constant = -Header_Height
                } else {
                    contentTop.constant = 0
                }
                
            } else {
                contentHeight.constant = Header_Height
                backHeight.constant = Header_Height
                contentBottom.constant = 0
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
    }
}

extension MainViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        Log(scrollView)
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        Log(scrollView)
    }
}

extension CGPoint {
    static func - (lhd: CGPoint, rhd: CGPoint) -> CGPoint {
        return CGPoint(x: lhd.x - rhd.x, y: lhd.y - rhd.y)
    }
}
