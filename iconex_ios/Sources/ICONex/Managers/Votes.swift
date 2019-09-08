//
//  Votes.swift
//  iconex_ios
//
//  Created by a1ahn on 07/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import BigInt

struct MyVoteEditInfo {
    var prepName: String
    var address: String
    var totalDelegate: BigUInt
    var myDelegate: BigUInt?
    var editedDelegate: BigUInt?
    var isAdded: Bool
}

class VoteListManager {
    static let shared = VoteListManager()
    
    private init () { }
    
    private var myVotes: TotalDelegation?
    
    private var preps: PRepListResponse?
    
    private var addedList = [PRepListResponse.PReps]()
    
    var votesCount: Int {
        return (myVotes?.delegations.count ?? 0) + (preps?.preps.count ?? 0)
    }
    
    var myVotesList: [Any] {
        return (myVotes?.delegations ?? []) + (preps?.preps ?? [])
    }
    
    func add(prep: PRepListResponse.PReps) -> Bool {
        guard (myVotes?.delegations.count ?? 0) + addedList.count < 10 else { return false }
        
        addedList.append(prep)
        Log("added List - \(addedList)")
        return true
    }
    
    func remove(prep: PRepListResponse.PReps) {
        let filtered = addedList.enumerated().filter { $0.element.address == prep.address }
        
        if let index = filtered.first?.offset {
            _ = addedList.remove(at: index)
            Log("added List - \(addedList)")
        }
    }
    
    func loadPrepList(from: ICXWallet, _ completion: ((PRepListResponse?) -> Void)? = nil) {
        DispatchQueue.global().async {
            let preps = Manager.icon.getPreps(from: from, start: nil, end: nil)
            self.preps = preps
            DispatchQueue.main.async {
                completion?(preps)
            }
        }
    }
    
    func loadMyVotes(from: ICXWallet, _ completion: ((TotalDelegation?) -> Void)? = nil) {
        DispatchQueue.global().async {
            let result = Manager.icon.getDelegation(wallet: from)
            self.myVotes = result
            DispatchQueue.main.async {
                completion?(result)
            }
        }
    }
    
    func contains(address: String) -> Bool {
        return addedList.filter { $0.address == address }.count != 0
    }
}
