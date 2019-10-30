//
//  PRepListViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 30/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//


import UIKit
import RxSwift
import RxCocoa
import PanModal
import BigInt

class PRepListViewController: BaseViewController, Floatable {
    @IBOutlet weak var navBar: IXNavigationView!
    @IBOutlet weak var tableView: UITableView!
    
    var wallet: ICXWallet!
    
    var floater: Floater = {
        return Floater(type: .search)
    }()
    
    var selectedWallet: ICXWallet? { return wallet }
    
    private var refreshControl: UIRefreshControl = UIRefreshControl()
    private var preps: NewPRepListResponse?
    private var sectionHeader = PRepSectionHeaderView(frame: CGRect(x: 0, y: 0, width: .max, height: 36))
    private var sortType: OrderType = .rankDescending {
        willSet {
            sectionHeader.orderType = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        navBar.setLeft {
            self.navigationController?.popViewController(animated: true)
        }
        navBar.setTitle("P-Reps")
        
        tableView.register(UINib(nibName: "PRepViewCell", bundle: nil), forCellReuseIdentifier: "PRepViewCell")
        
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = self.refreshControl
        
        floater.button.rx.tap.subscribe(onNext: { [unowned self] in
            let search = UIStoryboard(name: "Vote", bundle: nil).instantiateViewController(withIdentifier: "PRepSearchView") as! PRepSearchViewController
            search.delegate = self
            search.isViewMode = true
            search.wallet = self.wallet
            search.pop(self)
        }).disposed(by: disposeBag)
        
        sectionHeader.orderButton.rx.tap.asControlEvent().subscribe { (_) in
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

extension PRepListViewController {
    func loadData() {
        guard self.refreshControl.isRefreshing == false else { return }
        
        self.refreshControl.beginRefreshing()
        
        DispatchQueue.global().async {
            // load my votes
            let _ = Manager.voteList.loadMyVotes(from: self.wallet)
            
            Manager.voteList.loadPrepListwithRank(from: self.wallet) { preps, editInfoList in
                self.refreshControl.endRefreshing()
                
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
                
                DispatchQueue.main.async {
                    self.preps = orderedList
                    self.tableView.reloadData()
                }
            }
        
        }
    }
}

extension PRepListViewController: UITableViewDataSource {
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
        cell.addButton.isHidden = true
        
        guard let prepList = preps?.preps else { return cell }
        let prep = prepList[indexPath.row]
        
        cell.rankLabel.size12(text: "\(prep.rank).", color: .gray77, weight: .semibold)
        
        let grade: String = {
            switch prep.grade {
            case .main: return "Main P-Rep"
            case .sub: return "Sub P-Rep"
            case .candidate: return "Candidate"
            }
        }()
        
        cell.prepNameLabel.size12(text: prep.name, color: .gray77, weight: .semibold, align: .left, lineBreakMode: .byTruncatingTail)
        
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
        
        return cell
    }
}

extension PRepListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let wallet = self.wallet, let prepList = preps?.preps else { return }
        let prepInfo = prepList[indexPath.row]
        
        DispatchQueue.global().async {
            guard let prep = Manager.icon.getPRepInfo(from: wallet, address: prepInfo.address) else { return }
            
            DispatchQueue.main.async {
                Alert.prepDetail(prepInfo: prep).show()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return sectionHeader
    }
}

extension PRepListViewController: PRepSearchDelegate {
    var prepList: [NewPReps] {
        if let list = preps?.preps {
            return list
        }
        
        return []
    }
    
    var voteViewModel: VoteViewModel! {
        return nil
    }
}
