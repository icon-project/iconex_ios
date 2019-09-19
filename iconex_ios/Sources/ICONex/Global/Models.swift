//
//  Models.swift
//  iconex_ios
//
//  Created by a1ahn on 22/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import RealmSwift

// MARK: Realm Strtuct
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

// MARK: ICONex structs


struct Token {
    var name: String
    var parent: String
    var contract: String
    var parentType: String
    var symbol: String
    var decimal: Int
    var created: Date = Date()
    
    init(model: TokenModel) {
        self.name = model.name
        self.parent = model.dependedAddress.prefix0xRemoved()
        self.contract = model.contractAddress
        self.parentType = model.parentType
        self.symbol = model.symbol
        self.decimal = model.defaultDecimal
        self.created = model.createdDate
    }
    
    init(name: String, parent: String, contract: String, parentType: String, symbol: String, decimal: Int, created: Date) {
        self.name = name
        self.parent = parent
        self.contract = contract
        self.parentType = parentType
        self.symbol = symbol
        self.decimal = decimal
        self.created = created
    }
}

// Token JSON File
struct TokenFile: Decodable {
    var name: String
    var address: String
    var symbol: String
    var decimal: Int
}

struct NewToken {
    var name: String
    var parent: String
    var contract: String
    var parentType: String
    var symbol: String
    var decimal: Int
    var created: Date = Date()
    
    init(token: TokenFile, parent: BaseWalletConvertible) {
        self.name = token.name
        self.parent = parent.address
        self.contract = token.address
        if let _ = parent as? ICXWallet {
            self.parentType = "icx"
        } else {
            self.parentType = "eth"
        }
        self.symbol = token.symbol
        self.decimal = token.decimal
    }
}


// MARK: Export Bundle

/// [[String: WalletBundle]]
typealias WalletBundleList = [[String: WalletBundle]]

struct WalletBundle: Codable {
    var name: String
    var type: String
    var priv: String
    var tokens: [TokenBundle]?
    var createdAt: String?
    var coinType: String?
    
    init(name: String, type: String, priv: String, tokens: [TokenBundle]?, createdAt: String?, coinType: String?) {
        self.name = name
        self.type = type
        self.priv = priv
        self.tokens = tokens
        self.createdAt = createdAt
        self.coinType = coinType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        priv = try container.decode(String.self, forKey: .priv)
        if container.contains(.tokens) {
            do {
                tokens = try container.decode([TokenBundle].self, forKey: .tokens)
            } catch {
                tokens = nil
            }
        }
        if container.contains(.createdAt) {
            createdAt = try container.decode(String.self, forKey: .createdAt)
        }
        if container.contains(.coinType) {
            coinType = try container.decode(String.self, forKey: .coinType)
        }
    }
}

struct TokenBundle: Codable {
    var address: String
    var createdAt: String
    var decimals: Int
    var defaultDecimals: Int
    var defaultName: String
    var name: String
    var defaultSymbol: String
    var symbol: String
    
    init(address: String, createdAt: String, decimals: Int, name: String, symbol: String) {
        self.address = address
        self.createdAt = createdAt
        self.decimals = decimals
        self.defaultDecimals = decimals
        self.defaultName = name
        self.name = name
        self.defaultSymbol = symbol
        self.symbol = symbol
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.address = try container.decode(String.self, forKey: .address)
        self.createdAt = try container.decode(String.self, forKey: .createdAt)
        do {
            self.decimals = try container.decode(Int.self, forKey: .decimals)
        } catch {
            let decimal = try container.decode(String.self, forKey: .decimals)
            self.decimals = Int(decimal)!
        }
        do {
            self.defaultDecimals = try container.decode(Int.self, forKey: .defaultDecimals)
        } catch {
            let decimal = try container.decode(String.self, forKey: .defaultDecimals)
            self.defaultDecimals = Int(decimal)!
        }
        self.name = try container.decode(String.self, forKey: .name)
        self.defaultName = try container.decode(String.self, forKey: .defaultName)
        self.defaultSymbol = try container.decode(String.self, forKey: .defaultSymbol)
        self.symbol = try container.decode(String.self, forKey: .symbol)
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

public enum CoinType {
    case icx, eth
    
    var fullName: String {
        switch self {
        case .icx: return "ICON"
        case .eth: return "Ethereum"
        }
    }
    
    var symbol: String {
        switch self {
        case .icx: return "ICX"
        case .eth: return "ETH"
        }
    }
}

public enum BalanceUnit {
    case USD, BTC, ETH, ICX
    
    var symbol: String {
        switch self {
        case .USD: return "USD"
        case .BTC: return "BTC"
        case .ETH: return "ETH"
        case .ICX: return "ICX"
        }
    }
}
