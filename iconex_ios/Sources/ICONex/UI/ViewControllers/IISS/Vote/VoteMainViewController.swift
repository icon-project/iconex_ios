//
//  VoteMainViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 22/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ICONKit
import BigInt

protocol VoteMainDelegate {
    var wallet: ICXWallet! { get set }
    func headerSelected(index: Int)
}

class VoteMainViewController: BaseViewController, VoteMainDelegate {
    @IBOutlet weak var navBar: IXNavigationView!
    @IBOutlet weak var prepContainer: UIView!
    @IBOutlet weak var myvoteContainer: UIView!
    @IBOutlet weak var buttonConatiner: UIView!
    @IBOutlet weak var voteButton: UIButton!
    @IBOutlet weak var bottomHeight: NSLayoutConstraint!
    
    var wallet: ICXWallet!
    var key: PrivateKey!
    
    var isPreps: Bool = false
    
    var votedList: [MyVoteEditInfo] = [MyVoteEditInfo]()
    var votingList: [MyVoteEditInfo] = [MyVoteEditInfo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        navBar.setTitle(wallet.name)
        navBar.setLeft {
            if self.voteButton.isEnabled {
                Alert.basic(title: "MyVoteView.Alert.Back".localized, isOnlyOneButton: false, leftButtonTitle: "Common.No".localized, rightButtonTitle: "Common.Yes".localized, confirmAction: {
                    self.navigationController?.popViewController(animated: true)
                    Manager.voteList.reset()
                }).show()
            } else {
                self.navigationController?.popViewController(animated: true)
                Manager.voteList.reset()
            }
        }
        
        headerSelected(index: isPreps ? 1: 0)
        
        buttonConatiner.backgroundColor = .gray252
        voteButton.lightMintRounded()
        voteButton.setTitle("Vote", for: .normal)
        
        voteButton.isEnabled = false
        
        Observable.merge(voteViewModel.myList, voteViewModel.newList)
            .subscribe(onNext: { (list) in
                for i in list {
                    if i.editedDelegate != nil {
                        self.voteButton.rx.isEnabled.onNext(true)
                        return
                    }
                }
                
                self.voteButton.rx.isEnabled.onNext(false)
                return
        }).disposed(by: disposeBag)
        
        voteViewModel.myList
            .subscribe(onNext: { (list) in
                self.votedList = list
            }).disposed(by: disposeBag)
        
        voteViewModel.newList
            .subscribe(onNext: { (list) in
                self.votingList = list
            }).disposed(by: disposeBag)
        
        children.forEach({
            if let myVote = $0 as? MyVoteViewController {
                myVote.delegate = self
            } else if let prep = $0 as? PRepsViewController {
                prep.delegate = self
            }
        })
        
        voteButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                guard let pk = self.key else { return }
                
                var delList = [[String: Any]]()
                
                for i in self.votedList {
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

                    print("voted List \(i)")
                }
                
                // 새로 추가한 리스트
                for i in self.votingList {
                    let info = ["address": i.address, "value": i.editedDelegate?.toHexString() ?? "0x0"]
                    delList.append(info)
                    
                    print("new voting list \(i)")
                    
                }
                let voteInfo = VoteInfo(count: delList.count, estimatedFee: "-", maxFee: "-", wallet: self.wallet, delegationList: delList, privateKey: pk)
                
                Alert.vote(voteInfo: voteInfo, confirmAction: { isSuccess, txHash in
                    if isSuccess {
                        app.window?.showToast(message: "MyVoteView.Toast".localized)
                    } else {
                        app.window?.showToast(message: txHash ?? "Common.Error".localized)
                    }
                    
                }).show()
                
        }.disposed(by: disposeBag)
        
        
        voteViewModel.isChanged.subscribe { (_) in
            let votedListPower: BigUInt = self.votedList.map {
                if $0.editedDelegate == nil {
                    return $0.myDelegate ?? 0
                } else {
                    return $0.editedDelegate ?? 0
                }
            }.reduce(0, +)
            Log("voted \(votedListPower)")
            
            let votingListPower: BigUInt = self.votingList.map {
                if $0.editedDelegate == nil {
                    return $0.myDelegate ?? 0
                } else {
                    return $0.editedDelegate ?? 0
                }
                }.reduce(0, +)
            Log("voting \(votingListPower)")
            
            let power = Manager.voteList.myVotes?.votingPower ?? 0
            let delegated = Manager.voteList.myVotes?.totalDelegated ?? 0
            let total = power + delegated
            let plus = votedListPower + votingListPower
            
            Log("Power \(power) delegated \(delegated) total \(total) plus \(plus)")
            
            guard plus <= total else { return voteViewModel.available.onNext(0) }
            
            let result = total - plus
            
            voteViewModel.available.onNext(result)
        }.disposed(by: disposeBag)
    }
}

extension VoteMainViewController {
    func headerSelected(index: Int) {
        prepContainer.isHidden = index == 0
        myvoteContainer.isHidden = index != 0
        bottomHeight.constant = index == 0 ? 66 : 0 - view.safeAreaInsets.bottom
    }
}
