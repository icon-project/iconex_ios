//
//  Votes.swift
//  iconex_ios
//
//  Created by a1ahn on 07/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import BigInt
import RxSwift
import RxCocoa

struct MyVoteEditInfo {
    var prepName: String
    var address: String
    var totalDelegate: BigUInt
    var myDelegate: BigUInt?
    var editedDelegate: BigUInt?
    var isMyVote: Bool
    var percent: Float?
    var grade: PRepGrade
}

class VoteListManager {
    static let shared = VoteListManager()
    
    private init () { }
    
    var myVotes: TotalDelegation?
    
    var preps: PRepListResponse?
    
    var myAddList = [MyVoteEditInfo]()
    
    var currentAddedList = PublishSubject<[MyVoteEditInfo]>()
    
    var votesCount: Int {
        return (myVotes?.delegations.count ?? 0) + myAddList.count
    }
    
    func loadPrepList(from: ICXWallet) -> (PRepListResponse?, [MyVoteEditInfo]?) {
        let preps = Manager.icon.getPreps(from: from, start: nil, end: nil)
        self.preps = preps
        
        var myList: [MyVoteEditInfo]? = nil
        if let response = preps {
            myList = [MyVoteEditInfo]()
            for prep in response.preps {
                let editInfo = MyVoteEditInfo(prepName: prep.name, address: prep.address, totalDelegate: prep.delegated, myDelegate: nil, editedDelegate: nil, isMyVote: false, percent: nil, grade: prep.grade)
                myList?.append(editInfo)
            }
        }
        return (preps, myList)
    }
    
    func loadPrepList(from: ICXWallet, _ completion: ((PRepListResponse?, [MyVoteEditInfo]?) -> Void)? = nil) {
        DispatchQueue.global().async {
            let preps = Manager.icon.getPreps(from: from, start: nil, end: nil)
            self.preps = preps
            
            var myList: [MyVoteEditInfo]? = nil
            if let response = preps {
                myList = [MyVoteEditInfo]()
                for prep in response.preps {
                    let editInfo = MyVoteEditInfo(prepName: prep.name, address: prep.address, totalDelegate: prep.delegated, myDelegate: nil, editedDelegate: nil, isMyVote: false, percent: nil, grade: prep.grade)
                    myList?.append(editInfo)
                }
            }
            
            DispatchQueue.main.async {
                completion?(preps, myList)
            }
        }
    }
    
    func loadPrepListwithRank(from: ICXWallet, _ completion: ((NewPRepListResponse?, [MyVoteEditInfo]?) -> Void)? = nil) {
        DispatchQueue.global().async {
            let preps = Manager.icon.getPreps(from: from, start: nil, end: nil)
            self.preps = preps
            
            var myList: [MyVoteEditInfo]? = nil
            
            var new: NewPRepListResponse? = nil
            
            var rankedList = [NewPReps]()
            
            if let response = preps {
                myList = [MyVoteEditInfo]()
                
                for prep in response.preps {
                    let editInfo = MyVoteEditInfo(prepName: prep.name, address: prep.address, totalDelegate: prep.delegated, myDelegate: nil, editedDelegate: nil, isMyVote: false, percent: nil, grade: prep.grade)
                    myList?.append(editInfo)
                    
                    let rankInfo = NewPReps(rank: rankedList.count + 1, name: prep.name, country: prep.country, city: prep.city, address: prep.address, stake: prep.stake, delegated: prep.delegated, grade: prep.grade, irep: prep.irep, irepUpdateBlockHeight: prep.irepUpdateBlockHeight, lastGenerateBlockHeight: prep.lastGenerateBlockHeight, totalBlocks: prep.totalBlocks, validatedBlocks: prep.validatedBlocks)
                    
                    rankedList.append(rankInfo)
                }
                
                new = NewPRepListResponse(blockHeight: response.blockHeight, startRanking: response.startRanking, totalDelegated: response.totalDelegated, totalStake: response.totalStake, preps: rankedList)
            }
            
            DispatchQueue.main.async {
                completion?(new, myList)
            }
        }
    }
    
    func loadMyVotes(from: ICXWallet) -> (TotalDelegation?, [MyVoteEditInfo]?) {
        let result = Manager.icon.getDelegation(wallet: from)
        self.myVotes = result
        var myList: [MyVoteEditInfo]? = nil
        if let response = result {
            myList = [MyVoteEditInfo]()
            for prep in response.delegations {
                guard let prepInfo = Manager.icon.getPRepInfo(from: from, address: prep.address) else { continue }
                let myInfo = MyVoteEditInfo(prepName: prepInfo.name, address: prep.address, totalDelegate: prepInfo.delegated, myDelegate: prep.value, editedDelegate: nil, isMyVote: true, percent: nil, grade: prepInfo.grade)
                myList?.append(myInfo)
            }
        }
        return (result, myList)
    }
    
    func loadMyVotes(from: ICXWallet, _ completion: ((TotalDelegation?, [MyVoteEditInfo]?) -> Void)? = nil) {
        DispatchQueue.global().async {
            let result = Manager.icon.getDelegation(wallet: from)
            self.myVotes = result
            
            var myList: [MyVoteEditInfo]? = nil
            if let response = result {
                myList = [MyVoteEditInfo]()
                for prep in response.delegations {
                    guard let prepInfo = Manager.icon.getPRepInfo(from: from, address: prep.address) else { continue }
                    let myInfo = MyVoteEditInfo(prepName: prepInfo.name, address: prep.address, totalDelegate: prepInfo.delegated, myDelegate: prep.value, editedDelegate: nil, isMyVote: true, percent: nil, grade: prepInfo.grade)
                    myList?.append(myInfo)
                }
            }
            
            DispatchQueue.main.async {
                completion?(result, myList)
            }
        }
    }
    
    func contains(address: String) -> Bool {
        return myAddList.filter { $0.address == address }.count != 0
    }
    
    func add(prep: MyVoteEditInfo) -> Bool {
        guard (myVotes?.delegations.count ?? 0) + myAddList.count < 10 else { return false }
        
        myAddList.append(prep)
        Log("added List - \(myAddList)")
        currentAddedList.onNext(myAddList)
        return true
    }
    
    func remove(prep: MyVoteEditInfo) {
        let filtered = myAddList.enumerated().filter { $0.element.address == prep.address }
        
        if let index = filtered.first?.offset {
            _ = myAddList.remove(at: index)
            Log("added List - \(myAddList)")
            currentAddedList.onNext(myAddList)
        }
    }
    
    func reset() {
        myAddList.removeAll()
        currentAddedList.onNext(myAddList)
    }
}
