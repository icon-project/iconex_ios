//
//  MyVoteViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 22/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MyVoteViewController: BaseViewController {
    var delegate: VoteMainDelegate!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerFirstItem: UILabel!
    @IBOutlet weak var headerSecondItem: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 262
        tableView.rowHeight = UITableView.automaticDimension
        
        headerFirstItem.size14(text: "My Votes", color: .gray77, weight: .bold, align: .center)
        headerSecondItem.setTitle("P-Reps", for: .normal)
        headerSecondItem.titleLabel?.font = .systemFont(ofSize: 14)
        headerSecondItem.setTitleColor(.gray77, for: .normal)
        
        headerSecondItem.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.delegate.headerSelected(index: 1)
            }).disposed(by: disposeBag)
    }
}

extension MyVoteViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyVoteGeneralCell", for: indexPath)
        
        
        
        return cell
    }
}

extension MyVoteViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 36
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return nil
        } else {
            let sectionHeader = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 36))
            sectionHeader.backgroundColor = .gray250
            let orderButton = UIButton(type: .custom)
            orderButton.setTitle("My Votes ↓", for: .normal)
            orderButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .light)
            orderButton.setTitleColor(.gray77, for: .normal)
            orderButton.translatesAutoresizingMaskIntoConstraints = false
            sectionHeader.addSubview(orderButton)
            orderButton.leadingAnchor.constraint(equalTo: sectionHeader.leadingAnchor, constant: 20).isActive = true
            orderButton.centerYAnchor.constraint(equalTo: sectionHeader.centerYAnchor, constant: 0).isActive = true
            
            let resetButton = UIButton(type: .custom)
            resetButton.setTitle("MyVoteView.VoteReset".localized, for: .normal)
            resetButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .light)
            resetButton.setTitleColor(.gray128, for: .normal)
            resetButton.translatesAutoresizingMaskIntoConstraints = false
            sectionHeader.addSubview(resetButton)
            resetButton.trailingAnchor.constraint(equalTo: sectionHeader.trailingAnchor, constant: -20).isActive = true
            resetButton.centerYAnchor.constraint(equalTo: sectionHeader.centerYAnchor).isActive = true
            
            
            let upperLine = UIView()
            upperLine.backgroundColor = .gray230
            upperLine.translatesAutoresizingMaskIntoConstraints = false
            sectionHeader.addSubview(upperLine)
            upperLine.leadingAnchor.constraint(equalTo: sectionHeader.leadingAnchor).isActive = true
            upperLine.trailingAnchor.constraint(equalTo: sectionHeader.trailingAnchor).isActive = true
            upperLine.topAnchor.constraint(equalTo: sectionHeader.topAnchor).isActive = true
            upperLine.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            let underLine = UIView()
            underLine.backgroundColor = .gray230
            underLine.translatesAutoresizingMaskIntoConstraints = false
            sectionHeader.addSubview(underLine)
            underLine.leadingAnchor.constraint(equalTo: sectionHeader.leadingAnchor).isActive = true
            underLine.trailingAnchor.constraint(equalTo: sectionHeader.trailingAnchor).isActive = true
            underLine.bottomAnchor.constraint(equalTo: sectionHeader.bottomAnchor).isActive = true
            underLine.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            
            
            return sectionHeader
        }
    }
}
