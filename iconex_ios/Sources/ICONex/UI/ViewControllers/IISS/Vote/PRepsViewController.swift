//
//  PRepsViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 23/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PanModal
import BigInt

public enum OrderType {
    case rankDescending, rankAscending, nameDescending, nameAscending
}

public struct NewPRepListResponse {
    var blockHeight: BigUInt
    var startRanking: BigUInt
    var totalDelegated: BigUInt
    var totalStake: BigUInt
    var preps: [NewPReps]
}

public struct NewPReps {
    var rank: Int
    var name: String
    var country: String
    var city: String
    var address: String
    var stake: BigUInt
    var delegated: BigUInt
    var grade: PRepGrade
    var irep: BigUInt
    var irepUpdateBlockHeight: BigUInt
    var lastGenerateBlockHeight: BigUInt?
    var totalBlocks: BigUInt
    var validatedBlocks: BigUInt
}

class PRepsViewController: BaseViewController, Floatable {
    @IBOutlet weak var firstItem: UIButton!
    @IBOutlet weak var secondItem: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    unowned var delegate: VoteMainDelegate!
    
    var floater: Floater = {
        return Floater(type: .search)
    }()
    
    var selectedWallet: ICXWallet? { return delegate.wallet }
    
    private var refreshControl: UIRefreshControl?
    private var preps: NewPRepListResponse?
    private var editInfoList: [MyVoteEditInfo]?
    
    private var myvoteList: [MyVoteEditInfo]?
    private var newList: [MyVoteEditInfo]?
    
    private var sortType: OrderType = .rankDescending {
        willSet {
            sectionHeader.orderType = newValue
        }
    }
    
    private var sectionHeader = PRepSectionHeaderView(frame: CGRect(x: 0, y: 0, width: .max, height: 36))
    
    private let toolTip: IXToolTip = IXToolTip()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        tableView.register(UINib(nibName: "PRepViewCell", bundle: nil), forCellReuseIdentifier: "PRepViewCell")
        
        firstItem.setTitle("My Votes", for: .normal)
        firstItem.setTitleColor(.gray77, for: .normal)
        firstItem.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        secondItem.size14(text: "P-Reps", color: .gray77, weight: .bold, align: .center)
        
        firstItem.rx.tap.subscribe(onNext: { [weak self] in
            self?.delegate.headerSelected(index: 0)
            self?.toolTip.dismissLastToolTip()
        }).disposed(by: disposeBag)
        
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
        
        let refresh = UIRefreshControl()
        tableView.refreshControl = refresh
        self.refreshControl = refresh
        refresh.beginRefreshing()
        
        delegate.voteViewModel.myList.subscribe(onNext: { (list) in
            self.myvoteList = list
            self.tableView.reloadData()
        }).disposed(by: disposeBag)
        
        delegate.voteViewModel.newList.subscribe { (_) in
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        floater.button.rx.tap.subscribe(onNext: { [unowned self] in
            let search = UIStoryboard(name: "Vote", bundle: nil).instantiateViewController(withIdentifier: "PRepSearchView") as! PRepSearchViewController
            search.wallet = self.selectedWallet
            search.delegate = self
            search.pop(self)
        }).disposed(by: disposeBag)
        
        sectionHeader.orderButton.rx.tap.asControlEvent().subscribe { [unowned self] (_) in
            self.toolTip.dismissLastToolTip()
            
            switch self.sortType {
            case .rankDescending:
                self.sortType = .rankAscending
                self.loadData()
                
            case .rankAscending:
                self.sortType = .nameDescending
                self.loadData()
                
            case .nameDescending:
                self.sortType = .nameAscending
                self.loadData()
                
            case .nameAscending:
                self.sortType = .rankDescending
                self.loadData()
            }
            
        }.disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        
        loadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.bringSubviewToFront(floater.contentView)
        attach()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        detach()
    }
}

extension PRepsViewController {
    @objc func loadData() {
        Manager.voteList.loadPrepListwithRank(from: delegate.wallet) { [unowned self] preps, editInfoList in
            if let refresh = self.refreshControl {
                refresh.endRefreshing()
                self.tableView.refreshControl = nil
                self.refreshControl = nil
            }
            
            let orderedList: NewPRepListResponse? = {
                guard var prepInfo = preps, let prepList = preps?.preps else { return preps }
                
                switch self.sortType {
                case .rankDescending:
                    return preps
                case .rankAscending:
                    prepInfo.preps.reverse()
                    
                    return prepInfo
                    
                case .nameDescending:
                    let aa = prepList.sorted(by: { (lhs, rhs) -> Bool in
                        return lhs.name < rhs.name
                    })
                    prepInfo.preps = aa
                    return prepInfo
                    
                case .nameAscending:
                    let aa = prepList.sorted(by: { (lhs, rhs) -> Bool in
                        return lhs.name > rhs.name
                    })
                    prepInfo.preps = aa
                    return prepInfo
                    
                }
            }()
            
            let orderedEditList: [MyVoteEditInfo]? = {
                guard var editInfo = editInfoList else { return editInfoList }
                
                switch self.sortType {
                case .rankDescending:
                    break
                    
                case .rankAscending:
                    editInfo.reverse()
                    
                case .nameDescending:
                    editInfo.sort(by: { (lhs, rhs) -> Bool in
                        return lhs.prepName < rhs.prepName
                    })
                    
                case .nameAscending:
                    editInfo.sort(by: { (lhs, rhs) -> Bool in
                        return lhs.prepName > rhs.prepName
                    })
                }
                return editInfo
            }()
        
            self.preps = orderedList
            self.editInfoList = orderedEditList
            self.tableView.reloadData()
        }
    }
}

extension PRepsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let list = preps?.preps {
            return list.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PRepViewCell", for: indexPath) as! PRepViewCell
        cell.addButton.isHidden = false
        
        guard let prepList = preps?.preps else { return cell }
        let prep = prepList[indexPath.row]
        
        guard let checker = self.myvoteList?.filter({ $0.address == prep.address }).count else { return cell }
        
        cell.rankLabel.size12(text: "\(prep.rank).", color: .gray77, weight: .semibold)
        
        let grade: String = {
            switch prep.grade {
            case .main: return "Main P-Rep"
            case .sub: return "Sub P-Rep"
            case .candidate: return "Candidate"
            }
        }()
        
        cell.prepNameLabel.size12(text: prep.name, color: .gray77, weight: .semibold, align: .left)
        
        if let checker = Manager.voteList.myVotes?.delegations.filter({ $0.address == prep.address }).count, checker > 0 {
            cell.prepTypeLabel.size12(text: "(" + grade + " / Voted)", color: .gray77)
        } else {
            cell.prepTypeLabel.size12(text: "(" + grade + ")", color: .gray77)
        }
        
        cell.totalVoteValue.size12(text: prep.delegated.toString(decimal: 18, 4, false), color: .gray77, weight: .semibold, align: .right)
        
        let totalDelegated = self.preps?.totalDelegated ?? 0
        let totalDelegatedDecimal = totalDelegated.decimalNumber ?? 0
        let prepDelegated = prep.delegated.decimalNumber ?? 0
        
        let delegatedPercent = (prepDelegated / totalDelegatedDecimal).floatValue * 100
        
        cell.totalVotePercent.size12(text: "(" + String(format: "%.1f", delegatedPercent) + "%)", color: .gray77, weight: .semibold, align: .right)
        cell.active = true
        
        cell.addButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                let editInfo = self.editInfoList![indexPath.row]
                if Manager.voteList.contains(address: editInfo.address) || checker > 0 {
                    self.toolTip.show(positionY: cell.frame.origin.y-14-self.view.safeAreaInsets.top, message: "PRepView.ToolTip.Exist".localized, parent: self.tableView)
                    self.tableView.reloadData()
                } else {
                    if Manager.voteList.add(prep: editInfo) {
                        let myVoteCount = self.myvoteList?.count ?? 0
                        let newVoteCount = Manager.voteList.myAddList.count
                        
                        let total = myVoteCount + newVoteCount
                        Tool.voteToast(count: total)
                        
                        self.delegate.voteViewModel.currentAddedList.onNext(Manager.voteList.myAddList)
                    } else {
                        self.toolTip.show(positionY: cell.frame.origin.y-14-self.view.safeAreaInsets.top, message: "PRepView.ToolTip.Maximum".localized, parent: self.tableView)
                    }
                }
            }).disposed(by: cell.disposeBag)
        
        cell.addButton.isSelected = Manager.voteList.contains(address: prep.address) || checker > 0
        
        return cell
    }
}

extension PRepsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let wallet = self.selectedWallet, let prepInfo = self.preps?.preps[indexPath.row] else { return }
        
        DispatchQueue.global().async {
            guard let prep = Manager.icon.getPRepInfo(from: wallet, address: prepInfo.address) else { return }
            
            DispatchQueue.main.async {
                Alert.prepDetail(prepInfo: prep).show()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return sectionHeader
    }
}

extension PRepsViewController: PRepSearchDelegate {
    var prepList: [NewPReps] {
        if let list = preps?.preps {
            return list
        }
        
        return []
    }
    
    var voteViewModel: VoteViewModel! {
        return delegate.voteViewModel
    }
}
