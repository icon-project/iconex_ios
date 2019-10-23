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

protocol VoteMainDelegate: class {
    var wallet: ICXWallet! { get set }
    func headerSelected(index: Int)
    var stepLimit: String { get set }
    var maxFee: String { get set }
    var estimatedStep: BigUInt { get set }
    var voteViewModel: VoteViewModel { get set }
}

class VoteMainViewController: BaseViewController, VoteMainDelegate {
    @IBOutlet weak var navBar: IXNavigationView!
    @IBOutlet weak var prepContainer: UIView!
    @IBOutlet weak var myvoteContainer: UIView!
    @IBOutlet weak var buttonConatiner: UIView!
    @IBOutlet weak var voteButton: UIButton!
    @IBOutlet weak var bottomHeight: NSLayoutConstraint!
    
    var voteViewModel: VoteViewModel = VoteViewModel()
    
    weak var wallet: ICXWallet!
    var key: PrivateKey!
    
    var stepLimit: String = ""
    var maxFee: String = ""
    var estimatedStep: BigUInt = 0
    
    var isPreps: Bool = false
    
    var votedList: [MyVoteEditInfo] = [MyVoteEditInfo]()
    var votingList: [MyVoteEditInfo] = [MyVoteEditInfo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.isMovingFromParent {
            print("View Did Disappear - Vote Main")
            
            Manager.voteList.reset()
//            voteViewModel.dispose()
        }
    }
    deinit {
        Log("deinit")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let myVote = segue.destination as? MyVoteViewController {
            myVote.delegate = self
        } else if let prep = segue.destination as? PRepsViewController {
            prep.delegate = self
        }
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        navBar.setTitle(wallet.name)
        navBar.setLeft {
            if self.voteButton.isEnabled {
                Alert.basic(title: "MyVoteView.Alert.Back".localized, isOnlyOneButton: false, leftButtonTitle: "Common.No".localized, rightButtonTitle: "Common.Yes".localized, confirmAction: {
                    self.navigationController?.popViewController(animated: true)
                }).show()
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        headerSelected(index: isPreps ? 1: 0)
        
        buttonConatiner.backgroundColor = .gray252
        voteButton.lightMintRounded()
        voteButton.setTitle("Vote", for: .normal)
        
        voteButton.isEnabled = false
        
        Observable.combineLatest(voteViewModel.originalList, voteViewModel.myList, voteViewModel.newList).flatMapLatest { [unowned self] (originalList, myList, newList) -> Observable<Bool> in
            for i in myList {
                let newPrepChecker = originalList.contains(where: { (list) -> Bool in
                    return i.address == list.address
                })
                
                guard newPrepChecker else {
                    self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                    return Observable.just(true)
                }
            }
            
            if originalList.count != myList.count {
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                return Observable.just(true)
            }
            
            for i in myList {
                if i.editedDelegate != nil && i.editedDelegate != i.myDelegate {
                    self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                    return Observable.just(true)
                }
            }
            
            for i in newList {
                if let edited = i.editedDelegate, edited > BigUInt(0) {
                    self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                    return Observable.just(true)
                }
            }
            
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            return Observable.just(false)
            
        }.bind(to: self.voteButton.rx.isEnabled).disposed(by: disposeBag)
        
        voteViewModel.myList
            .subscribe(onNext: { [unowned self] (list) in
                self.votedList = list
            }).disposed(by: disposeBag)
        
        voteViewModel.newList
            .subscribe(onNext: { [unowned self] (list) in
                self.votingList = list
            }).disposed(by: disposeBag)
        
//        children.forEach({
//            if let myVote = $0 as? MyVoteViewController {
//                myVote.delegate = self
//            } else if let prep = $0 as? PRepsViewController {
//                prep.delegate = self
//            }
//        })
        
        voteButton.rx.tap.asControlEvent()
            .subscribe { [unowned self] (_) in
                guard let pk = self.key else { return }
                
                let balance = Manager.balance.getBalance(wallet: self.wallet) ?? 0
                let step = self.estimatedStep.convert(unit: .gLoop)
                
                guard balance >= step else {
                    Alert.basic(title: "MyVoteView.Alert.InsufficientFee".localized, leftButtonTitle: "Common.Confirm".localized).show()
                    return
                }
                
                var delList = [[String: Any]]()
                
                for i in self.votedList {
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
                
                for i in self.votingList {
                    let info = ["address": i.address, "value": i.editedDelegate?.toHexString() ?? "0x0"]
                    delList.append(info)
                    
                }
                let price = Tool.calculatePrice(currency: "icxusd", balance: self.estimatedStep)
                
                let voteInfo = VoteInfo(count: delList.count, estimatedFee: self.stepLimit, maxFee: self.maxFee, usdPrice: price, wallet: self.wallet, delegationList: delList, privateKey: pk)
                
                Alert.vote(voteInfo: voteInfo, confirmAction: { isSuccess, txHash in
                    if isSuccess {
                        Tool.toast(message: "MyVoteView.Toast".localized)
                        self.navigationController?.popToRootViewController(animated: true)
                    } else {
                        Log(txHash, .error)
                        Tool.toast(message: "Error.CommonError".localized)
                    }
                    
                }).show()
                
        }.disposed(by: disposeBag)
        
        Observable.combineLatest(voteViewModel.myList, voteViewModel.newList).flatMapLatest { (myList, newList) -> Observable<Int> in
            let total = myList + newList
            return Observable.just(total.count)
        }.bind(to: voteViewModel.voteCount)
        .disposed(by: disposeBag)
    }
}

extension VoteMainViewController {
    func headerSelected(index: Int) {
        prepContainer.isHidden = index == 0
        myvoteContainer.isHidden = index != 0
        bottomHeight.constant = index == 0 ? 66 : 0 - view.safeAreaInsets.bottom
    }
}
