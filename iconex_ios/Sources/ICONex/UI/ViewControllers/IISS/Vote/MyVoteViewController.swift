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
import BigInt

class MyVoteViewController: BaseViewController {
    var delegate: VoteMainDelegate!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerFirstItem: UILabel!
    @IBOutlet weak var headerSecondItem: UIButton!
    
    private var myVoteList = [MyVoteEditInfo]()
    private var newList = [MyVoteEditInfo]()
    
    private var totalDelegation: TotalDelegation?
    
    private var refreshControl = UIRefreshControl()
    
    private var selectedIndexPath: IndexPath? = nil
    
    private var available: BigUInt = 0
    
    private var sectionHeader = UIView()
    
    private var scrollPoint: CGFloat = 0
    
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
        
        refreshControl.rx.controlEvent(.valueChanged)
            .subscribe { (_) in
                self.loadData()
            }.disposed(by: disposeBag)
        
        Manager.voteList.currentAddedList.subscribe(onNext: { addedList in
            self.newList = addedList
            voteViewModel.newList.onNext(addedList)
            self.tableView.reloadData()
        }).disposed(by: disposeBag)
        
        voteViewModel.available.subscribe(onNext: { (value) in
            self.available = value
        }).disposed(by: disposeBag)
        
        voteViewModel.myList.onNext(self.myVoteList)
        voteViewModel.newList.onNext(self.newList)
        
        // section header
        sectionHeader = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 36))
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
        
        
        resetButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                Alert.basic(title: "MyVoteView.Alert.Reset".localized, isOnlyOneButton: false, confirmAction: {
                    for (index, list) in self.myVoteList.enumerated() {
                        var item = list
                        item.editedDelegate = 0
                        
                        self.myVoteList[index] = item
                    }
                    
                    for (index, list) in self.newList.enumerated() {
                        var item = list
                        item.editedDelegate = 0
                        
                        self.myVoteList[index] = item
                    }
                    
                    voteViewModel.myList.onNext(self.myVoteList)
                    voteViewModel.newList.onNext(self.newList)
                    
                    voteViewModel.isChanged.onNext(true)
                    
                    self.tableView.reloadData()
                    
                }).show()
            }.disposed(by: disposeBag)
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
        
        Manager.voteList.loadMyVotes(from: delegate.wallet) { tDelegation, myVotes in
            self.refreshControl.endRefreshing()
            self.totalDelegation = tDelegation
            self.myVoteList.removeAll()
            if let votes = myVotes {
                self.myVoteList.append(contentsOf: votes)
            }
            
            voteViewModel.available.onNext(tDelegation?.votingPower ?? 0)
            voteViewModel.myList.onNext(self.myVoteList)
            
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
        // voted (VP)
        // available (VP)
        if indexPath.section == 0 {
            let info = self.totalDelegation!
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyVoteGeneralCell", for: indexPath) as! MyVoteGeneralCell
            
            cell.set(info: info)
            voteViewModel.available.onNext(self.totalDelegation?.votingPower ?? 0)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyVoteDelegateCell", for: indexPath) as! MyVoteDelegateCell
            
            guard let totalDelegationList = totalDelegation?.delegations else {
                Log("totaldelegation is empty", .debug)
                return cell
            }
            
            if selectedIndexPath == indexPath {
                cell.sliderBoxView.isHidden = false
            } else {
                cell.sliderBoxView.isHidden = true
            }
            
            let delegated = Manager.voteList.myVotes?.totalDelegated ?? 0
            let votingPower = Manager.voteList.myVotes?.votingPower ?? 0
            let stakedTotalValue = delegated + votingPower
            
            let fixedAvailable = self.available
            
            if indexPath.row < totalDelegationList.count {
                let info = myVoteList[indexPath.row]
                
                let my: BigUInt = {
                    if let edited = info.editedDelegate {
                        return edited
                    } else {
                        return info.myDelegate ?? 0
                    }
                }()
                
                cell.prepName.size12(text: info.prepName, color: .gray77, weight: .semibold)
                cell.totalVotedValue.size12(text: info.totalDelegate.toString(decimal: 18, 4, false), color: .gray77, weight: .semibold)
                
                cell.addButton.isHighlighted = false
                cell.addButton.rx.tap.asControlEvent()
                    .subscribe { (_) in
                        self.tableView.showToolTip(sizeY: cell.frame.origin.y-self.scrollPoint)
                    }.disposed(by: cell.disposeBag)
                
                let sliderMaxValue = fixedAvailable + my
                
                let child = sliderMaxValue.decimalNumber ?? 0.0
                let parentDecimal = stakedTotalValue.decimalNumber ?? 0.0
                let percent = (child / parentDecimal) * 100
                let percentFloat = percent.floatValue
                
                cell.myVoteMaxValue = "\(percentFloat)%"
                
                if let myDelegateInfo = info.myDelegate {
                    let myDelegateDecimal = myDelegateInfo.decimalNumber ?? 0.0
                    let sliderDecimal = sliderMaxValue.decimalNumber ?? 0.0

                    let calculated = myDelegateDecimal / sliderDecimal
                    let sliderPercent = calculated.floatValue
                    cell.current = sliderPercent
                    cell.slider.value = sliderPercent
                    
                    let currentICXValue = myDelegateInfo.toString(decimal: 18, 4).currencySeparated()
                    cell.myVotesField.text = currentICXValue

                }
                
                cell.slider.rx.value.skip(1).distinctUntilChanged()
                    .subscribe(onNext: { value in
                        cell.current = value
                        
                        var this = self.myVoteList[indexPath.row]
                        let power = sliderMaxValue.decimalNumber ?? 0
                        let valueDecimal = NSDecimalNumber(value: value).decimalValue
                        let rateValueNum = power * valueDecimal
                        let rateValue = BigUInt(rateValueNum.floatValue)
                        
                        this.editedDelegate = rateValue
                        
                        cell.slider.value = valueDecimal.floatValue
                        
                        let currentICXValue = rateValue.toString(decimal: 18, 4).currencySeparated()
                        cell.myVotesField.text = currentICXValue
                        
//                        let voteUnit = rateValueNum.floatValue
//                        cell.myVotesUnitLabel.text = "(\(voteUnit)%)"
                        
                        self.myVoteList[indexPath.row] = this
                        
                        voteViewModel.myList.onNext(self.myVoteList)
                        voteViewModel.isChanged.onNext(true)
                        
                    }).disposed(by: cell.disposeBag)
                
            } else {
                var info = self.newList[indexPath.row - totalDelegationList.count]
                cell.prepName.size12(text: info.prepName, color: .gray77, weight: .semibold)
                cell.totalVotedValue.size12(text: info.totalDelegate.toString(decimal: 18, 4, false), color: .gray77, weight: .semibold)
//                cell.addButton.isSelected = true
//                cell.addButton.isEnabled = true
                cell.addButton.isHighlighted = true
                cell.addButton.rx.tap
                    .subscribe(onNext: {
                        Manager.voteList.remove(prep: info)
                        tableView.reloadData()
                    }).disposed(by: cell.disposeBag)
                
                let delegate = info.editedDelegate ?? 0
                let sliderMaxValue = fixedAvailable + delegate
                
                let child = sliderMaxValue.decimalNumber ?? 0.0
                let parentDecimal = stakedTotalValue.decimalNumber ?? 0.0
                let percent = (child / parentDecimal) * 100
                let percentFloat = percent.floatValue
                
                cell.myVoteMaxValue = "\(percentFloat)%"
                
                if let value = info.editedDelegate {
                    let sliderValue = value.decimalNumber ?? 0
                    let totalValue = sliderMaxValue.decimalNumber ?? 0
                    let calculated = sliderValue / totalValue
                    cell.slider.value = calculated.floatValue
                    let currentICXValue = value.toString(decimal: 18, 4).currencySeparated()
                    cell.myVotesField.text = currentICXValue
                    
                    voteViewModel.isChanged.onNext(true)
                } else {
                    cell.slider.value = 0.0
                }
                
                cell.slider.rx.value.skip(1).distinctUntilChanged()
                    .subscribe(onNext: { value in
                        cell.current = value
                        
                        let sliderMaxValue = fixedAvailable.decimalNumber ?? 0
                        let valueDecimal = NSDecimalNumber(value: value).decimalValue
                        let rateValueNum = sliderMaxValue * valueDecimal
                        let rateValue = BigUInt(rateValueNum.floatValue)
                        
                        info.editedDelegate = rateValue
                        
                        let currentICXValue = rateValue.toString(decimal: 18, 4).currencySeparated()
                        cell.myVotesField.text = currentICXValue
                        
                        self.newList[indexPath.row - totalDelegationList.count] = info
                        
                        voteViewModel.newList.onNext(self.newList)
                        voteViewModel.isChanged.onNext(true)
                        
                    }).disposed(by: cell.disposeBag)
            }
            
            return cell
        }
        
    }
}

extension MyVoteViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollPoint = scrollView.contentOffset.y
    }
    
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
            return sectionHeader
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            selectedIndexPath = indexPath
            self.tableView.reloadData()
//            tableView.beginUpdates()
//            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
//            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section == 1 else { return 265 }
        if indexPath == selectedIndexPath {
            return 228
        } else {
            return 80
        }
    }

}
