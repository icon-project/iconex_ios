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
    var tokens: [Token]? { get }
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
        return nil
    }
    var rawData: Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        return try! encoder.encode(keystore)
    }
}

extension BaseWalletConvertible {
    func canSave(name: String) -> Bool {
        return DB.canSaveWallet(name: name)
    }
    
    func canSave(address: String) -> Bool {
        return DB.canSaveWallet(address: address)
    }
    
    func canSave() throws {
        guard DB.canSaveWallet(name: name) else { throw CommonError.duplicateName }
        guard DB.canSaveWallet(address: address) else { throw CommonError.duplicateAddress }
    }
    
    func save() throws {
        guard DB.canSaveWallet(name: name) else { throw CommonError.duplicateName }
        guard DB.canSaveWallet(address: address) else { throw CommonError.duplicateAddress }
        try DB.saveWallet(name: name, address: address, type: address.hasPrefix("0x") ? "eth" : "icx", rawData: rawData)
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
    
    func saveToken(token: Token) throws {
        try DB.addToken(tokenInfo: token)
    }
    
    func deleteToken(token: Token) throws {
        try DB.removeToken(tokenInfo: token)
    }
    
    func modifyToken(token: Token) throws {
        try DB.modifyToken(tokenInfo: token)
    }
}
