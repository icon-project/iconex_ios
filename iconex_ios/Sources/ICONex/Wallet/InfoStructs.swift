//
//  Address.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import BigInt

struct WalletInfo {
    var name: String
    var address: String
    var type: COINTYPE
    var value: BigUInt?
    
    init(name: String, address: String, type: COINTYPE) {
        self.name = name
        self.address = address
        self.type = type
    }
    
    init(model: WalletModel) {
        self.name = model.name
        self.address = model.address
        self.type = COINTYPE(rawValue: model.type)!
    }
}

class AddressBookInfo {
    var name: String
    var address: String
    var type: COINTYPE
    var createdDate: Date
    
    init(name: String, address: String, type: COINTYPE, createdDate: Date) {
        self.name = name
        self.address = address
        self.type = type
        self.createdDate = createdDate
    }
    
    convenience init(addressBook: AddressBookModel) {
        let type = COINTYPE(rawValue: addressBook.type)!
        self.init(name: addressBook.name, address: addressBook.address, type: type, createdDate: addressBook.createdDate)
    }
}


struct TransactionInfo {
    var name: String
    var address: String
    var date: Date
    var hexAmount: String
    var tokenSymbol: String?
    
    init(name: String, address: String, date: Date, hexAmount: String, tokenSymbol: String? = nil) {
        self.name = name
        self.address = address
        self.date = date
        self.hexAmount = hexAmount
        self.tokenSymbol = tokenSymbol
    }
}

class CoinInfo {
    var name: String
    var symbol: String
    var wallets: [WalletInfo]?
    
    init(name: String, shortName: String) {
        self.name = name
        self.symbol = shortName
    }
}

class TokenInfo {
    var name: String
    var defaultName: String
    var symbol: String
    var decimal: Int
    var defaultDecimal: Int
    var dependedAddress: String
    var contractAddress: String
    var parentType: String
    var createDate: Date
    var swapAddress: String?
    var needSwap: Bool {
        if self.symbol.lowercased() == "icx" {
            return true
        }
        
        return false
    }
    
    init(name: String, defaultName: String, symbol: String, decimal: Int, defaultDecimal: Int, dependedAddress: String, contractAddress: String, parentType: String) {
        self.name = name
        self.defaultName = defaultName
        self.symbol = symbol
        self.decimal = decimal
        self.defaultDecimal = defaultDecimal
        self.dependedAddress = dependedAddress
        self.contractAddress = contractAddress
        self.parentType = parentType
        self.createDate = Date()
    }
    
    convenience init(token: TokenModel) {
        self.init(name: token.name, defaultName: token.defaultName, symbol: token.symbol, decimal: token.decimal, defaultDecimal: token.defaultDecimal, dependedAddress: token.dependedAddress, contractAddress: token.contractAddress, parentType: token.parentType)
        self.createDate = token.createdDate
        self.swapAddress = token.swapAddress
    }
}
