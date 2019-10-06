//
//  VoteViewModel.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 09/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import BigInt

class VoteViewModel {
    static let shared = VoteViewModel()
    
    var isChanged: PublishSubject<Bool>
    
    var available: BehaviorSubject<BigUInt>
    
    var originalList: PublishSubject<[MyVoteEditInfo]>
    var myList: BehaviorSubject<[MyVoteEditInfo]>
    var newList: BehaviorSubject<[MyVoteEditInfo]>
    
    var voteCount: BehaviorSubject<Int>
    
    var disposeBag = DisposeBag()
    
    init() {
        self.isChanged = PublishSubject<Bool>()
        self.available = BehaviorSubject<BigUInt>(value: Manager.voteList.myVotes?.votingPower ?? 0)
        
        self.originalList = PublishSubject<[MyVoteEditInfo]>()
        self.myList = BehaviorSubject<[MyVoteEditInfo]>(value: [MyVoteEditInfo]())
        self.newList = BehaviorSubject<[MyVoteEditInfo]>(value: [MyVoteEditInfo]())
        self.voteCount = BehaviorSubject<Int>(value: Manager.voteList.votesCount)
        
        Observable.combineLatest(self.myList, self.newList).flatMapLatest { (myList, newList) -> Observable<Int> in
            let total = myList + newList
            return Observable.just(total.count)
        }.bind(to: self.voteCount)
        .disposed(by: disposeBag)
    }
}

let voteViewModel = VoteViewModel.shared

let sharedAvailable = voteViewModel.available.share(replay: 1)
