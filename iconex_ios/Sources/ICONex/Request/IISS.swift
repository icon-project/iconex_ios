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
    
    enum CodingKeys: String, CodingKey {
        case stake, unstake, unstakeBlockHeight, remainingBlocks
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let stakeString = try container.decode(String.self, forKey: .stake)
        guard let stake = stakeString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `stake` to BigUInt"))
        }
        self.stake = stake
        
        if container.contains(.unstake) {
            let unstakeString = try container.decode(String.self, forKey: .unstake)
            guard let unstake = unstakeString.hexToBigUInt() else {
                throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `unstake` to BigUInt"))
            }
            self.unstake = unstake
        }
        
        if container.contains(.unstakeBlockHeight) {
            let unstakeBlockString = try container.decode(String.self, forKey: .unstakeBlockHeight)
            guard let unstakeBlock = unstakeBlockString.hexToBigUInt() else {
                throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `unstakeBlockHeight` to BigUInt"))
            }
            self.unstakeBlockHeight = unstakeBlock
        }
        
        if container.contains(.remainingBlocks) {
            let remainingString = try container.decode(String.self, forKey: .remainingBlocks)
            guard let remaining = remainingString.hexToBigUInt() else {
                throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `remainingBlocks` to BigUInt"))
            }
            self.remainingBlocks = remaining
        }
        
    }
}

// Test
struct DelegationInfo: Codable {
    var address: String
    var value: String
}

// MARK: Delegation
struct PRepDelegation: Decodable {
    var address: String
    var value: BigUInt
//    var status: Int?
    var fine: BigUInt?
    
    enum CodingKeys: String, CodingKey {
        case address, value, status, fine
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.address = try container.decode(String.self, forKey: .address)
        let valueString = try container.decode(String.self, forKey: .value)
        guard let value = valueString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `value` to BigUInt"))
        }
        self.value = value
//        self.status = try container.decode(Int.self, forKey: .status)
        
        if container.contains(.fine) {
            let fineString = try container.decode(String.self, forKey: .fine)
            guard let fine = fineString.hexToBigUInt() else {
                throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `fine` to BigUInt"))
            }
            self.fine = fine
        }
    }
    
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(address, forKey: .address)
//        try container.encode(value.toHexString(), forKey: .value)
//        if let status = self.status {
//            try container.encode(status, forKey: .status)
//        }
//    }
}

struct TotalDelegation: Decodable {
    /// 특정 주소가 p-rep에게 voting한 수량 (즉, voted)
    var totalDelegated: BigUInt
    
    /// 특정 주소의 voting 가능한 수량 (즉, avaliable)
    var votingPower: BigUInt
    
    /// 이거 현재 안내려옴
    var status: Int?

    /// 특정 주소가 delegation한 p-rep 리스트
    var delegations: [PRepDelegation]
    
    enum CodingKeys: String, CodingKey {
        case totalDelegated, votingPower, delegations, status
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let totalString = try container.decode(String.self, forKey: .totalDelegated)
        guard let total = totalString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `totalDelegated` to BigUInt"))
        }
        self.totalDelegated = total
        
        let votingString = try container.decode(String.self, forKey: .votingPower)
        guard let voting = votingString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `votingPower` to BigUInt"))
        }
        self.votingPower = voting
        
        self.delegations = try container.decode([PRepDelegation].self, forKey: .delegations)
        if container.contains(.status) {
            self.status = try container.decode(Int.self, forKey: .status)
        } else {
            self.status = 0
        }
    }
}

// MARK: I-Score
struct QueryIScoreResponse: Decodable {
    var blockHeight: BigUInt
    var iscore: BigUInt
    var estimatedICX: BigUInt
    
    enum CodingKeys: String ,CodingKey {
        case blockHeight, iscore, estimatedICX
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let heightString = try container.decode(String.self, forKey: .blockHeight)
        guard let blockHeight = heightString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `blockHeight` to BigUInt"))
        }
        self.blockHeight = blockHeight
        
        let iscoreString = try container.decode(String.self, forKey: .iscore)
        guard let iscore = iscoreString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `iscore` to BigUInt"))
        }
        self.iscore = iscore
        
        let estimatedString = try container.decode(String.self, forKey: .estimatedICX)
        guard let estimated = estimatedString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `estimatedICX` to BigUInt"))
        }
        self.estimatedICX = estimated
    }
}

enum PRepStatus: String, Codable {
    case active = "0x0"
    case unregistered = "0x1"
    case disqualification = "0x2"
    case lowProductivity = "0x3"
}

enum PRepGrade: String, Codable {
    case main = "0x0"
    case sub = "0x1"
    case candidate = "0x2"
}

// MARK: P-REP
struct PRepInfoResponse: Decodable {
    var status: PRepStatus
    var grade: PRepGrade
    var name: String
    var country: String
    var city: String
    var email: String
    var website: String
    var details: String
    var p2pEndpoint: String
    var irep: BigUInt
    var irepUpdateBlockHeight: BigUInt
    var lastGenerateBlockHeight: BigUInt?
    var stake: BigUInt
    var delegated: BigUInt
    var totalBlocks: BigUInt
    var validatedBlocks: BigUInt
    
    enum CodingKeys: String, CodingKey {
        case status, grade, name, country, city, email, website, details, p2pEndpoint, irep, irepUpdateBlockHeight, lastGenerateBlockHeight, stake, delegated, totalBlocks, validatedBlocks
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decode(PRepStatus.self, forKey: .status)
        self.grade = try container.decode(PRepGrade.self, forKey: .grade)
        self.name = try container.decode(String.self, forKey: .name)
        self.country = try container.decode(String.self, forKey: .country)
        self.city = try container.decode(String.self, forKey: .city)
        self.email = try container.decode(String.self, forKey: .email)
        self.website = try container.decode(String.self, forKey: .website)
        self.details = try container.decode(String.self, forKey: .details)
        self.p2pEndpoint = try container.decode(String.self, forKey: .p2pEndpoint)
        let irepString = try container.decode(String.self, forKey: .irep)
        guard let irep = irepString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `irep` to BigUInt"))
        }
        self.irep = irep
        
        let updateBlockString = try container.decode(String.self, forKey: .irepUpdateBlockHeight)
        guard let updateBlock = updateBlockString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `irepUpdateBlockHeight` to BigUInt"))
        }
        self.irepUpdateBlockHeight = updateBlock
        
        let lastBlockString = try container.decode(String.self, forKey: .lastGenerateBlockHeight)
        if let lastBlock = lastBlockString.hexToBigUInt() {
            self.lastGenerateBlockHeight = lastBlock
        } else {
            self.lastGenerateBlockHeight = nil
        }
        
        let stakeString = try container.decode(String.self, forKey: .stake)
        guard let stake = stakeString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `stake` to BigUInt"))
        }
        self.stake = stake
        
        let delegatedString = try container.decode(String.self, forKey: .delegated)
        guard let delegated = delegatedString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `delegated` to BigUInt"))
        }
        self.delegated = delegated
        
        let totalString = try container.decode(String.self, forKey: .totalBlocks)
        guard let total = totalString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `totalBlocks` to BigUInt"))
        }
        self.totalBlocks = total
        
        let validatedString = try container.decode(String.self, forKey: .validatedBlocks)
        guard let validate = validatedString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `validatedBlocks` to BigUInt"))
        }
        self.validatedBlocks = validate
    }
}

struct PRepListResponse: Decodable {
    var blockHeight: BigUInt
    var startRanking: BigUInt
    var totalDelegated: BigUInt
    var totalStake: BigUInt
    var preps: [PReps]
    
    enum CodingKeys: String, CodingKey {
        case blockHeight, startRanking, totalDelegated, totalStake, preps
    }
    
    struct PReps: Decodable {
        var name: String
        var country: String
        var city: String
        var address: String
        var stake: BigUInt
        var delegated: BigUInt
        var grade: PRepGrade
        var irep: BigUInt
        var irepUpdateBlockHeight: BigUInt
        var lastGenerateBlockHeight: BigUInt?
        var totalBlocks: BigUInt
        var validatedBlocks: BigUInt
        
        enum CodingKeys: String, CodingKey {
            case name, country, city, address, stake, delegated, grade, irep, irepUpdateBlockHeight, lastGenerateBlockHeight, totalBlocks, validatedBlocks
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: PReps.CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.country = try container.decode(String.self, forKey: .country)
            self.city = try container.decode(String.self, forKey: .city)
            self.address = try container.decode(String.self, forKey: .address)
            let stakeString = try container.decode(String.self, forKey: .stake)
            guard let stake = stakeString.hexToBigUInt() else {
                throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `stake` to BigUInt"))
            }
            self.stake = stake
            
            let delegatedString = try container.decode(String.self, forKey: .delegated)
            guard let delegated = delegatedString.hexToBigUInt() else {
                throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `delegated` to BigUInt"))
            }
            self.delegated = delegated
            
            self.grade = try container.decode(PRepGrade.self, forKey: .grade)
            
            let irepString = try container.decode(String.self, forKey: .irep)
            guard let irep = irepString.hexToBigUInt() else {
                throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `irep` to BigUInt"))
            }
            self.irep = irep
            
            let irepUpdateString = try container.decode(String.self, forKey: .irepUpdateBlockHeight)
            guard let updatedBlockHeight = irepUpdateString.hexToBigUInt() else {
                throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `irepUpdateBlockHeight` to BigUInt"))
            }
            self.irepUpdateBlockHeight = updatedBlockHeight
            
            let lastBlockString = try container.decode(String.self, forKey: .lastGenerateBlockHeight)
            if let lastBlock = lastBlockString.hexToBigUInt() {
                self.lastGenerateBlockHeight = lastBlock
            } else {
                self.lastGenerateBlockHeight = nil
            }
            
            let totalString = try container.decode(String.self, forKey: .totalBlocks)
            guard let totalBlocks = totalString.hexToBigUInt() else {
                throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `totalBlocks` to BigUInt"))
            }
            self.totalBlocks = totalBlocks
            
            let validateBlockString = try container.decode(String.self, forKey: .validatedBlocks)
            guard let validateBlock = validateBlockString.hexToBigUInt() else {
                throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `validatedBlocks` to BigUInt"))
            }
            self.validatedBlocks = validateBlock
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let blockHeightString = try container.decode(String.self, forKey: .blockHeight)
        guard let blockHeight = blockHeightString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `blockHeight` to BigUInt"))
        }
        self.blockHeight = blockHeight
        
        let startString = try container.decode(String.self, forKey: .startRanking)
        guard let startRanking = startString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `startRanking` to BigUInt"))
        }
        self.startRanking = startRanking
        
        let totalString = try container.decode(String.self, forKey: .totalDelegated)
        guard let totalDelegate = totalString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `totalDelegated` to BigUInt"))
        }
        self.totalDelegated = totalDelegate
        
        let stakeString = try container.decode(String.self, forKey: .totalStake)
        guard let stake = stakeString.hexToBigUInt() else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Could not convert `totalStake` to BigUInt"))
        }
        self.totalStake = stake
        
        self.preps = try container.decode([PReps].self, forKey: .preps)
    }
}

struct MyStakeInfo {
    let stake: BigUInt
    let votingPower: BigUInt
    let iscore: BigUInt
}
