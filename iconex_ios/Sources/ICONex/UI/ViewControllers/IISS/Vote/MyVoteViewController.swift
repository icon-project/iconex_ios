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
    
    
    @IBOutlet weak var footerBox: UIView!
    @IBOutlet weak var stepLimitTitleLabel: UILabel!
    @IBOutlet weak var estimatedFeeTitleLabel: UILabel!
    
    @IBOutlet weak var stepLimitLabel: UILabel!
    @IBOutlet weak var estimatedFeeLabel: UILabel!
    @IBOutlet weak var exchangedLabel: UILabel!
    
    
    private var myVoteList = [MyVoteEditInfo]()
    private var newList = [MyVoteEditInfo]()
    
    private var totalDelegation: TotalDelegation?
    
    private var refreshControl = UIRefreshControl()
    
    private var selectedIndexPath: IndexPath? = nil
    
    private var available: BigUInt = 0
    
    private var sectionHeader = UIView()
    
    private var scrollPoint: CGFloat = 0
    
    private var stepPrice: BigUInt = Manager.icon.stepPrice ?? 0
    
    private var estimatedStep: BigUInt = 0 {
        willSet {
            let separated = String(newValue).currencySeparated()
            let priceToICX = self.stepPrice.toString(decimal: 18, 9, false)
            
            let stepLimitString = separated + " / " + priceToICX
            stepLimitLabel.size14(text: stepLimitString, color: .gray77, align: .right)
            
            let calculated = newValue * self.stepPrice
            let calculatedPrice = Tool.calculatePrice(decimal: 18, currency: "icxusd", balance: calculated)
            
            stepLimitLabel.size14(text: stepLimitString, color: .gray179, align: .right)
            estimatedFeeLabel.size14(text: calculated.toString(decimal: 18, 9, false), color: .gray179, align: .right)
            exchangedLabel.size14(text: calculatedPrice, color: .gray179, align: .right)
            
            self.delegate.stepLimit = stepLimitLabel.text ?? ""
            self.delegate.maxFee = estimatedFeeLabel.text ?? ""
            self.delegate.estimatedStep = newValue
        }
    }
    
    private var isDecending: Bool = true
    
    private var prepInfo: NewPRepListResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        footerBox.layer.cornerRadius = 8
        footerBox.clipsToBounds = true
        footerBox.backgroundColor = .gray250
        footerBox.layer.borderColor = UIColor.gray230.cgColor
        footerBox.layer.borderWidth = 1
        
        stepLimitTitleLabel.size12(text: "Alert.Common.StepLimit".localized, color: .gray77, align: .right)
        estimatedFeeTitleLabel.size12(text: "Alert.Common.EstimatedFee".localized, color: .gray77, align: .right)
        
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
        
        sharedAvailable.subscribe(onNext: { (value) in
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
        resetButton.setTitleColor(.gray217, for: .disabled)
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
        
        
        orderButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.isDecending.toggle()
                
                if self.isDecending {
                    orderButton.setTitle("My Votes ↓", for: .normal)
                } else {
                    orderButton.setTitle("My Votes ↑", for: .normal)
                }
                
                self.tableView.reloadData()
                
        }.disposed(by: disposeBag)
        
        resetButton.rx.tap
            .subscribe { (_) in
                Alert.basic(title: "MyVoteView.Alert.Reset".localized, isOnlyOneButton: false, confirmAction: {
                    for (index, list) in self.myVoteList.enumerated() {
                        var item = list
                        item.editedDelegate = 0
                        item.percent = 0.0

                        self.myVoteList[index] = item
                    }

                    for (index, list) in self.newList.enumerated() {
                        var item = list
                        item.editedDelegate = 0
                        item.percent = 0.0

                        self.newList[index] = item
                    }

                    voteViewModel.myList.onNext(self.myVoteList)
                    voteViewModel.newList.onNext(self.newList)

                    voteViewModel.isChanged.onNext(true)

                    self.tableView.reloadData()

                }).show()
            }.disposed(by: disposeBag)
        
        Observable.merge(voteViewModel.myList, voteViewModel.newList)
            .skip(2)
            .subscribe(onNext: { (list) in
                
                print("ESTIMATE!!!!!")
                var delList = [[String: Any]]()
                
                for i in list {
                    let value: String = {
                        if let edit = i.editedDelegate {
                            return edit.toHexString()
                        } else if let myDelegate = i.myDelegate {
                            return myDelegate.toHexString()
                        } else {
                            return "0x0"
                        }
                    }()
                    
                    let info = ["address": i.address, "value": value]
                    delList.append(info)
                }
                
                DispatchQueue.global().async {
                    let delegationCall = Manager.icon.setDelegation(from: self.delegate.wallet, delegations: delList)
                    
                    DispatchQueue.main.async {
                        self.estimatedStep = delegationCall.stepLimit ?? 0
                    }
                }
                
            }).disposed(by: disposeBag)
        
        Observable.combineLatest(voteViewModel.myList, voteViewModel.newList)
            .flatMapLatest({ (myList, newList) -> Observable<Bool> in
                let myVoteChecker = self.myVoteList.filter({ $0.percent != 0.0 }).count > 0
                let newListChecker = self.newList.filter({ $0.percent != 0.0 }).count > 0
                
                return Observable.just(myVoteChecker || newListChecker)
                
            }).bind(to: resetButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        self.scrollView?.keyboardDismissMode = .onDrag
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
        
        guard let wallet = self.delegate.wallet else { return }
        // getPReps
        Manager.voteList.loadPrepListwithRank(from: wallet) { (prepList, _) in
            self.prepInfo = prepList
        }
        
        Manager.voteList.loadMyVotes(from: delegate.wallet) { tDelegation, myVotes in
            self.refreshControl.endRefreshing()
            self.totalDelegation = tDelegation
            self.myVoteList.removeAll()
            if let votes = myVotes {
                self.myVoteList.append(contentsOf: votes.sorted(by: { (lhs, rhs) -> Bool in
                    guard let left = lhs.myDelegate, let right = rhs.myDelegate else {
                        return lhs.prepName > rhs.prepName
                    }
                    
                    if self.isDecending {
                        return left > right
                    } else {
                        return left < right
                    }
                    
                }))
            }
            voteViewModel.available.onNext(tDelegation?.votingPower ?? 0)
            voteViewModel.myList.onNext(self.myVoteList)
            voteViewModel.originalList.onNext(self.myVoteList)
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
            let count = self.myVoteList.count + self.newList.count
            self.footerBox.isHidden = count == 0
            
            return count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // voted (VP)
        // available (VP)
        if indexPath.section == 0 {
            let info = self.totalDelegation!
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyVoteGeneralCell", for: indexPath) as! MyVoteGeneralCell
            
            print("info \(info)")
            cell.set(info: info)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyVoteDelegateCell", for: indexPath) as! MyVoteDelegateCell
            
            if selectedIndexPath == indexPath {
                cell.sliderBoxView.isHidden = false
                
                cell.myVotesTitleLabel.isHidden = true
                cell.myvotesValueLabel.isHidden = true
            } else {
                cell.sliderBoxView.isHidden = true
                
                cell.myVotesTitleLabel.isHidden = false
                cell.myvotesValueLabel.isHidden = false
            }
            
            
            let delegated = Manager.voteList.myVotes?.totalDelegated ?? 0
            let votingPower = Manager.voteList.myVotes?.votingPower ?? 0
            let stakedTotalValue = delegated + votingPower
            let stakedDecimal = stakedTotalValue.decimalNumber ?? 0
            
            let fixedAvailable = self.available
            
            if indexPath.row < myVoteList.count {
                var info = myVoteList[indexPath.row]
                
                let my: BigUInt = {
                    if let percent = info.percent {
                        let result = self.convertPercentToBigValue(percent: percent)
                        return result
                        
                    } else if let myDelegate = info.myDelegate {
                        let percent = self.calculatePercent(value: myDelegate)
                        info.percent = percent
                        
                        return myDelegate
                    } else {
                        return 0
                    }
                }()
                
                // myvotes
                let myPercent: Float = {
                    guard my > 0 else { return 0 }
                    guard let myDecimal = my.decimalNumber, let delegatedDecimal = delegated.decimalNumber else { return 0 }
                    let divided = (myDecimal / delegatedDecimal).floatValue * 100
                    return divided
                }()
                
                let myPercentString = "(" + String(format: "%.1f", myPercent) + "%)"
                cell.myvotesValueLabel.size12(text: "\(my.toString(decimal: 18, 4).currencySeparated()) \(myPercentString)", color: .gray77, weight: .bold, align: .right)
                
                let sliderMaxValue = fixedAvailable + my
                let sliderMaxDecimal = sliderMaxValue.decimalNumber ?? 0
                
                cell.prepName.size12(text: info.prepName, color: .gray77, weight: .semibold)
                
                let grade: String = {
                    switch info.grade {
                    case .main: return "P-Rep"
                    case .sub: return "Sub P-Rep"
                    case .candidate: return "Candidate"
                    }
                }()
                
                if let edited = info.editedDelegate, edited != info.myDelegate {
                    cell.prepInfo.size12(text: "(\(grade) / Voted / Edited)", color: .gray77, weight: .light)
                } else {
                    cell.prepInfo.size12(text: "(\(grade) / Voted)", color: .gray77, weight: .light)
                }
                guard let totalDelegated = self.prepInfo?.totalDelegated, let totalDelegatedDecimal = totalDelegated.decimalNumber, let prepTotalDecimal = info.totalDelegate.decimalNumber else { return cell }
                
                let calculatedFloat: Float = (prepTotalDecimal / totalDelegatedDecimal).floatValue * 100
                let totalVotesPercent = "(" + String(format: "%.1f", calculatedFloat) + "%)"
                
                cell.totalVotedValue.size12(text: info.totalDelegate.toString(decimal: 18, 4, false) + " \(totalVotesPercent)" , color: .gray77, weight: .bold)
                
                cell.addButton.isHighlighted = false
                cell.addButton.rx.tap.asControlEvent()
                    .subscribe { (_) in
                        guard cell.slider.value == 0 else { return self.tableView.showToolTip(positionY: cell.frame.origin.y-self.scrollPoint, text: "MyVoteView.ToolTip.Delete".localized) }
                        
                        Manager.voteList.remove(prep: info)
                        self.myVoteList.remove(at: indexPath.row)
                        voteViewModel.myList.onNext(self.myVoteList)
                        tableView.reloadData()
                        
                    }.disposed(by: cell.disposeBag)
                
                
                let child = sliderMaxValue.decimalNumber ?? 0.0
                let parentDecimal = stakedTotalValue.decimalNumber ?? 0.0
                let percent = (child / parentDecimal) * 100
                let percentFloat = percent.floatValue
                cell.myVoteMaxValue = String(format: "%.0f", percentFloat) + " %"
                
                let myDelegateDecimal = my.decimalNumber ?? 0.0
                let sliderDecimal = sliderMaxValue.decimalNumber ?? 0.0
                
                let calculated: Decimal =  {
                    if sliderDecimal > 0 {
                        return myDelegateDecimal / sliderDecimal
                    } else {
                        return 0
                    }
                }()
                
                let sliderPercent = calculated.floatValue * 100
                cell.current = sliderPercent
                cell.slider.value = sliderPercent
                
                let currentICXValue = my.toString(decimal: 18, 4).currencySeparated()
                cell.myVotesField.text = currentICXValue
                
                cell.myVotesUnitLabel.text = "(" + String(format: "%.1f", calculated.floatValue * 100) + "%)"
                
                if sliderMaxValue == 0 {
                    cell.slider.isEnabled = false
                    cell.myVotesField.isEnabled = false
                } else {
                    cell.slider.isEnabled = true
                    cell.myVotesField.isEnabled = true
                }
                
                cell.slider.rx.value.skip(1).distinctUntilChanged()
                    .subscribe(onNext: { value in
                        let realValue = roundf(value)
                        
                        cell.current = realValue
                        
                        var this = self.myVoteList[indexPath.row]
                        let valueDecimal = NSDecimalNumber(value: realValue).decimalValue
                        let rateValueNum = sliderMaxDecimal * valueDecimal
                        let rateValue = BigUInt(rateValueNum.floatValue / 100.0 )
                        
                        // percent
                        let percent = rateValueNum / stakedDecimal
                        
                        this.editedDelegate = rateValue
                        this.percent = percent.floatValue
                        
                        cell.slider.value = valueDecimal.floatValue
                        
                        let currentICXValue = rateValue.toString(decimal: 18, 4).currencySeparated()
                        cell.myVotesField.text = currentICXValue
                        
                        cell.myVotesUnitLabel.text = "(" + String(format: "%.1f", valueDecimal.floatValue) + "%)"
                        
                        self.myVoteList[indexPath.row] = this
                        
                        voteViewModel.myList.onNext(self.myVoteList)
                        voteViewModel.isChanged.onNext(true)
                        
                    }).disposed(by: cell.disposeBag)
                
                // textfield
                cell.myVotesField.rx.text.orEmpty.skip(1).subscribe(onNext: { (value) in
                    guard let bigValue = Tool.stringToBigUInt(inputText: value) else { return }
                    
                    var this = self.myVoteList[indexPath.row]
                    
                    guard bigValue <= sliderMaxValue else {
                        bzz()
                        
                        cell.myVotesField.text = sliderMaxValue.toString(decimal: 18, 4).currencySeparated()
                        cell.current = 100.0
                        cell.slider.value = 100.0
                        cell.myVotesUnitLabel.text = "(100.0%)"
                        
                        // update
                        this.editedDelegate = sliderMaxValue
                        
                        let maxDecimal = sliderMaxValue.decimalNumber?.floatValue ?? 0
                        
                        let percent = maxDecimal / stakedDecimal.floatValue * 100
                        this.percent = percent
                        
                        self.myVoteList[indexPath.row] = this
                        voteViewModel.myList.onNext(self.myVoteList)
                        voteViewModel.isChanged.onNext(true)
                        return
                    }
                    
                    guard let bigValueDecimal = bigValue.decimalNumber, let maxValueDecimal = sliderMaxValue.decimalNumber else { return }
                    
                    let valuePercent: Float = {
                        if bigValueDecimal > 0 {
                            return (bigValueDecimal / maxValueDecimal).floatValue * 100
                        } else {
                            return 0
                        }
                    }()
                    
                    cell.myVotesUnitLabel.text = "(" + String(format: "%.1f", valuePercent) + " %)"
                    
                    cell.current = valuePercent
                    cell.slider.value = valuePercent
                    
                    this.editedDelegate = bigValue
                    
                    let percentValue = (bigValueDecimal / stakedDecimal).floatValue
                    this.percent = percentValue
                    
                    self.myVoteList[indexPath.row] = this
                    voteViewModel.myList.onNext(self.myVoteList)
                    voteViewModel.isChanged.onNext(true)
                    
                }).disposed(by: disposeBag)
                
            } else {
                let info = self.newList[indexPath.row - myVoteList.count]
                cell.prepName.size12(text: info.prepName, color: .gray77, weight: .semibold)
                
                let grade: String = {
                    switch info.grade {
                    case .main: return "P-Rep"
                    case .sub: return "Sub P-Rep"
                    case .candidate: return "Candidate"
                    }
                }()
                
                cell.prepInfo.size12(text: "(\(grade))", color: .gray77, weight: .light)
                
                cell.addButton.isHighlighted = true
                cell.addButton.rx.tap
                    .subscribe(onNext: {
                        self.newList.remove(at: indexPath.row - self.myVoteList.count)
                        Manager.voteList.remove(prep: info)
                        voteViewModel.newList.onNext(self.newList)
                        voteViewModel.isChanged.onNext(true)
                        tableView.reloadData()
                    }).disposed(by: cell.disposeBag)
                
                let delegate = self.convertPercentToBigValue(percent: info.percent ?? 0.0)
                let sliderMaxValue = fixedAvailable + delegate
                let sliderMaxDecimal = sliderMaxValue.decimalNumber ?? 0
                
                let sliderMaxPercent = (sliderMaxDecimal / stakedDecimal) * 100
                let percentFloat = sliderMaxPercent.floatValue
                
                
                guard let totalDelegated = self.prepInfo?.totalDelegated, let totalDelegatedDecimal = totalDelegated.decimalNumber, let prepTotalDecimal = info.totalDelegate.decimalNumber else { return cell }
                
                let calculatedFloat: Float = (prepTotalDecimal / totalDelegatedDecimal).floatValue * 100
                let totalVotesPercent = "(" + String(format: "%.1f", calculatedFloat) + "%)"
                
                cell.totalVotedValue.size12(text: info.totalDelegate.toString(decimal: 18, 4, false) + " \(totalVotesPercent)" , color: .gray77, weight: .bold)
                
                cell.myVoteMaxValue = String(format: "%.0f", percentFloat) + " %"
                
                let myPercent = info.percent ?? 0
                
                let myValue = self.convertPercentToBigValue(percent: myPercent).toString(decimal: 18, 4).currencySeparated()
                let myPercentString = "(" + String(format: "%.1f", myPercent) + "%)"
                
                cell.myvotesValueLabel.size12(text: "\(myValue) \(myPercentString)", color: .gray77, weight: .bold, align: .right)
                
                if let valuePercent = info.percent {
                    let sliderValue = self.convertPercentToBigValue(percent: valuePercent)
                    let sliderDecimal = sliderValue.decimalNumber ?? 0
                    
                    let calculatedFloat: Float = {
                        if sliderMaxDecimal > 0 {
                            return (sliderDecimal / sliderMaxDecimal).floatValue * 100
                        } else {
                            return 0
                        }
                    }()
                    
                    cell.slider.value = calculatedFloat
                    cell.current = calculatedFloat
                    
                    let stringValue = sliderValue.toString(decimal: 18, 4).currencySeparated()
                    cell.myVotesField.text = stringValue
                    
                    cell.myVotesUnitLabel.text = "(" + String(format: "%.1f", calculatedFloat * 100) + "%)"
                    
                } else {
                    cell.current = 0.0
                    cell.slider.value = 0.0
                    cell.myVotesUnitLabel.text = "0.0%"
                    
                    cell.slider.sendActions(for: .valueChanged)
                }
                
                if sliderMaxValue == 0 {
                    cell.slider.isEnabled = false
                    cell.myVotesField.isEnabled = false
                } else {
                    cell.slider.isEnabled = true
                    cell.myVotesField.isEnabled = true
                }
                
                cell.slider.rx.value.skip(1).distinctUntilChanged()
                    .subscribe(onNext: { value in
                        var this = self.newList[indexPath.row - self.myVoteList.count]
                        
                        let realValue = roundf(value)
                        cell.current = realValue

                        let valueDecimal = NSDecimalNumber(value: realValue).decimalValue
                        let rateValueNum = sliderMaxDecimal * valueDecimal
                        let rateValue = BigUInt(rateValueNum.floatValue / 100.0)


                        let currentICXValue = rateValue.toString(decimal: 18, 4).currencySeparated()

                        cell.myVotesField.text = currentICXValue
                        
                        this.editedDelegate = rateValue
                        
                        let nowPercent = (rateValueNum / stakedDecimal).floatValue
                        this.percent = nowPercent
                        
                        cell.slider.value = valueDecimal.floatValue

                        cell.myVotesUnitLabel.text = "(" + String(format: "%.1f", valueDecimal.floatValue) + "%)"

                        self.newList[indexPath.row - self.myVoteList.count] = this

                        voteViewModel.newList.onNext(self.newList)
                        voteViewModel.isChanged.onNext(true)

                    }).disposed(by: cell.disposeBag)
                
                
                cell.myVotesField.rx.text.orEmpty.subscribe(onNext: { (value) in
                    guard let bigValue = Tool.stringToBigUInt(inputText: value) else { return }

                    var this = self.newList[indexPath.row - self.myVoteList.count]

                    guard bigValue <= sliderMaxValue else {
                        bzz()
                        cell.myVotesField.text = sliderMaxValue.toString(decimal: 18, 4).currencySeparated()
                        cell.current = 100.0
                        cell.slider.value = 100.0
                        cell.myVotesUnitLabel.text = "(100.0%)"

                        this.editedDelegate = sliderMaxValue
                        this.percent = 100.0
                        self.newList[indexPath.row - self.myVoteList.count] = this
                        voteViewModel.newList.onNext(self.newList)
                        voteViewModel.isChanged.onNext(true)
                        return
                    }

                    guard let bigValueDecimal = bigValue.decimalNumber, let maxValueDecimal = sliderMaxValue.decimalNumber else { return }
//                    let sliderPercent = bigValueDecimal / maxValueDecimal * 100
                    
                    let sliderPercent: Decimal = {
                        if bigValueDecimal > 0 {
                            return bigValueDecimal / maxValueDecimal * 100
                        } else {
                            return 0
                        }
                    }()
                    
                    let availablePercent = (bigValueDecimal / stakedDecimal).floatValue * 100
                    
                    let percentFloat = sliderPercent.floatValue
                    
                    cell.myVotesUnitLabel.text = "(" + String(format: "%.1f", percentFloat) + "%)"

                    cell.current = sliderPercent.floatValue
                    cell.slider.value = sliderPercent.floatValue

                    this.editedDelegate = bigValue
                    this.percent = availablePercent
                    
                    self.newList[indexPath.row - self.myVoteList.count] = this
                    voteViewModel.newList.onNext(self.newList)
                    voteViewModel.isChanged.onNext(true)
                }).disposed(by: disposeBag)
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
            guard selectedIndexPath != indexPath else { return }
            selectedIndexPath = indexPath
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section == 1 else { return 265 }
        if indexPath == selectedIndexPath {
            return 250
        } else {
            return 102
        }
    }

}

extension MyVoteViewController {
    func calculatePercent(value: BigUInt) -> Float {
        guard let delegated = self.totalDelegation?.totalDelegated, let available = self.totalDelegation?.votingPower else { return 0.0 }
        
        let staked = delegated + available
        guard let stakedDecimal = staked.decimalNumber, let valueDecimal = value.decimalNumber else { return 0.0 }
        
        let percent = valueDecimal / stakedDecimal
        let result = percent.floatValue
        
        return result
    }
    
    func convertPercentToBigValue(percent: Float) -> BigUInt {
        guard percent > 0 else { return 0 }
        guard let delegated = self.totalDelegation?.totalDelegated, let available = self.totalDelegation?.votingPower else { return 0 }
        
        // total
        let staked = delegated + available
        guard let stakedFloat = staked.decimalNumber?.floatValue else { return 0 }
        
        let value = stakedFloat * percent / 100
        let bigValue = BigUInt(value)
        
        return bigValue
    }
}
