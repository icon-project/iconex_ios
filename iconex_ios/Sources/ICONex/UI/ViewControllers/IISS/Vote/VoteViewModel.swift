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
    
    var originalList: PublishSubject<[MyVoteEditInfo]>
    var myList: BehaviorSubject<[MyVoteEditInfo]>
    var newList: BehaviorSubject<[MyVoteEditInfo]>
    
    var voteCount: BehaviorSubject<Int>
    
    var disposeBag = DisposeBag()
    
    init() {
        self.originalList = PublishSubject<[MyVoteEditInfo]>()
        self.myList = BehaviorSubject<[MyVoteEditInfo]>(value: [MyVoteEditInfo]())
        self.newList = BehaviorSubject<[MyVoteEditInfo]>(value: [MyVoteEditInfo]())
        self.voteCount = BehaviorSubject<Int>(value: Manager.voteList.votesCount)
    }
    
    func dispose() {
        disposeBag = DisposeBag()
    }
}

let voteViewModel = VoteViewModel.shared
