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
    
    var totalDelegated: BehaviorSubject<BigUInt>
    var votingPower: BehaviorSubject<BigUInt>
    
    var isChanged: PublishSubject<Bool>
    
    var available: BehaviorSubject<BigUInt>
    
    var myList: PublishSubject<[MyVoteEditInfo]>
    var newList: PublishSubject<[MyVoteEditInfo]>
    
    var disposeBag = DisposeBag()
    
    init() {
        self.totalDelegated = BehaviorSubject<BigUInt>(value: Manager.voteList.myVotes?.totalDelegated ?? 0)
        self.votingPower = BehaviorSubject<BigUInt>(value: Manager.voteList.myVotes?.votingPower ?? 0)
    
        
        self.isChanged = PublishSubject<Bool>()
        self.available = BehaviorSubject<BigUInt>(value: Manager.voteList.myVotes?.votingPower ?? 0)
        self.myList = PublishSubject<[MyVoteEditInfo]>()
        self.newList = PublishSubject<[MyVoteEditInfo]>()
        
        
        
    }
}

let voteViewModel = VoteViewModel.shared

