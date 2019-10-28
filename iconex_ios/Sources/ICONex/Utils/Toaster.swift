//
//  Toaster.swift
//  iconex_ios
//
//  Created by a1ahn on 25/10/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class Toaster {
    static let shared = Toaster()
    
    private init() { }
    
    var views = [ToastView]()
    
    func toast(message: String) {
        remove {
            let toastView = ToastView(message)
            self.views.append(toastView)
            toastView.show()
        }
    }
    
    func remove(_ completed: (() -> Void)? = nil) {
        guard let v = views.last else {
            completed?()
            return }
        UIView.animate(withDuration: 0.15, animations: {
            v.alpha = 0.0
        }, completion: { _ in
            v.invalidate()
            self.views.removeAll()
            completed?()
        })
    }
}
    
class ToastView: UIView {
    private var timer: Timer?
    
    init(_ message: String) {
        super.init(frame: .zero)
        self.alpha = 0.0
        
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 14)
        
        //        let toastView = UIView()
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.backgroundColor = UIColor(white: 38.0 / 255.0, alpha: 0.9)
        self.layer.cornerRadius = 8
        
        self.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.topAnchor.constraint(equalTo: self.topAnchor, constant: 12).isActive = true
        label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -12).isActive = true
        label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20).isActive = true
        label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20).isActive = true
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let window = app.window else { return }
        window.addSubview(self)
        
        self.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 20).isActive = true
        self.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20).isActive = true
        self.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -46).isActive = true
        
        UIView.animate(withDuration: 0.15, animations: {
            self.alpha = 1.0
        }) { _ in
            self.setTimer()
        }
    }
    
    private func setTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { _ in
            self.invalidate()
        })
    }
    
    func invalidate() {
        timer?.invalidate()
        timer = nil
        UIView.animate(withDuration: 0.15, animations: {
            self.alpha = 0.0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}

let Toast = Toaster.shared
