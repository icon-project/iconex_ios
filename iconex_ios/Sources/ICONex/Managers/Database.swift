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
    
    static func canSaveWallet(address: String) -> Bool {
        let realm = try! Realm()
        
        let wallet = realm.objects(WalletModel.self).filter( { $0.address.lowercased() == address.lowercased() })
        if wallet.count > 0 {
            return false
        }
        
        return true
    }
    
    static func saveWallet(name: String, address: String, type: String, rawData: Data?) throws {
        let realm = try Realm()
        
        guard realm.objects(WalletModel.self).filter({ $0.address == address }).first == nil else {
            throw CommonError.duplicateAddress
        }
        guard realm.objects(WalletModel.self).filter({ $0.name == name }).first == nil else {
            throw CommonError.duplicateName
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
            try icx.changePassword(old: oldPassword, new: newPassword)
            
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
    
    static func walletListBy(type: String) -> CoinInfo? {
        let realm = try! Realm()
        
        let list = realm.objects(WalletModel.self).filter({ $0.type == type })
        
        if list.count == 0 { return nil }
        
        var name = ""
        
        switch type {
        case "icx":
            name = "ICON"
            
        case "eth":
            name = "Ethereum"
            
        default:
            break
        }
        
        let info = CoinInfo(name: name, shortName: coin.rawValue.uppercased())
        var walletList = [WalletInfo]()
        
        for model in list {
            var wallet = WalletInfo(name: model.name, address: model.address, type: coin)
            wallet.value = Balance.walletBalanceList[model.address]
            walletList.append(wallet)
        }
        
        info.wallets = walletList
        
        return info
    }
    
    static func walletListBy(token: Token) -> CoinInfo? {
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
    
    static func walletBy(address: String, type: String) -> BaseWalletConvertible? {
        do {
            let realm = try Realm()
            
            guard let model = realm.objects(WalletModel.self).filter({ $0.type == type.lowercased() && $0.address.lowercased() == address.lowercased() }).first else { return nil }
            
            if type == "icx" {
                guard let icx = ICXWallet(name: model.name, from: model.rawData!) else { return nil }
                icx.created = model.createdDate
                
                let modelList = try DB.tokenList(dependedAddress: address)
                
                icx.tokens = modelList
                
                return icx
            } else {
                let eth = ETHWallet(name: model.name, from: model.rawData!)!
                eth.created = model.createdDate
                
                let modelList = try DB.tokenList(dependedAddress: address)
                
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
            let info = Token(token: token)
            dic[token.symbol] = info
        }
        
        return Array(dic.values)
    }
    
    static func tokenList(dependedAddress: String) throws -> [Token] {
        let realm = try Realm()
        
        let list = realm.objects(TokenModel.self).sorted(byKeyPath: "id").filter({ $0.dependedAddress.lowercased() == dependedAddress.lowercased() })
        
        var infoList = [Token]()
        for model in list {
            let info = Token(token: model)
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
        
        let token = TokenModel()
        
        if let maxID = realm.objects(TokenModel.self).max(ofProperty: "id") as Int? {
            token.id = maxID + 1
        }
        
        token.name = tokenInfo.name
        token.contractAddress = tokenInfo.dependedAddress.hasPrefix("hx") ? tokenInfo.contractAddress.lowercased() : tokenInfo.contractAddress.add0xPrefix().lowercased()
        token.decimal = tokenInfo.decimal
        token.dependedAddress = tokenInfo.dependedAddress.add0xPrefix().lowercased()
        token.defaultDecimal = tokenInfo.defaultDecimal
        token.parentType = tokenInfo.parentType
        token.symbol = tokenInfo.symbol
        token.swapAddress = tokenInfo.swapAddress
        
        try realm.write {
            realm.add(token)
        }
    }
    
    static func modifyToken(tokenInfo: Token) throws {
        let realm = try Realm()
        Log("token - \(tokenInfo.contractAddress) , \(tokenInfo.dependedAddress)")
        let contract = tokenInfo.dependedAddress.hasPrefix("hx") ? tokenInfo.contractAddress.lowercased() : tokenInfo.contractAddress.add0xPrefix().lowercased()
        
        guard let model = realm.objects(TokenModel.self).filter( "contractAddress = %@ and dependedAddress = %@", contract, tokenInfo.dependedAddress).first else {
            Log("contract - \(contract) , depeded - \(tokenInfo.dependedAddress)")
            throw IXError.invalidTokenInfo }
        
        let token = TokenModel()
        token.id = model.id
        token.name = tokenInfo.name
        token.contractAddress = contract
        token.decimal = tokenInfo.decimal
        token.dependedAddress = tokenInfo.dependedAddress.add0xPrefix().lowercased()
        token.defaultDecimal = tokenInfo.defaultDecimal
        token.parentType = tokenInfo.parentType
        token.symbol = tokenInfo.symbol
        token.swapAddress = tokenInfo.swapAddress
        
        try realm.write {
            
            realm.add(token, update: true)
            
        }
    }
    
    static func removeToken(tokenInfo: Token) throws {
        let realm = try Realm()
        
        let token = realm.objects(TokenModel.self).filter({ $0.dependedAddress == tokenInfo.dependedAddress && $0.contractAddress == tokenInfo.contractAddress })
        
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
                    model.address = token.address.add0xPrefix()
                    model.symbol = token.symbol
                    model.type = token.type
                    model.decimal = token.decimal
                    try realm.write {
                        realm.add(model)
                    }
                    id += 1
                }
                
            } catch {
                Log("error: \(error)")
            }
        }
    }
    
    static func localTokenList() {
        do {
            let realm = try Realm()
            
            let list = realm.objects(TokenListModel.self)
            
            for tokenInfo in list {
                Log("name: \(tokenInfo.symbol)")
            }
        } catch {
            Log("error \(error)")
        }
    }
    
    static func findToken(_ address: String) -> TokenListInfo? {
        do {
            let realm = try Realm()
            
            guard let model = realm.objects(TokenListModel.self).filter({ $0.address.lowercased() == address.lowercased() }).first else { return nil }
            
            let info = TokenListInfo(symbol: model.symbol, address: model.address, decimal: model.decimal, type: model.type)
            return info                                   
        } catch {
            Log("error \(error)")
        }
        
        return nil
    }
}

