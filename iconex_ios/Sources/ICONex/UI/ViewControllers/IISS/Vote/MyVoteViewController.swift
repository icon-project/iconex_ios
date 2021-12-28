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
    unowned var delegate: VoteMainDelegate!
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
    
    private var refreshControl: UIRefreshControl?
    
    private var selectedIndexPath: IndexPath?
    
    private var sectionHeader = UIView()
    
    @IBOutlet weak var tableFooterView: UIView!
    
    private var stepPrice: BigUInt = Manager.icon.stepPrice ?? 0
    
    private var estimatedStep: BigUInt = 0 {
        willSet {
            let separated = String(newValue).currencySeparated()
            let priceToICX = self.stepPrice.toString(decimal: 18, 18, true)
            
            let stepLimitString = separated + " / " + priceToICX
            stepLimitLabel.text = stepLimitString
            
            let calculated = newValue * self.stepPrice
            let calculatedPrice = Tool.calculatePrice(decimal: 18, currency: "icxusd", balance: calculated)
            estimatedFeeLabel.size14(text: calculated.toString(decimal: 18, 18, true), color: .gray77, align: .right)
            exchangedLabel.size12(text: calculatedPrice, color: .gray179, align: .right)
            
            self.delegate.stepLimit = stepLimitLabel.text ?? ""
            self.delegate.maxFee = estimatedFeeLabel.text ?? ""
            self.delegate.estimatedStep = newValue
        }
    }
    
    private var isDecending: Bool = true
    
    private var prepInfo: NewPRepListResponse?
    
    private var available: BehaviorSubject<BigUInt> = BehaviorSubject<BigUInt>(value: BigUInt.zero)
    private var isChanged: PublishSubject<Bool> = PublishSubject<Bool>()
    
    private var isFirstLoad: Bool = true
    
    private var stack: UIStackView?
    
    private var tooltip: IndexPath? {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        selectedIndexPath = IndexPath(row: 0, section: 1)
        
        let messageTitle = UILabel(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 40))
        messageTitle.numberOfLines = 0
        messageTitle.size14(text: "MyVoteView.Empty.Title".localized, color: .mint1, align: .center, lineBreakMode: .byWordWrapping)
        messageTitle.numberOfLines = 0
         
        let messageSubtitle = UILabel(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 40))
        messageSubtitle.size12(text: "MyVoteView.Empty.Desc".localized, color: .gray128, weight: .light, align: .center, lineBreakMode: .byWordWrapping)
        messageSubtitle.numberOfLines = 0
        
        
        stack = UIStackView(arrangedSubviews: [messageTitle, messageSubtitle])
        stack?.axis = .vertical
        
        stack?.translatesAutoresizingMaskIntoConstraints = false
        
        if let stackView = self.stack {
            stackView.isHidden = true
            self.tableFooterView.addSubview(stackView)
            stackView.topAnchor.constraint(equalTo: self.tableFooterView.topAnchor, constant: 10).isActive = true
            stackView.leadingAnchor.constraint(equalTo: self.tableFooterView.leadingAnchor, constant: 20).isActive = true
            stackView.trailingAnchor.constraint(equalTo: self.tableFooterView.trailingAnchor, constant: -20).isActive = true
            stackView.bottomAnchor.constraint(equalTo: self.tableFooterView.bottomAnchor, constant: -40).isActive = true
        }
        
        footerBox.layer.cornerRadius = 8
        footerBox.clipsToBounds = true
        footerBox.backgroundColor = .gray250
        footerBox.layer.borderColor = UIColor.gray230.cgColor
        footerBox.layer.borderWidth = 1
        
        stepLimitTitleLabel.size12(text: "Alert.Common.StepLimit".localized, color: .gray128, weight: .light, align: .right)
        estimatedFeeTitleLabel.size12(text: "Alert.Common.EstimatedFee".localized, color: .gray128, weight: .light,align: .right)
        
        stepLimitLabel.size14(text: "-", color: .gray77, align: .right)
        estimatedFeeLabel.size14(text: "-", color: .gray77, align: .right)
        exchangedLabel.size12(text: "-", color: .gray179, align: .right)
        
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
                self?.tooltip = nil
            }).disposed(by: disposeBag)
        
        let refresh = UIRefreshControl()
        tableView.refreshControl = refresh
        self.refreshControl = refresh
        refresh.beginRefreshing()
        
        self.delegate.voteViewModel.currentAddedList.subscribe(onNext: { [unowned self] addedList in
            guard !addedList.isEmpty else {
                self.delegate.voteViewModel.newList.onNext(addedList)
                if self.myVoteList.count == 0 {
                    self.footerBox.isHidden = true
                    self.stack?.isHidden = false
                    self.tableView.separatorStyle = .none
                }
                self.tableView.reloadData()
                return
            }
            for i in addedList {
                let checker = self.newList.contains(where: { (new) -> Bool in
                    return new.address == i.address
                })
                
                if !checker {
                    self.newList.append(i)
                }
            }
            
            self.delegate.voteViewModel.newList.onNext(self.newList)
            
            let count = self.myVoteList.count + self.newList.count
            self.footerBox.isHidden = count == 0
            
            if count == 0 {
                self.stack?.isHidden = false
                self.tableView.separatorStyle = .none
                
            } else {
                self.stack?.isHidden = true
                self.tableView.separatorStyle = .singleLine
            }
            
            self.tableView.reloadData()
        }).disposed(by: disposeBag)
        
        self.isChanged.subscribe { (_) in
            let votedListPower: BigUInt = self.myVoteList.map {
                if $0.editedDelegate == nil {
                    return $0.myDelegate ?? 0
                } else {
                    return $0.editedDelegate ?? 0
                }
            }.reduce(0, +)
            
            let votingListPower: BigUInt = self.newList.map {
                if $0.editedDelegate == nil {
                    return $0.myDelegate ?? 0
                } else {
                    return $0.editedDelegate ?? 0
                }
            }.reduce(0, +)
            
            let power = Manager.voteList.myVotes?.votingPower ?? 0
            let delegated = Manager.voteList.myVotes?.totalDelegated ?? 0
            let total = power + delegated
            let plus = votedListPower + votingListPower
            
            guard plus <= total else { return self.available.onNext(0) }
            
            let result = total - plus
            self.available.onNext(result)
        }.disposed(by: disposeBag)
        
        // section header
        sectionHeader = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 36))
        sectionHeader.backgroundColor = .gray250
        let orderButton = UIButton(type: .custom)
//        orderButton.setTitle("My Votes ↓", for: .normal)
        orderButton.setTitle("My Votes", for: .normal)
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
        
        
//        orderButton.rx.tap.asControlEvent()
//            .subscribe { (_) in
//                self.isDecending.toggle()
//
//                if self.isDecending {
//                    orderButton.setTitle("My Votes ↓", for: .normal)
//                } else {
//                    orderButton.setTitle("My Votes ↑", for: .normal)
//                }
//
//                self.tableView.reloadData()
//
//        }.disposed(by: disposeBag)
        
        resetButton.rx.tap
            .subscribe { [unowned self] (_) in
                Alert.basic(title: "MyVoteView.Alert.Reset".localized, isOnlyOneButton: false, leftButtonTitle: "Common.No".localized, rightButtonTitle: "Common.Yes".localized, confirmAction: {
                    self.tooltip = nil
                    
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

                    self.delegate.voteViewModel.myList.onNext(self.myVoteList)
                    self.delegate.voteViewModel.newList.onNext(self.newList)

                    self.isChanged.onNext(true)

                    self.tableView.reloadData()

                }).show()
            }.disposed(by: disposeBag)
        
        let voteObservable = Observable.combineLatest(delegate.voteViewModel.myList, delegate.voteViewModel.newList).share(replay: 1)
        
        voteObservable.flatMapLatest({ [unowned self] (myList, newList) -> Observable<Bool> in
            let myVoteChecker = self.myVoteList.filter({ $0.percent != 0.0 }).count > 0
            
            let newVoteChecker = self.newList.filter { (newList) -> Bool in
                let edited = newList.editedDelegate ?? BigUInt.zero
                return edited > BigUInt.zero
            }.count > 0
            
            return Observable.just(myVoteChecker || newVoteChecker)
            
        }).bind(to: resetButton.rx.isEnabled)
        .disposed(by: disposeBag)
        
        voteObservable.skip(1).subscribe(onNext: { (myList, newList) in
            print("ESTIMATE!!!!!")
            
            let list = myList + newList
            
            var delList = [[String: Any]]()
            
            for i in list {
                let value: String = {
                    if let edit = i.editedDelegate {
                        return edit.toHexString()
                    } else if let myDelegate = i.myDelegate {
                        return myDelegate.toHexString()
                    } else {
                        let zero = BigUInt(0).toHexString()
                        return zero
                    }
                }()
                
                let info = ["address": i.address, "value": value]
                
                delList.append(info)
            }
            
            guard let wallet = self.delegate.wallet else { return }
            DispatchQueue.global().async {
                let delegationCall = Manager.icon.setDelegation(from: wallet, delegations: delList)
                
                DispatchQueue.main.async {
                    self.estimatedStep = delegationCall.stepLimit ?? 0
                }
            }
        }).disposed(by: disposeBag)
        
        self.scrollView?.keyboardDismissMode = .onDrag
    }
    
    override func refresh() {
        super.refresh()
        loadData()
    }
}

extension MyVoteViewController {
    @objc func loadData() {
        guard let wallet = self.delegate.wallet else { return }
        // getPReps
        Manager.voteList.loadPrepListwithRank(from: wallet) { [unowned self] (prepList, _) in
            if prepList == nil {
                Toast.toast(message: "Error.CommonError".localized)
            }
            self.prepInfo = prepList
        }
        
        Manager.voteList.loadMyVotes(from: delegate.wallet) { [unowned self] tDelegation, myVotes in
            if let refresh = self.refreshControl {
                refresh.endRefreshing()
                self.tableView.refreshControl = nil
                self.refreshControl = nil
            }
            
            
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
            } else {
                Toast.toast(message: "Error.CommonError".localized)
            }
            
            if self.isFirstLoad {
                self.available.onNext(tDelegation?.votingPower ?? 0)
                self.delegate.voteViewModel.myList.onNext(self.myVoteList)
                
                self.footerBox.isHidden = self.myVoteList.count == 0
                self.stack?.isHidden = self.myVoteList.count != 0
            }
            self.isFirstLoad = false
            
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
            return totalDelegation == nil ? 0 : 1
            
        } else {
            let count = self.myVoteList.count + self.newList.count
            
            return count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // voted (VP)
        // available (VP)
        if indexPath.section == 0 {
            let info = self.totalDelegation!
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyVoteGeneralCell", for: indexPath) as! MyVoteGeneralCell
            cell.layoutIfNeeded()
            
            let votingPower = info.votingPower
            let total = info.totalDelegated + votingPower
            let totalDecimal = total.decimalNumber ?? 0
            
            self.available.subscribe(onNext: { [unowned cell] (availablePower) in
                let powerDecimal = availablePower.decimalNumber ?? 0
                let rate = powerDecimal / totalDecimal

                cell.votedWidth.constant = cell.slideView.frame.width * CGFloat(1.0 - rate.floatValue)

                let percent = rate * 100
                cell.votedLabel.size14(text: "Voted " + String(format: "%.1f", 100.0 - percent.floatValue) + "%", color: .mint1, weight: .light)
                cell.availableLabel.size14(text: "Available " + String(format: "%.1f", percent.floatValue) + "%", color: .gray77, weight: .light)

                let delegated = total - availablePower
                cell.votedValueLabel.size14(text: delegated.toString(decimal: 18, 4, false), color: .gray77, weight: .regular, align: .right)
                cell.availableValueLabel.size14(text: availablePower.toString(decimal: 18, 4, false), color: .gray77, weight: .regular, align: .right)

            }).disposed(by: cell.cellBag)
            
            delegate.voteViewModel.voteCount.subscribe(onNext: { [unowned cell] (count) in
                cell.voteHeader.size16(text: "Vote (\(count)/10)", color: .gray77, weight: .medium, align: .left)
            }).disposed(by: cell.cellBag)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyVoteDelegateCell", for: indexPath) as! MyVoteDelegateCell
            
            if selectedIndexPath == indexPath {
                cell.sliderBoxView.layoutIfNeeded()
                cell.sliderBoxView.isHidden = false
                
                cell.myVotesTitleLabel.isHidden = true
                cell.myvotesValueLabel.isHidden = true
            } else {
                cell.sliderBoxView.isHidden = true
                
                cell.myVotesTitleLabel.isHidden = false
                cell.myvotesValueLabel.isHidden = false
            }
            
            if let tip = self.tooltip {
                cell.tooltipContainer.isHidden = indexPath != tip
            } else {
                cell.tooltipContainer.isHidden = true
            }
            
            let delegated = Manager.voteList.myVotes?.totalDelegated ?? 0
            let votingPower = Manager.voteList.myVotes?.votingPower ?? 0
            let stakedTotalValue = delegated + votingPower
            let stakedDecimal = stakedTotalValue.decimalNumber ?? 0
            
            let fixedAvailable: BigUInt = {
                do {
                    return try self.available.value()
                } catch {
                    return BigUInt.zero
                }
            }()
            
            if indexPath.row < myVoteList.count {
                var info = myVoteList[indexPath.row]
                
                // add rank
                let rank: Int = self.prepInfo?.preps.first(where: { (prep) -> Bool in
                    return prep.address == info.address
                })?.rank ?? 0
                
                cell.rank.size12(text: "\(rank).", color: .gray77, weight: .semibold)
                
                let my: BigUInt = {
                    if let edit = info.editedDelegate {
                        return edit
                        
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
                    guard let myDecimal = my.decimalNumber else { return 0 }
                    let divided = (myDecimal / stakedDecimal).floatValue * 100
                    return divided
                }()
                
                let myPercentString = "(" + String(format: "%.1f", myPercent) + "%)"
                cell.myvotesValueLabel.text = "\(my.toString(decimal: 18, 4).currencySeparated()) \(myPercentString)"
                let sliderMaxValue = fixedAvailable + my
                let sliderMaxDecimal = sliderMaxValue.decimalNumber ?? 0
                
                cell.prepName.size12(text: info.prepName, color: .gray77, weight: .semibold)
                
                let grade: String = {
                    switch info.grade {
                    case .main: return "Main P-Rep"
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
                
                cell.totalVotedValue.text = info.totalDelegate.toString(decimal: 18, 4, false) + " \(totalVotesPercent)"
                
                cell.addButton.isSelected = false
                cell.addButton.rx.tap
                    .subscribe { [unowned self] _ in
                        Log("\(indexPath)")
                        self.tooltip = indexPath
                    }.disposed(by: cell.disposeBag)
                cell.voteTooltipButton.rx.tap
                    .subscribe { [unowned self] _ in
                        self.tooltip = nil
                }.disposed(by: disposeBag)
                
                let child = sliderMaxValue.decimalNumber ?? 0.0
                let parentDecimal = stakedTotalValue.decimalNumber ?? 0.0
                let percent = (child / parentDecimal) * 100
                let percentFloat = percent.floatValue
                cell.myVoteMaxValue = String(format: "%.0f", percentFloat) + "%"
                
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
                    .subscribe(onNext: { [unowned self] value in
                        let realValue = roundf(value)
                        
                        cell.current = realValue
                        
                        var updated = self.myVoteList[indexPath.row]
                        let valueDecimal = NSDecimalNumber(value: realValue).decimalValue
                        
                        let rateValueNum = sliderMaxDecimal * valueDecimal
                        let rateValue: BigUInt = {
                            if realValue == 100.0 {
                                return sliderMaxValue
                            } else {
                                return BigUInt(rateValueNum.floatValue / 100.0 )
                            }
                        }()
                        
                        // percent
                        let percent = rateValueNum / stakedDecimal
                        
                        updated.editedDelegate = rateValue
                        updated.percent = percent.floatValue
                        
                        cell.slider.value = valueDecimal.floatValue
                        
                        let currentICXValue = rateValue.toString(decimal: 18, 4).currencySeparated()
                        cell.myVotesField.text = currentICXValue
                        
                        cell.myVotesUnitLabel.text = "(" + String(format: "%.1f", valueDecimal.floatValue) + "%)"
                        
                        // edit label
                        if let edited = updated.editedDelegate, edited != updated.myDelegate {
                            cell.prepInfo.size12(text: "(\(grade) / Voted / Edited)", color: .gray77, weight: .light)
                        } else {
                            cell.prepInfo.size12(text: "(\(grade) / Voted)", color: .gray77, weight: .light)
                        }
                        
                        self.myVoteList[indexPath.row] = updated
                        self.isChanged.onNext(true)
                        
                    }).disposed(by: cell.disposeBag)
                
                cell.slider.rx.controlEvent([.touchUpInside, .touchUpOutside]).subscribe { [unowned self] (_) in
                    self.delegate.voteViewModel.myList.onNext(self.myVoteList)
                }.disposed(by: cell.disposeBag)
                
                // textfield
                cell.myVotesField.rx.text.orEmpty.skip(1).subscribe(onNext: { [unowned self] (value) in
                    guard let bigValue = Tool.stringToBigUInt(inputText: value, fixed: true) else { return }
                    
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
                        
                        let percent = (maxDecimal / stakedDecimal.floatValue) * 100
                        this.percent = percent
                        
                        self.myVoteList[indexPath.row] = this
                        self.delegate.voteViewModel.myList.onNext(self.myVoteList)
                        self.isChanged.onNext(true)
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
                    
                    cell.myVotesUnitLabel.text = "(" + String(format: "%.1f", valuePercent) + "%)"
                    
                    cell.current = valuePercent
                    cell.slider.value = valuePercent
                    
                    this.editedDelegate = bigValue
                    
                    let percentValue = (bigValueDecimal / stakedDecimal).floatValue * 100
                    this.percent = percentValue
                    
                    self.myVoteList[indexPath.row] = this
                    self.isChanged.onNext(true)
                    
                }).disposed(by: cell.disposeBag)
                
                cell.myVotesField.rx.controlEvent(.editingDidEnd).subscribe { [unowned self] (_) in
                    self.delegate.voteViewModel.myList.onNext(self.myVoteList)
                }.disposed(by: cell.disposeBag)
                
            } else {
                let info = self.newList[indexPath.row - myVoteList.count]
                cell.prepName.size12(text: info.prepName, color: .gray77, weight: .semibold)
                
                // add rank
                let rank: Int = self.prepInfo?.preps.first(where: { (prep) -> Bool in
                    return prep.address == info.address
                })?.rank ?? 0
                
                cell.rank.size12(text: "\(rank).", color: .gray77, weight: .semibold)
                
                let grade: String = {
                    switch info.grade {
                    case .main: return "Main P-Rep"
                    case .sub: return "Sub P-Rep"
                    case .candidate: return "Candidate"
                    }
                }()
                
                cell.prepInfo.size12(text: "(\(grade))", color: .gray77, weight: .light)
                
                cell.addButton.isSelected = true
                cell.addButton.rx.tap
                    .subscribe(onNext: { [unowned self] in
                        self.newList.remove(at: indexPath.row - self.myVoteList.count)
                        
                        if let selectedRow = self.selectedIndexPath?.row {
                            if selectedRow == indexPath.row {
                                self.selectedIndexPath = nil
                            } else if selectedRow > indexPath.row {
                                self.selectedIndexPath?.row -= 1
                            }
                        }
                        
                        Manager.voteList.remove(prep: info)
                        self.delegate.voteViewModel.currentAddedList.onNext(self.newList)
                        self.isChanged.onNext(true)
                        
                    }).disposed(by: cell.disposeBag)
                
                let delegate = info.editedDelegate ?? 0
                let sliderMaxValue = fixedAvailable + delegate
                let sliderMaxDecimal = sliderMaxValue.decimalNumber ?? 0
                
                let sliderMaxPercent: Decimal = {
                    if sliderMaxDecimal > 0 {
                        return (sliderMaxDecimal / stakedDecimal) * 100
                    } else {
                        return 0.0
                    }
                }()
                
                let percentFloat = sliderMaxPercent.floatValue
                
                
                guard let totalDelegated = self.prepInfo?.totalDelegated, let totalDelegatedDecimal = totalDelegated.decimalNumber, let prepTotalDecimal = info.totalDelegate.decimalNumber else { return cell }
                
                let calculatedFloat: Float = (prepTotalDecimal / totalDelegatedDecimal).floatValue * 100
                let totalVotesPercent = "(" + String(format: "%.1f", calculatedFloat) + "%)"
                
                cell.totalVotedValue.text = info.totalDelegate.toString(decimal: 18, 4, false) + " \(totalVotesPercent)"
                cell.myVoteMaxValue = String(format: "%.0f", percentFloat) + "%"
                
                let my: BigUInt = info.editedDelegate ?? 0
                
                // myvotes
                let myPercent: Float = {
                    guard let myDecimal = my.decimalNumber else { return 0 }
                    let divided = (myDecimal / stakedDecimal).floatValue * 100
                    return divided
                }()
                
                let myPercentString = "(" + String(format: "%.1f", myPercent) + "%)"
                cell.myvotesValueLabel.text = "\(my.toString(decimal: 18, 4).currencySeparated()) \(myPercentString)"

                if let edited = info.editedDelegate {
                    let editedDecimal = edited.decimalNumber ?? 0.0
                    let calculatedFloat: Float = {
                        if editedDecimal > 0 {
                            return (editedDecimal / sliderMaxDecimal).floatValue * 100
                        } else {
                            return 0
                        }
                    }()
                    
                    if edited > BigUInt(0) {
                        cell.prepInfo.size12(text: "(\(grade) / Edited)", color: .gray77, weight: .light)
                    } else {
                        cell.prepInfo.size12(text: "(\(grade))", color: .gray77, weight: .light)
                    }
                    
                    cell.slider.value = calculatedFloat
                    cell.current = calculatedFloat
                    
                    let stringValue = edited.toString(decimal: 18, 4).currencySeparated()
                    cell.myVotesField.text = stringValue
                    
                    cell.myVotesUnitLabel.text = "(" + String(format: "%.1f", calculatedFloat) + "%)"
                    
                } else {
                    cell.prepInfo.size12(text: "(\(grade))", color: .gray77, weight: .light)
                    cell.current = 0.0
                    cell.slider.value = 0.0
                    cell.myVotesUnitLabel.text = "0.0%"
                    cell.myVotesField.text = "0.0000"
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
                    .subscribe(onNext: { [unowned self] value in
                        var this = self.newList[indexPath.row - self.myVoteList.count]
                        
                        let realValue = roundf(value)
                        cell.current = realValue
                        
                        if realValue > 0 {
                            cell.prepInfo.size12(text: "(\(grade) / Edited)", color: .gray77, weight: .light)
                        } else {
                            cell.prepInfo.size12(text: "(\(grade))", color: .gray77, weight: .light)
                        }

                        let valueDecimal = NSDecimalNumber(value: realValue).decimalValue
                        let rateValueNum = sliderMaxDecimal * valueDecimal
                        let rateValue = BigUInt(rateValueNum.floatValue / 100.0)


                        let currentICXValue = rateValue.toString(decimal: 18, 4).currencySeparated()

                        cell.myVotesField.text = currentICXValue
                        
                        if realValue == 100.0 {
                            this.editedDelegate = sliderMaxValue
                        } else {
                            this.editedDelegate = rateValue
                        }
                        
                        let nowPercent = (rateValueNum / stakedDecimal).floatValue
                        this.percent = nowPercent
                        
                        cell.slider.value = valueDecimal.floatValue

                        cell.myVotesUnitLabel.text = "(" + String(format: "%.1f", valueDecimal.floatValue) + "%)"

                        self.newList[indexPath.row - self.myVoteList.count] = this
                        self.isChanged.onNext(true)
                    }).disposed(by: cell.disposeBag)
                
                cell.slider.rx.controlEvent([.touchUpInside, .touchUpOutside]).subscribe { [unowned self] (_) in
                    self.delegate.voteViewModel.newList.onNext(self.newList)
                }.disposed(by: cell.disposeBag)
                
                cell.myVotesField.rx.text.orEmpty.skip(1).subscribe(onNext: { [unowned self] (value) in
                    guard let bigValue = Tool.stringToBigUInt(inputText: value, fixed: true) else { return }

                    var this = self.newList[indexPath.row - self.myVoteList.count]
                    
                    if bigValue > BigUInt.zero {
                        cell.prepInfo.size12(text: "(\(grade) / Edited)", color: .gray77, weight: .light)
                    } else {
                        cell.prepInfo.size12(text: "(\(grade))", color: .gray77, weight: .light)
                    }

                    guard bigValue <= sliderMaxValue else {
                        bzz()
                        cell.myVotesField.text = sliderMaxValue.toString(decimal: 18, 4).currencySeparated()
                        cell.current = 100.0
                        cell.slider.value = 100.0
                        cell.myVotesUnitLabel.text = "(100.0%)"

                        this.editedDelegate = sliderMaxValue
                        this.percent = 100.0
                        self.newList[indexPath.row - self.myVoteList.count] = this
                        
                        self.isChanged.onNext(true)
                        return
                    }

                    guard let bigValueDecimal = bigValue.decimalNumber, let maxValueDecimal = sliderMaxValue.decimalNumber else { return }
                    
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
                    self.isChanged.onNext(true)
                }).disposed(by: cell.disposeBag)
                
                cell.myVotesField.rx.controlEvent(.editingDidEnd).subscribe { [unowned self] (_) in
                    self.delegate.voteViewModel.newList.onNext(self.newList)
                }.disposed(by: cell.disposeBag)
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
            return sectionHeader
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if selectedIndexPath == indexPath {
                selectedIndexPath = nil
            } else {
                selectedIndexPath = indexPath
            }
            self.tooltip = nil
            self.tableView.reloadData()
        } else {
            selectedIndexPath = nil
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
