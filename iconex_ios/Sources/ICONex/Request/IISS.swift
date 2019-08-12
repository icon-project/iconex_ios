//
//  IISS.swift
//  iconex_ios
//
//  Created by a1ahn on 12/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import BigInt

// MARK: Stake
struct PRepStakeResponse: Decodable {
    /// Amount of Staking
    ///
    /// Unit: loop
    var stake: BigUInt
    
    /// Amount of Unstaking
    ///
    /// Unit: loop
    var unstake: BigUInt?
    
    /// Block height when unstake will be done
    var unstakeBlockHeight: BigUInt?
    
    /// The number of remaining blocks to reach unstakeBlockHeight
    var remainingBlocks: BigUInt?
}

// MARK: Delegation
struct PRepDelegation: Codable {
    var address: String
    var value: BigUInt
}

struct TotalDelegation: Decodable {
    var totalDelegated: BigUInt
    var votingPower: BigUInt
    var delegations: [PRepDelegation]
}

// MARK: I-Score
struct QueryIScoreResponse: Decodable {
    var blockHeight: BigUInt
    var iscore: BigUInt
    var estimatedICX: BigUInt
}
