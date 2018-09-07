//
//  Database.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import RealmSwift
import ICONKit

class TokenModel: Object {
    @objc dynamic var id = 0
    @objc dynamic var name = ""
    @objc dynamic var defaultName = ""
    @objc dynamic var dependedAddress: String = ""
    @objc dynamic var contractAddress: String = ""
    @objc dynamic var parentType: String = ""
    @objc dynamic var symbol: String = ""
    @objc dynamic var decimal: Int = 0
    @objc dynamic var defaultDecimal: Int = 0
    @objc dynamic var createdDate: Date = Date()
    @objc dynamic var swapAddress: String? = nil
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class WalletModel: Object {
    @objc dynamic var id = 0
    @objc dynamic var name: String = ""
    @objc dynamic var type: String = ""
    @objc dynamic var address: String = ""
    @objc dynamic var createdDate: Date = Date()
    @objc dynamic var rawData: Data? = nil
    let tokens = List<TokenModel>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class TransactionModel: Object {
    @objc dynamic var id = 0
    @objc dynamic var txHash: String = ""
    @objc dynamic var from: String = ""
    @objc dynamic var to: String = ""
    @objc dynamic var date: Date = Date()
    @objc dynamic var type: String = ""
    @objc dynamic var value: String = ""
    @objc dynamic var completed: Bool = false
    @objc dynamic var tokenSymbol: String?
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class AddressBookModel: Object {
    @objc dynamic var id = 0
    @objc dynamic var name: String = ""
    @objc dynamic var address: String = ""
    @objc dynamic var type: String = ""
    @objc dynamic var createdDate: Date = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class TokenListModel: Object {
    @objc dynamic var id = 0
    @objc dynamic var address: String = ""
    @objc dynamic var symbol: String = ""
    @objc dynamic var decimal: Int = 0
    @objc dynamic var type: String = "default"
}

struct DB {
    // Wallet
    static func walletTypes() -> [String] {
        let realm = try! Realm()
        
        let list = realm.objects(WalletModel.self).value(forKeyPath: "@distinctUnionOfObjects.type") as! [String]
        
        return list
    }
    
    static func saveWallet(name: String, address: String, type: String, rawData: Data?) throws {
        let realm = try Realm()
        
        guard realm.objects(WalletModel.self).filter({ $0.address == address }).first == nil else {
            throw IXError.duplicateAddress
        }
        guard realm.objects(WalletModel.self).filter({ $0.name == name }).first == nil else {
            throw IXError.duplicateName
        }
        
        let wallet = WalletModel()
        wallet.name = name
        wallet.address = address
        wallet.type = type
        wallet.rawData = rawData
        
        if let maxID = realm.objects(WalletModel.self).max(ofProperty: "id") as Int? {
            wallet.id = maxID + 1
        }
        
        try realm.write {
            realm.add(wallet)
        }
    }
    
    static func changeWalletName(former: String, newName: String) throws -> Bool {
        let realm = try Realm()
        
        guard let wallet = realm.objects(WalletModel.self).filter({ $0.name == former }).first else {
            return false
        }
        
        try realm.write {
            wallet.name = newName
        }
        
        return true
    }
    
    static func changeWalletPassword(wallet: BaseWalletConvertible,oldPassword: String, newPassword: String) throws -> Bool {
        let realm = try Realm()
        
        guard let walletModel = realm.objects(WalletModel.self).filter({ $0.name == wallet.alias! }).first else {
            return false
        }
        
        if wallet.type == .icx {
            let icx = wallet as! ICXWallet
            try icx.changePassword(old: oldPassword, new: newPassword)
            
            try realm.write {
                walletModel.rawData = icx.__rawData
            }
        } else if wallet.type == .eth {
            let eth = wallet as! ETHWallet
            try eth.changePassword(oldPassword: oldPassword, newPassword: newPassword)
            
            try realm.write {
                walletModel.rawData = eth.__rawData
            }
        }
        
        return true
    }
    
    static func deleteWallet(wallet: BaseWalletConvertible) throws -> Bool {
        let realm = try Realm()
        
        guard let walletModel = realm.objects(WalletModel.self).filter({ $0.name == wallet.alias! }).first else {
            return false
        }
        
        try realm.write {
            realm.delete(walletModel)
        }
        
        let tokenList = realm.objects(TokenModel.self).filter({ $0.dependedAddress == wallet.address! })
        
        for token in tokenList {
            try realm.write {
                realm.delete(token)
            }
        }
        
        return true
    }
    
    static func findWalletName(with: TransactionModel, exclude: String) -> String? {
        let realm = try! Realm()
        
        guard let wallet = realm.objects(WalletModel.self).filter({ ($0.address == with.from || $0.address == with.to) && $0.address.lowercased() != exclude.lowercased() }).first else {
            return nil
        }
        
        return wallet.name
    }
    
    static func walletListBy(coin: COINTYPE) -> CoinInfo? {
        let realm = try! Realm()
        
        let list = realm.objects(WalletModel.self).filter({ $0.type == coin.rawValue })
        
        if list.count == 0 { return nil }
        
        var name = ""
        
        switch coin {
        case .icx:
            name = "ICON"
            
        case .eth:
            name = "Ethereum"
            
        default:
            break
        }
        
        let info = CoinInfo(name: name, shortName: coin.rawValue.uppercased())
        var walletList = [WalletInfo]()
        
        for model in list {
            var wallet = WalletInfo(name: model.name, address: model.address, type: coin)
            wallet.value = WManager.walletBalanceList[model.address]
            walletList.append(wallet)
        }
        
        info.wallets = walletList
        
        return info
    }
    
    static func walletListBy(token: TokenInfo) -> CoinInfo? {
        let realm = try! Realm()
        
        let list = realm.objects(TokenModel.self).filter({ $0.contractAddress == token.contractAddress })
        var result = [WalletInfo]()
        for model in list {
            let walletList = realm.objects(WalletModel.self).filter({ $0.address == model.dependedAddress })
            for walletModel in walletList {
                let walletInfo = WalletInfo(name: walletModel.name, address: walletModel.address, type: COINTYPE(rawValue: walletModel.type)!)
                result.append(walletInfo)
            }
        }
        let info = CoinInfo(name: token.name, shortName: token.symbol)
        info.wallets = result
        
        return info
//        let list = realm.objects(WalletModel.self).filter({ $0.tokens.count > 0 })
//        var walletList = [WalletInfo]()
//        for model in list {
//            if model.tokens.filter({ $0.symbol == token.symbol }).count > 0 {
//                let wallet = WalletInfo(name: model.name, address: model.address, type: COINTYPE(rawValue: model.type)!)
//                walletList.append(wallet)
//            }
//        }
//
//        let info = CoinInfo(name: token.name, shortName: token.symbol)
//        info.wallets = walletList
//
//        return info
    }
    
    static func walletBy(info: WalletInfo) -> BaseWalletConvertible? {
        return walletBy(address: info.address, type: info.type)
    }
    
    static func walletBy(address: String, type: COINTYPE) -> BaseWalletConvertible? {
        do {
            let realm = try Realm()
            
            guard let model = realm.objects(WalletModel.self).filter({ $0.type == type.rawValue.lowercased() && $0.address == address }).first else { return nil }
            
            if type == .icx {
                guard let icx = ICXWallet(alias: model.name, from: model.rawData!) else { return nil }
                icx.createdDate = model.createdDate
                return icx
            } else {
                let eth = ETHWallet(alias: model.name, from: model.rawData!)
                eth.createdDate = model.createdDate
                
                let modelList = try Ethereum.tokenList(dependedAddress: eth.address!)
                
                eth.tokens = modelList
                
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
        Log.Debug("expireDate \(expireDate)")
        
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
    
    static func saveAddressBook(name: String, address: String, type: COINTYPE) throws {
        let realm = try Realm()
        
        let addressBook = AddressBookModel()
        addressBook.name = name
        addressBook.address = address
        addressBook.type = type.rawValue
        
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
            throw IXError.noAddressInfo
        }
        
        try realm.write {
            info.name = newName
        }
    }
    
    static func addressBookList(by: COINTYPE) throws -> [AddressBookModel] {
        let realm = try Realm()
        
        let list = realm.objects(AddressBookModel.self).sorted(byKeyPath: "createdDate").filter({ $0.type == by.rawValue })
        
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
    static func allTokenList() -> [TokenInfo] {
        let realm = try! Realm()
        
        let tokenList = realm.objects(TokenModel.self)
        var dic = [String: TokenInfo]()
        for token in tokenList {
            let info = TokenInfo(token: token)
            dic[token.symbol] = info
        }
        
        return Array(dic.values)
    }
    
    static func tokenList(dependedAddress: String) throws -> [TokenModel] {
        let realm = try Realm()
        
        let list = realm.objects(TokenModel.self).sorted(byKeyPath: "id").filter({ $0.dependedAddress == dependedAddress })
        
        return Array(list)
    }
    
    static func tokenListBy(symbol: String) -> [TokenModel] {
        let realm = try! Realm()
        
        let list = realm.objects(TokenModel.self).filter({ $0.symbol == symbol })
        
        return Array(list)
    }
    
    static func addToken(tokenInfo: TokenInfo) throws {
        let realm = try Realm()
        
        let token = TokenModel()
        
        if let maxID = realm.objects(TokenModel.self).max(ofProperty: "id") as Int? {
            token.id = maxID + 1
        }
        
        token.name = tokenInfo.name
        token.contractAddress = tokenInfo.contractAddress
        token.decimal = tokenInfo.decimal
        token.dependedAddress = tokenInfo.dependedAddress
        token.defaultDecimal = tokenInfo.defaultDecimal
        token.parentType = tokenInfo.parentType
        token.symbol = tokenInfo.symbol
        token.swapAddress = tokenInfo.swapAddress
        
        try realm.write {
            realm.add(token)
        }
    }
    
    static func modifyToken(tokenInfo: TokenInfo) throws {
        let realm = try Realm()
        
        guard let model = realm.objects(TokenModel.self).filter( "contractAddress = %@ and dependedAddress = %@", tokenInfo.contractAddress, tokenInfo.dependedAddress).first else { throw IXError.invalidTokenInfo }
        
//        Log.Debug("depended: \(tokenInfo.dependedAddress)")
//        let list = Array(realm.objects(TokenModel.self))
//        Log.Debug("origin: \(list)")
//        let modelList = list.filter({ $0.dependedAddress == tokenInfo.dependedAddress && $0.contractAddress == tokenInfo.contractAddress })
//        Log.Debug("filtered: \(modelList)")
//        if modelList.count == 0 { throw IXError.invalidTokenInfo }
//        let model = modelList[0]
        
        let token = TokenModel()
        token.id = model.id
        token.name = tokenInfo.name
        token.contractAddress = tokenInfo.contractAddress
        token.decimal = tokenInfo.decimal
        token.dependedAddress = tokenInfo.dependedAddress
        token.defaultDecimal = tokenInfo.defaultDecimal
        token.parentType = tokenInfo.parentType
        token.symbol = tokenInfo.symbol
        token.swapAddress = tokenInfo.swapAddress
        
        try realm.write {
            
            realm.add(token, update: true)
            
        }
    }
    
    static func removeToken(tokenInfo: TokenInfo) throws {
        let realm = try Realm()
        
        guard let token = realm.objects(TokenModel.self).filter({ $0.name == tokenInfo.name }).first else {
            return
        }
        
        try realm.write {
            realm.delete(token)
        }
    }
    
    // ETH Token list
    static func importLocalTokenList() {
        DispatchQueue.global(qos: .background).async {
            do {
                let realm = try Realm()
                
                guard realm.objects(TokenListModel.self).first == nil else { return }
                guard let filePath = Bundle.main.path(forResource: "ethToken", ofType: "json") else { return }
                guard let data = FileManager.default.contents(atPath: filePath) else { return }
                
                let decoder = JSONDecoder()
                
                let list = try decoder.decode([TokenListInfo].self, from: data)
                
                var id = 0
                for token in list {
                    let model = TokenListModel()
                    model.id = id
                    model.address = token.address
                    model.symbol = token.symbol
                    model.type = token.type
                    model.decimal = token.decimal
                    try realm.write {
                        realm.add(model)
                    }
                    id += 1
                }
                
            } catch {
                Log.Debug("error: \(error)")
            }
        }
    }
    
    static func localTokenList() {
        do {
            let realm = try Realm()
            
            let list = realm.objects(TokenListModel.self)
            
            for tokenInfo in list {
                Log.Debug("name: \(tokenInfo.symbol)")
            }
        } catch {
            Log.Debug("error \(error)")
        }
    }
    
    static func findToken(_ address: String) -> TokenListInfo? {
        do {
            let realm = try Realm()
            
            guard let model = realm.objects(TokenListModel.self).filter({ $0.address.lowercased() == address.lowercased() }).first else { return nil }
            
            let info = TokenListInfo(symbol: model.symbol, address: model.address, decimal: model.decimal, type: model.type)
            return info                                   
        } catch {
            Log.Debug("error \(error)")
        }
        
        return nil
    }
}

