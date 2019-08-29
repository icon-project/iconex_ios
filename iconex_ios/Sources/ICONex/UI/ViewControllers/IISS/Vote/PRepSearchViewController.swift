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
    @IBOutlet weak var bottomAnchor: NSLayoutConstraint!
    
    var delegate: PRepSearchDelegate!
    
    var searched = [PRepListResponse.PReps]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        searchField.placeholder = "PRepSearch.Placeholder".localized
        
        cancelButton.setTitle("Common.Cancel".localized, for: .normal)
        cancelButton.setTitleColor(.gray128, for: .normal)
        
        tableView.register(UINib(nibName: "PRepViewCell", bundle: nil), forCellReuseIdentifier: "PRepSearchCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        cancelButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        searchField.tintColor = .mint1
        searchField.rx.text.orEmpty
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] string in
                guard let list = self?.delegate.prepList else { return }
                self?.searched.removeAll()
                self?.searched.append(contentsOf: list.filter { $0.name.contains(string) })
                self?.tableView.reloadData()
            }).disposed(by: disposeBag)
        searchField.becomeFirstResponder()
        
        keyboardHeight().asObservable().subscribe(onNext: { height in
            if height == 0 {
                self.bottomAnchor.constant = 0
            } else {
                let keyboardHeight = height - self.view.safeAreaInsets.bottom
                self.bottomAnchor.constant = keyboardHeight
            }
        }).disposed(by: disposeBag)
    }
}

extension PRepSearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searched.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PRepSearchCell", for: indexPath) as! PRepViewCell
        let prep = searched[indexPath.row]
        
        cell.prepNameLabel.size12(text: prep.name, color: .gray77, weight: .semibold, align: .left)
        cell.totalVoteValue.size12(text: prep.delegated.toString(decimal: 18, 4, false), color: .gray77, weight: .semibold, align: .right)
        cell.active = true
        
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
