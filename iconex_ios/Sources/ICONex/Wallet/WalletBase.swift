//
//  WalletBase.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import Foundation
import BigInt

enum COINTYPE: String {
    case icx = "icx"
    case eth = "eth"
    case unknown = "unknown"
}

protocol BaseWalletConvertible {
    
    var alias: String? { get set }
    var address: String? { get set }
    var __rawData: Data? { get set }
    var type: COINTYPE { get set }
    var balance: BigUInt? { get set }
    var decimal: Int { get set }
    var createdDate: Date? { get set }
    var tokens: [TokenInfo]? { get set }
}

class BaseWallet: BaseWalletConvertible {
    var decimal: Int = 18
    var alias: String?
    var address: String?
    var __rawData: Data?
    var type: COINTYPE = .unknown
    var balance: BigUInt?
    var createdDate: Date?
    var tokens: [TokenInfo]?
    
    init() {
        self.type = .unknown
    }
    
    init(type: COINTYPE) {
        self.type = type
    }
    
    /// alias 명의 지갑 생성
    ///
    /// - Parameter alias: 지갑 이름
    convenience init(alias: String, type: COINTYPE) {
        self.init()
        self.alias = alias
        self.type = type
    }
    
    convenience init(alias: String, from: Data, type: COINTYPE) {
        self.init()
        self.alias = alias
        self.__rawData = from
        self.type = type
    }
    
    /// PrivateKey 생성
    ///
    /// - Returns: Private Key
    func generatePrivateKey() -> String {
        return ICONUtil.generatePrivateKey()
    }
}
