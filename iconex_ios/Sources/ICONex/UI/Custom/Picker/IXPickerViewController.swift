//
//  IXPickerViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 02/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class IXPickerViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    
}

class IXPickerViewController: BaseViewController {
    @IBOutlet weak var pickerContainer: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var pickerTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pickerHeight: NSLayoutConstraint!
    @IBOutlet weak var gestureView: UIView!
    
    var items: [String]!
    var selectedAction: ((Int) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        view.alpha = 0.0
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.4)
        
        pickerContainer.alpha = 0.0
        pickerContainer.transform = CGAffineTransform(translationX: 0, y: 50)
        
        if items.count > 5 {
            pickerHeight.constant = 360
        } else {
            pickerHeight.constant = (CGFloat)(60 + 60 * items.count)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
        beginShow()
    }
    
    func beginShow() {
        UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25, animations: {
                self.view.alpha = 1.0
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25, animations: {
                self.pickerContainer.alpha = 1.0
                self.pickerContainer.transform = .identity
            })
        }, completion: nil)
    }
    
    func close(_ row: Int? = nil, _ completion: ((Int) -> Void)? = nil) {
        UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25, animations: {
                self.pickerContainer.alpha = 0.0
                self.pickerContainer.transform = CGAffineTransform(translationX: 0, y: 50)
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25, animations: {
                self.view.alpha = 0.0
            })
        }, completion: { _ in
            self.dismiss(animated: false, completion: {
                if let handler = completion, let index = row {
                    handler(index)
                }
            })
        })
    }
    
    func pop(_ source: UIViewController? = app.topViewController()) {
        source?.present(self, animated: false, completion: {
            self.beginShow()
        })
    }
}

extension IXPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PickerViewCell", for: indexPath) as! IXPickerViewCell
        
        cell.titleLabel.size14(text: items[indexPath.row], color: .gray77)
        
        return cell
    }
}

extension IXPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        close(indexPath.row, selectedAction)
    }
}
