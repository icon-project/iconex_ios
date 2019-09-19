//
//  Database.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import RealmSwift
import ICONKit

struct DB {
    // Wallet
    static func loadWallets() -> [BaseWalletConvertible] {
        let realm = try! Realm()
        
        let list = realm.objects(WalletModel.self).sorted(byKeyPath: "createdDate")
        
        var walletList = [BaseWalletConvertible]()
        for walletModel in list {
            var wallet: BaseWalletConvertible
            if walletModel.type == "icx" {
                wallet = ICXWallet(model: walletModel)
            } else {
                wallet = ETHWallet(model: walletModel)
            }
            walletList.append(wallet)
        }
        
        return walletList
    }
    
    static func loadMyWallets(address: String, type: String) -> [BaseWalletConvertible] {
        let realm = try! Realm()
        
        let list = realm.objects(WalletModel.self).sorted(byKeyPath: "createdDate").filter({ $0.type == type }).filter({ $0.address.add0xPrefix() != address.add0xPrefix() })
        
        var walletList = [BaseWalletConvertible]()
        for walletModel in list {
            var wallet: BaseWalletConvertible
            if walletModel.type == "icx" {
                wallet = ICXWallet(model: walletModel)
            } else {
                wallet = ETHWallet(model: walletModel)
            }
            walletList.append(wallet)
        }
        
        return walletList
    }
    
    
    static func walletTypes() -> [String] {
        let realm = try! Realm()
        
        var sorted = [String]()
        
        var list = realm.objects(WalletModel.self).value(forKeyPath: "@distinctUnionOfObjects.type") as! [String]
        
        if let icx = list.enumerated().filter({ $0.element.lowercased() == "icx" }).first {
            sorted.append(icx.element)
            list.remove(at: icx.offset)
        }
        
        if let eth = list.enumerated().filter({ $0.element.lowercased() == "eth" }).first {
            sorted.append(eth.element)
            list.remove(at: eth.offset)
        }
        
        sorted.append(contentsOf: list)
        
        return sorted
    }
    
    static func canSaveWallet(name: String) -> Bool {
        let realm = try! Realm()
        
        let list = realm.objects(WalletModel.self).filter { $0.name == name }
        
        if list.count > 0 {
            return false
        }
        
        return true
    }
    
    static func saveWallet(name: String, address: String, type: String, rawData: Data?) throws {
        let realm = try Realm()
        
        let dupAddr = realm.objects(WalletModel.self).filter({ $0.address.add0xPrefix() == address.add0xPrefix() })
        
        if dupAddr.count > 0 {
            try realm.write {
                realm.delete(dupAddr)
            }
        }
        
        let wallet = WalletModel()
        wallet.name = name
        wallet.address = address.add0xPrefix()
        wallet.type = type
        wallet.rawData = rawData
        
        if let maxID = realm.objects(WalletModel.self).max(ofProperty: "id") as Int? {
            wallet.id = maxID + 1
        }
        
        try realm.write {
            realm.add(wallet)
        }
    }
    
    static func changeWalletName(former: String, newName: String) throws {
        let realm = try Realm()
        
        guard let wallet = realm.objects(WalletModel.self).filter({ $0.name == former }).first else {
            throw CommonError.duplicateName
        }
        
        try realm.write {
            wallet.name = newName
        }
    }
    
    static func changeWalletPassword(wallet: BaseWalletConvertible,oldPassword: String, newPassword: String) throws {
        let realm = try Realm()
        
        guard let walletModel = realm.objects(WalletModel.self).filter({ $0.name == wallet.name }).first else {
            throw WalletError.noWallet(wallet.name)
        }
        
        if let icx = wallet as? ICXWallet {
            try icx.changePassword(oldPassword: oldPassword, newPassword: newPassword)
            
            try realm.write {
                walletModel.rawData = icx.rawData
            }
        } else if let eth = wallet as? ETHWallet {
            try eth.changePassword(oldPassword: oldPassword, newPassword: newPassword)
            
            try realm.write {
                walletModel.rawData = eth.rawData
            }
        }
    }
    
    static func deleteWallet(wallet: BaseWalletConvertible) throws {
        let realm = try Realm()
        
        guard let walletModel = realm.objects(WalletModel.self).filter({ $0.name == wallet.name }).first else {
            throw WalletError.noWallet(wallet.name)
        }
        
        try realm.write {
            realm.delete(walletModel)
        }
        
        let tokenList = try DB.tokenList(dependedAddress: wallet.address.add0xPrefix())
        
        for token in tokenList {
            try DB.removeToken(tokenInfo: token)
        }
    }
    
    static func findWalletName(with: TransactionModel, exclude: String) -> String? {
        let realm = try! Realm()
        
        guard let wallet = realm.objects(WalletModel.self).filter({ ($0.address == with.from || $0.address == with.to) && $0.address.lowercased() != exclude.lowercased() }).first else {
            return nil
        }
        
        return wallet.name
    }
    
    static func walletListBy(type: String) -> [BaseWalletConvertible]? {
        let realm = try! Realm()
        
        let list = realm.objects(WalletModel.self).filter({ $0.type == type })
        
        if list.count == 0 { return nil }
        
        var walletList = [BaseWalletConvertible]()
        
        for model in list {
            
            if model.type == "icx", let wallet = ICXWallet(name: model.name, rawData: model.rawData!, created: model.createdDate) {
                walletList.append(wallet)
            } else if let wallet = ETHWallet(name: model.name, rawData: model.rawData!, created: model.createdDate) {
                walletList.append(wallet)
            }
        }
        
        return walletList
    }
    
    static func walletListBy(token: Token) -> [BaseWalletConvertible]? {
        let realm = try! Realm()
        
        let list = realm.objects(TokenModel.self).filter({ $0.contractAddress == token.contract })
        var result = [BaseWalletConvertible]()
        for model in list {
            let walletList = realm.objects(WalletModel.self).filter({ $0.address == model.dependedAddress })
            for walletModel in walletList {
                var wallet: BaseWalletConvertible
                if walletModel.type == "icx" {
                    wallet = ICXWallet(model: walletModel)
                } else {
                    wallet = ETHWallet(model: walletModel)
                }
                result.append(wallet)
            }
        }

        return result
    }
    
    static func walletBy(address: String, type: String) -> BaseWalletConvertible? {
        do {
            let realm = try Realm()
            
            guard let model = realm.objects(WalletModel.self).filter({ $0.type == type.lowercased() && $0.address.lowercased() == address.lowercased() }).first else { return nil }
            
            if type == "icx" {
                let icx = ICXWallet(model: model)
                
                return icx
            } else {
                let eth = ETHWallet(model: model)
                
                return eth
            }
        } catch {
            return nil
        }
    }
    
    // MARK: Transaction
    
    static func saveTransaction(from: String, to: String, txHash: String, value: String, type: String, tokenSymbol: String? = nil) throws {
        let realm = try Realm()
        
        let transaction = TransactionModel()
        transaction.from = from
        transaction.to = to
        transaction.txHash = txHash
        transaction.type = type
        transaction.value = value
        transaction.tokenSymbol = tokenSymbol
        
        if let maxID = realm.objects(TransactionModel.self).max(ofProperty: "id") as Int? {
            transaction.id = maxID + 1
        }
        
        try realm.write {
            realm.add(transaction)
        }
    }
    
    static func transactionList(address: String) -> [TransactionModel]? {
        let realm = try! Realm()
        
        let expireDate = Date().timeIntervalSince1970
        Log("expireDate - \(expireDate)")
        
        let lists = realm.objects(TransactionModel.self).sorted(byKeyPath: "date").reversed().filter({ $0.from == address && $0.completed == false && $0.date.timeIntervalSince1970 > Date().timeIntervalSince1970 - (60 * 2)})
        
        return lists.count > 0 ? Array(lists) : nil
    }
    
    static func transactionList(type: String) -> [TransactionModel]? {
        let realm = try! Realm()
        
        let lists = realm.objects(TransactionModel.self).sorted(byKeyPath: "date").reversed().filter({ $0.type == type })
        
        return lists.count > 0 ? Array(lists) : nil
    }
    
    static func updateTransactionCompleted(txHash: String) {
        let realm = try! Realm()
        
        guard let transaction = realm.objects(TransactionModel.self).filter({ $0.txHash == txHash && $0.completed == false }).first else {
            return
        }
        
        try! realm.write {
            transaction.completed = true
        }
    }
    
    
    // MARK: AddressBook
    static func canSaveAddressBook(name: String) -> Bool {
        let realm = try! Realm()
        guard let _ = realm.objects(AddressBookModel.self).filter({ $0.name == name }).first else {
            return true
        }
        
        return false
    }
    
    static func canSaveAddressBook(address: String) -> Bool {
        let realm = try! Realm()
        guard let _ = realm.objects(AddressBookModel.self).filter({ $0.address == address }).first else {
            return true
        }
        
        return false
    }
    
    static func saveAddressBook(name: String, address: String, type: String) throws {
        let realm = try Realm()
        
        let addressBook = AddressBookModel()
        addressBook.name = name
        addressBook.address = address
        addressBook.type = type
        
        if let maxID = realm.objects(AddressBookModel.self).max(ofProperty: "id") as Int? {
            addressBook.id = maxID + 1
        }
        
        try realm.write {
            realm.add(addressBook)
        }
    }
    
    static func modifyAddressBook(oldName: String, newName: String) throws {
        let realm = try Realm()
        
        guard let info = realm.objects(AddressBookModel.self).filter({ $0.name == oldName }).first else {
            throw WalletError.noWallet(oldName)
        }
        
        try realm.write {
            info.name = newName
        }
    }
    
    static func addressBookList(by: String) throws -> [AddressBookModel] {
        let realm = try Realm()
        
        let list = realm.objects(AddressBookModel.self).sorted(byKeyPath: "createdDate").filter({ $0.type == by })
        
        return Array(list)
    }
    
    static func deleteAddressBook(name: String) throws {
        let realm = try Realm()
        
        guard let item = realm.objects(AddressBookModel.self).filter({ $0.name == name }).first else {
            return
        }
        
        try realm.write {
            realm.delete(item)
        }
    }
    
    // MARK: Token
    static func allTokenList() -> [Token] {
        let realm = try! Realm()
        
        let tokenList = realm.objects(TokenModel.self)
        var dic = [String: Token]()
        for token in tokenList {
            let info = Token(model: token)
            dic[token.symbol] = info
        }
        
        return Array(dic.values)
    }
    
    static func tokenList(dependedAddress: String) throws -> [Token] {
        let realm = try Realm()
        
        let list = realm.objects(TokenModel.self).sorted(byKeyPath: "id").filter({ $0.dependedAddress.add0xPrefix().lowercased() == dependedAddress.add0xPrefix().lowercased() })
        
        var infoList = [Token]()
        for model in list {
            let info = Token(model: model)
            infoList.append(info)
        }
        
        return infoList
    }
    
    static func tokenListBy(symbol: String) -> [TokenModel] {
        let realm = try! Realm()
        
        let list = realm.objects(TokenModel.self).filter({ $0.symbol == symbol })
        
        return Array(list)
    }
    
    static func addToken(tokenInfo: Token) throws {
        let realm = try Realm()
        
        let exist = realm.objects(TokenModel.self).filter({ $0.dependedAddress == tokenInfo.parent && $0.contractAddress == tokenInfo.contract })
        
        for item in exist {
            try realm.write {
                realm.delete(item)
            }
        }
        
        let token = TokenModel()
        
        if let maxID = realm.objects(TokenModel.self).max(ofProperty: "id") as Int? {
            token.id = maxID + 1
        }
        
        token.name = tokenInfo.name
        token.contractAddress = tokenInfo.parent.hasPrefix("hx") ? tokenInfo.contract.lowercased() : tokenInfo.contract.add0xPrefix().lowercased()
        token.decimal = tokenInfo.decimal
        token.dependedAddress = tokenInfo.parent.add0xPrefix().lowercased()
        token.defaultDecimal = tokenInfo.decimal
        token.parentType = tokenInfo.parentType
        token.symbol = tokenInfo.symbol
        
        try realm.write {
            realm.add(token)
        }
    }
    
    static func canSaveToken(depended: String, contract: String) -> Bool {
        let realm = try! Realm()
        guard let _ = realm.objects(TokenModel.self).filter({ $0.contractAddress == contract && $0.dependedAddress.add0xPrefix() == depended.add0xPrefix() }).first else {
            return true
        }
        
        return false
    }
    
    static func addToken(tokenInfo: NewToken) throws {
        let realm = try Realm()

        let exist = realm.objects(TokenModel.self).filter({ $0.dependedAddress == tokenInfo.parent && $0.contractAddress == tokenInfo.contract })
        
        for item in exist {
            try realm.write {
                realm.delete(item)
            }
        }
        
        let token = TokenModel()

        if let maxID = realm.objects(TokenModel.self).max(ofProperty: "id") as Int? {
            token.id = maxID + 1
        }

        token.name = tokenInfo.name
        token.contractAddress = tokenInfo.parent.hasPrefix("hx") ? tokenInfo.contract.lowercased() : tokenInfo.contract.add0xPrefix().lowercased()
        token.decimal = tokenInfo.decimal
        token.dependedAddress = tokenInfo.parent.add0xPrefix().lowercased()
        token.defaultDecimal = tokenInfo.decimal
        token.parentType = tokenInfo.parentType
        token.symbol = tokenInfo.symbol

        try realm.write {
            realm.add(token)
        }
    }
    
    static func modifyToken(tokenInfo: Token) throws {
        let realm = try Realm()
        let contract = tokenInfo.parent.hasPrefix("hx") ? tokenInfo.contract.lowercased() : tokenInfo.contract.add0xPrefix().lowercased()
        
        guard let model = realm.objects(TokenModel.self).filter( "contractAddress = %@ and dependedAddress = %@", contract, tokenInfo.parent).first else {
            throw WalletError.noToken(tokenInfo.name)
        }
        
        let token = TokenModel()
        token.id = model.id
        token.name = tokenInfo.name
        token.contractAddress = contract
        token.decimal = tokenInfo.decimal
        token.dependedAddress = tokenInfo.parent.add0xPrefix().lowercased()
        token.defaultDecimal = tokenInfo.decimal
        token.parentType = tokenInfo.parentType
        token.symbol = tokenInfo.symbol
        
        try realm.write {
            
            realm.add(token, update: true)
            
        }
    }
    
    static func removeToken(tokenInfo: Token) throws {
        let realm = try Realm()
        
        let token = realm.objects(TokenModel.self).filter({ $0.dependedAddress == tokenInfo.parent && $0.contractAddress == tokenInfo.contract })
        
        try realm.write {
            realm.delete(token)
        }
    }
}

