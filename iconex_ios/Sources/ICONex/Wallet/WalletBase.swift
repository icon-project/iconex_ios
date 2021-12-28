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
    var tokens: [Token]? { get set }
    var created: Date { get set }
    var keystore: ICONKeystore { get set }
    
    var address: String { get }
    var decimal: Int { get }
    var balance: BigUInt? { get }
    var rawData: Data { get }
}

//class BaseWallet: BaseWalletConvertible {
extension BaseWalletConvertible {
    var address: String {
        return keystore.address
    }
    var decimal: Int { return 18 }
    var balance: BigUInt? {
        return Manager.balance.getBalance(wallet: self)
    }
    var rawData: Data {
        let encoder = JSONEncoder()
        return try! encoder.encode(keystore)
    }
}

extension BaseWalletConvertible {
    func canSave(name: String) -> Bool {
        return DB.canSaveWallet(name: name)
    }
    
    func canSave() throws {
        guard DB.canSaveWallet(name: name) else { throw CommonError.duplicateName }
    }
    
    func save() throws {
        try DB.saveWallet(name: name.removeContinuosCharacter(string: " "), address: address, type: address.hasPrefix("hx") ? "icx" : "eth", rawData: rawData)
        if let tokens = self.tokens {
            for token in tokens {
                try addToken(token: token)
            }
        }
    }
    
    func changeName(older: String, newer: String) throws {
        try DB.changeWalletName(former: older, newName: newer)
    }
    
    func delete() throws {
        try DB.deleteWallet(wallet: self)
    }
    
    func canSaveToken(contractAddress: String) -> Bool {
        guard let tokenList = tokens else { return true }
        return tokenList.filter { $0.contract == contractAddress }.count == 0
    }
    
    func addToken(token: Token) throws {
        try DB.addToken(tokenInfo: token)
    }
    
    func addToken(token: NewToken) throws {
        try DB.addToken(tokenInfo: token)
    }
    
    func deleteToken(token: Token) throws {
        try DB.removeToken(tokenInfo: token)
    }
    
    func modifyToken(token: Token) throws {
        try DB.modifyToken(tokenInfo: token)
    }
}
