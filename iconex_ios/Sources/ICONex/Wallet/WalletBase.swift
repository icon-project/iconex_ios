//
//  WalletBase.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import BigInt

protocol BaseWalletConvertible {
    var name: String { get set }
    var address: String { get }
    var decimal: Int { get set }
    var tokens: [Token]? { get set }
    var created: Date { get set }
    var balance: BigUInt? { get }
    var keystore: ICONKeystore { get set }
    var rawData: Data { get }
}

class BaseWallet: BaseWalletConvertible {
    var name: String
    var address: String {
        return keystore.address
    }
    var decimal: Int = 18
    var balance: BigUInt? {
        return BalanceManager.shared.walletBalanceList[address]
    }
    var created: Date
    var tokens: [Token]?
    var keystore: ICONKeystore
    var rawData: Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        return try! encoder.encode(keystore)
    }
    
    init(name: String, keystore: ICONKeystore, created: Date = Date()) {
        self.name = name
        self.keystore = keystore
        self.created = created
    }
    
    init?(name: String, rawData: Data, created: Date = Date()) {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let keystore = try? decoder.decode(ICONKeystore.self, from: rawData) else { return nil }
        
        self.name = name
        self.keystore = keystore
        self.created = created
    }
    
    /// PrivateKey 생성
    ///
    /// - Returns: Private Key
    func generatePrivateKey() -> String {
        return ICONUtil.generatePrivateKey()
    }
}
