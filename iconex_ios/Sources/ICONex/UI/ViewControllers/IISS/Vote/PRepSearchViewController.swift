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
    var prepList: [NewPReps] { get }
    var voteViewModel: VoteViewModel! { get }
}

class PRepSearchViewController: BaseViewController {
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomAnchor: NSLayoutConstraint!
    
    var delegate: PRepSearchDelegate!
    
    var searched = [NewPReps]()
    
    var wallet: ICXWallet?
    
    var newList = [MyVoteEditInfo]()
    
    var myVoteList = [MyVoteEditInfo]()
    
    var isViewMode: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.view.endEditing(true)
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        searchField.placeholder = "PRepSearch.Placeholder".localized
        searchField.keyboardType = .asciiCapable
        searchField.returnKeyType = .search
        
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
        
        self.tableView.rx.didScroll
            .subscribe { (_) in
                self.view.endEditing(true)
        }.disposed(by: disposeBag)
        
        if !isViewMode {
            delegate.voteViewModel.newList.subscribe(onNext: { (list) in
                self.newList = list
            }).disposed(by: disposeBag)

            delegate.voteViewModel.myList.subscribe(onNext: { (list) in
                self.myVoteList = list
            }).disposed(by: disposeBag)
        }
    }
}

extension PRepSearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searched.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PRepSearchCell", for: indexPath) as! PRepViewCell
        let prep = searched[indexPath.row]
        cell.addButton.isHidden = false
        
        cell.rankLabel.size12(text: "\(prep.rank).", color: .gray77, weight: .semibold)
        
        cell.prepNameLabel.size12(text: prep.name, color: .gray77, weight: .semibold, align: .left)
        cell.totalVoteValue.size12(text: prep.delegated.toString(decimal: 18, 4, false), color: .gray77, weight: .semibold, align: .right)
        
        let totalDelegatedDecimal = Manager.voteList.preps?.totalDelegated.decimalNumber ?? 0
        let prepDelegated = prep.delegated.decimalNumber ?? 0
        
        let delegatedPercent: Float = {
            if prepDelegated > 0 {
                return (prepDelegated / totalDelegatedDecimal).floatValue * 100
            } else {
                return 0.0
            }
        }()
        
        cell.totalVotePercent.size12(text: "(" + String(format: "%.1f", delegatedPercent) + "%)", color: .gray77, weight: .semibold, align: .right)
        
        cell.active = true
        
        cell.addButton.isHidden = self.isViewMode
        
        let myVoteChecker = self.myVoteList.filter({ $0.address == prep.address }).count == 0
        let newVoteChecker = self.newList.filter({ $0.address == prep.address }).count == 0
        
        let checker = myVoteChecker && newVoteChecker
        
        cell.addButton.isSelected = !checker
        
        let grade: String = {
            switch prep.grade {
            case .main: return "Main P-Rep"
            case .sub: return "Sub P-Rep"
            case .candidate: return "Candidate"
            }
        }()
        
        if isViewMode {
            if let checker = Manager.voteList.myVotes?.delegations.filter({ $0.address == prep.address }).count, checker > 0 {
                cell.prepTypeLabel.size12(text: "(" + grade + " / Voted)", color: .gray77)
            } else {
                cell.prepTypeLabel.size12(text: "(" + grade + ")", color: .gray77)
            }
        } else {
            if checker {
                cell.prepTypeLabel.size12(text: "(" + grade + ")", color: .gray77)
            } else {
                cell.prepTypeLabel.size12(text: "(" + grade + " / Voted)", color: .gray77)
            }
        }
        
        cell.addButton.rx.tap.asControlEvent().subscribe { (_) in
            self.view.endEditing(true)
            
            let myEdited = MyVoteEditInfo(prepName: prep.name, address: prep.address, totalDelegate: prep.delegated, myDelegate: nil, editedDelegate: nil, isMyVote: false, percent: nil, grade: prep.grade)
            
            if Manager.voteList.contains(address: prep.address) || !myVoteChecker {
                Toast.toast(message: "PRepView.ToolTip.Exist".localized)
                self.tableView.reloadData()
            } else {
                if Manager.voteList.add(prep: myEdited) {
                    self.delegate.voteViewModel.currentAddedList.onNext(Manager.voteList.myAddList)
                    guard let total = try? self.delegate.voteViewModel.voteCount.value() else { return }
                    Tool.voteToast(count: total)
                    self.tableView.reloadData()
                    
                } else {
                    Toast.toast(message: "PRepView.ToolTip.Maximum".localized)
                }
            }
            
        }.disposed(by: cell.disposeBag)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let wallet = self.wallet else { return }
        let prepInfo = self.searched[indexPath.row]
        
        DispatchQueue.global().async {
            guard let prep = Manager.icon.getPRepInfo(from: wallet, address: prepInfo.address) else { return }

            DispatchQueue.main.async {
                Alert.prepDetail(prepInfo: prep).show()
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
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
