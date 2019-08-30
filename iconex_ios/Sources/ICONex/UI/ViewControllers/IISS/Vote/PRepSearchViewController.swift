//
//  PRepSearchViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 26/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PanModal

protocol PRepSearchDelegate {
    var prepList: [PRepListResponse.PReps] { get }
}

class PRepSearchViewController: BaseViewController {
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var delegate: PRepSearchDelegate!
    
    var searched = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        tableView.register(PRepViewCell.self, forCellReuseIdentifier: "PRepSearchCell")
        tableView.delegate = self
        tableView.dataSource = self
        
        cancelButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
    }
}

extension PRepSearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PRepSearchCell", for: indexPath) as! PRepViewCell
        
        return cell
    }
}

extension PRepSearchViewController: UITableViewDelegate {
    
}

extension PRepSearchViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    func shouldRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return false
    }
    
    var isHapticFeedbackEnabled: Bool {
        return false
    }
    
    var topOffset: CGFloat {
        return app.window!.safeAreaInsets.top
    }
    
    var backgroundAlpha: CGFloat {
        return 0.4
    }
    
    var cornerRadius: CGFloat {
        return 18.0
    }
    
    func pop(_ viewController: UIViewController? = nil) {
        if let source = viewController {
            source.presentPanModal(self)
        } else {
            app.topViewController()?.presentPanModal(self)
        }
    }
}
