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
    
    private var myVoteList = [MyVoteEditInfo]()
    private var totalDelegation: TotalDelegation?
    
    private var refreshControl = UIRefreshControl()
    
    private var selectedIndexPath: IndexPath? = nil
    
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
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(loadData), for: .valueChanged)
        
        Manager.voteList.currentAddedList.subscribe(onNext: { addedList in
            self.myVoteList = addedList
            self.tableView.reloadData()
        }).disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        loadData()
    }
}

extension MyVoteViewController {
    @objc func loadData() {
        guard refreshControl.isRefreshing == false else { return }
        refreshControl.beginRefreshing()
        
        Manager.voteList.loadMyVotes(from: delegate.wallet) { totalDelegation, myVotes in
            self.refreshControl.endRefreshing()
            self.totalDelegation = totalDelegation
            self.myVoteList.removeAll()
            if let votes = myVotes {
                self.myVoteList.append(contentsOf: votes)
            }
            self.tableView.reloadData()
        }
    }
}

extension MyVoteViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if totalDelegation == nil {
                return 0
            }
            return 1
        } else {
            return Manager.voteList.votesCount
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let info = self.totalDelegation!
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyVoteGeneralCell", for: indexPath) as! MyVoteGeneralCell
            
            cell.set(info: info)
            
            return cell
        } else {
            let total = totalDelegation!.delegations
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyVoteDelegateCell", for: indexPath) as! MyVoteDelegateCell
            if indexPath.row < total.count {
                let info = myVoteList[indexPath.row]
                cell.prepName.size12(text: info.prepName, color: .gray77, weight: .semibold)
                cell.totalVotedValue.size12(text: info.totalDelegate.toString(decimal: 18, 4, false), color: .gray77, weight: .semibold)
                cell.addButton.isSelected = false
                cell.addButton.isEnabled = false
            } else {
                let info = Manager.voteList.myAddList[indexPath.row - total.count]
                cell.prepName.size12(text: info.prepName, color: .gray77, weight: .semibold)
                cell.totalVotedValue.size12(text: info.totalDelegate.toString(decimal: 18, 4, false), color: .gray77, weight: .semibold)
                cell.addButton.isSelected = true
                cell.addButton.isEnabled = true
                cell.addButton.rx.tap
                    .subscribe(onNext: {
                        Manager.voteList.remove(prep: info)
                        tableView.reloadData()
                    }).disposed(by: disposeBag)
                cell.slider.rx.value.subscribe(onNext: { value in
                    cell.current = value
                }).disposed(by: cell.disposeBag)
                
//                cell.currentValue
//                    .observeOn(MainScheduler.asyncInstance)
//                    .distinctUntilChanged()
//                    .debounce(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
//                    .subscribe(onNext: { current in
//
//                        Log("CURRENT \(current)")
//
//                    }).disposed(by: cell.disposeBag)
            }
            
            return cell
        }
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            selectedIndexPath = indexPath
            tableView.beginUpdates()
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            tableView.endUpdates()
        }
    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        guard let selected = selectedIndexPath else { return }
//    }
}
