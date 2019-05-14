//
//  WalletCreator.swift
//  iconex_ios
//
//  Created by a1ahn on 20/12/2018.
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import ICONKit
import web3swift

// MARK: Wallet Creator

class WalletCreator {
    
    static let sharedInstance = WalletCreator()
    
    private init() {}
    
    var newType: COINTYPE?
    var newPrivateKey: String?
    var newAlias: String?
    var newWallet: BaseWalletConvertible?
    var newBundle: [[String: WalletExportBundle]]?
    var importStyle: Int = 0
    
    func createWallet(alias: String, password: String, completion: @escaping () -> Void) throws {
        guard let coinType = newType else {
            throw IXError.invalidCoinType
        }
        
        self.newAlias = alias
        
        switch coinType {
        case .icx:
            let newWallet = ICXWallet(alias: alias)
            let icxPrv = newWallet.generatePrivateKey()
            
            self.newPrivateKey = icxPrv
            
            _ = try newWallet.generateICXKeyStore(privateKey: icxPrv, password: password)
            self.newWallet = newWallet
            completion()
            
        case .eth:
            let newWallet = ETHWallet(alias: alias)
            try newWallet.generateETHKeyStore(password: password)
            self.newWallet = newWallet
            
            self.newPrivateKey = try newWallet.extractETHPrivateKey(password: password)
            
            completion()
            break
            
        default:
            break
        }
    }
    
    func createSwapWallet(alias: String, password: String, privateKey: String) throws {
        guard newType != nil else {
            throw IXError.invalidCoinType
        }
        
        self.newAlias = alias
        
        let newWallet = ICXWallet(alias: alias)
        self.newPrivateKey = privateKey
        
        _ = try newWallet.generateICXKeyStore(privateKey: privateKey, password: password)
        self.newWallet = newWallet
    }
    
    func importWallet(alias: String, password: String, completion: @escaping () -> Void) throws {
        guard let coinType = newType else {
            throw IXError.invalidCoinType
        }
        
        self.newAlias = alias
        
        switch coinType {
        case .icx:
            guard let icxPrv = newPrivateKey else {
                throw IXError.emptyPrivateKey
            }
            
            let newWallet = ICXWallet(alias: alias)
            
            try newWallet.generateICXKeyStore(privateKey: icxPrv, password: password)
            
            try newWallet.saveICXWallet()
            
            completion()
            
        case .eth:
            guard let ethPrv = newPrivateKey else {
                throw IXError.emptyPrivateKey
            }
            
            let newWallet = ETHWallet(alias: alias)
            try newWallet.generateETHKeyStore(privateKey: ethPrv, password: password)
            try newWallet.saveETHWallet()
            
            completion()
            
            break
            
        default:
            break
        }
    }
    
    func checkWalletBundle(url:URL) -> Bool {
        do {
            let content = try Data(contentsOf: url)
            
            let decoder = JSONDecoder()
            let list = try decoder.decode([[String: WalletExportBundle]].self, from: content)
            newBundle = list
            
            return true
        } catch {
            return false
        }
    }
    
    func validateBundlePassword(password: String) -> Bool {
        let item = newBundle!.first!
        let address = item.keys.first!
        let bundle = item[address]!
        let data = bundle.priv.data(using: .utf8)!
        do {
            if bundle.type == "icx" {
                guard let icx = ICXWallet(alias: "temp", from: data) else { return false }
                newPrivateKey = try icx.extractICXPrivateKey(password: password)
            } else if bundle.type == "eth" {
                let eth = ETHWallet(alias: "temp", from: data)
                newPrivateKey = try eth.extractETHPrivateKey(password: password)
            }
            
            return true
        } catch {
            Log.Debug("error - \(error)")
            
            return false
        }
    }
    
    func saveBundle() {
        guard let bundle = newBundle else { return }
        
        for item in bundle {
            guard let keyAddress = item.keys.first, let value = item.values.first else {
                continue
            }
            
            if !WManager.canSaveWallet(address: keyAddress) {
                Log.Debug("duplicated address \(keyAddress)")
                continue
            }
            if !WManager.canSaveWallet(alias: value.name) {
                Log.Debug("duplicated name \(value.name)")
                continue
            }
            
            let data = value.priv.data(using: .utf8)!
            Log.Debug(value.priv)
            do {
                switch value.type {
                case "icx":
                    guard let icxWallet = ICXWallet(alias: value.name, from: data) else { continue }
                    if let tokens = value.tokens {
                        var tokenList = [TokenInfo]()
                        for token in tokens {
                            let tokenInfo = TokenInfo(name: token.name, defaultName: token.defaultName, symbol: token.symbol, decimal: token.decimals, defaultDecimal: token.defaultDecimals, dependedAddress: icxWallet.address!.addHxPrefix(), contractAddress: token.address, parentType: "icx")
                            tokenList.append(tokenInfo)
                        }
                        icxWallet.tokens = tokenList.count > 0 ? tokenList : nil
                    }
                    try icxWallet.saveICXWallet()
                    Log.Debug("Save ICX wallet which was named as \"\(value.name)\"")
                    
                case "eth":
                    let ethWallet = ETHWallet(alias: value.name, from: data)
                    if let tokens = value.tokens {
                        var tokenList = [TokenInfo]()
                        for token in tokens {
                            let tokenInfo = TokenInfo(name: token.name, defaultName: token.defaultName, symbol: token.symbol, decimal: token.decimals, defaultDecimal: token.defaultDecimals, dependedAddress: ethWallet.address!.add0xPrefix(), contractAddress: token.address, parentType: "eth")
                            tokenList.append(tokenInfo)
                        }
                        ethWallet.tokens = tokenList.count > 0 ? tokenList : nil
                    }
                    try ethWallet.saveETHWallet()
                    Log.Debug("Save ETH wallet which was named as \"\(value.name)\"")
                    
                default:
                    break
                }
            } catch {
                Log.Debug(error)
                continue
            }
        }
        
        WManager.loadWalletList()
    }
    
    func validateKeystore(urlOfData: URL) throws -> (Keystore, COINTYPE) {
        let content = try Data(contentsOf: urlOfData)
        Log.Debug("content - \(String(describing: String(data: content, encoding: .utf8)))")
        let decoder = JSONDecoder()
        
        let keystore = try decoder.decode(Keystore.self, from: content)
        
        if keystore.address.hasPrefix("hx") {
            guard WManager.canSaveWallet(address: keystore.address.addHxPrefix()) else { throw IXError.duplicateAddress}
            
            return (keystore, .icx)
        } else {
            guard WManager.canSaveWallet(address: keystore.address.add0xPrefix()) else { throw IXError.duplicateAddress}
            return (keystore, .eth)
        }
    }
    
    func validateICXPrivateKey() throws -> Bool {
        guard let prvKey = newPrivateKey else {
            throw IXError.keyMalformed
        }
        
        let privateKey = PrivateKey(hex: prvKey.hexToData()!)
        
        guard let publicKey = Cipher.createPublicKey(privateKey: privateKey) else {
            throw IXError.copyPublicKey
        }
        
        let address = Cipher.makeAddress(privateKey, PublicKey(hex: publicKey.hexToData()!))
        
        return WManager.canSaveWallet(address: address)
    }
    
    func validateETHPrivateKey() throws -> Bool {
        guard let prvKey = newPrivateKey else {
            throw IXError.keyMalformed
        }
        
        let generator = try EthereumKeystoreV3(privateKey: prvKey.hexToData()!)
        
        guard let address = generator?.getAddress()?.address else {
            throw IXError.keyMalformed
        }
        
        return WManager.canSaveWallet(address: address.add0xPrefix())
    }
    
    func saveWallet(alias: String) throws {
        self.newAlias = alias
        self.newWallet?.alias = alias
        
        if let type = self.newWallet?.type {
            
            switch type {
            case .icx:
                let wallet = self.newWallet as! ICXWallet
                try wallet.saveICXWallet()
                
            case .eth:
                let wallet = self.newWallet as! ETHWallet
                try wallet.saveETHWallet()
                
            default:
                break
            }
            
        } else {
            throw IXError.invalidKeystore
        }
    }
    
    func resetData() {
        newType = nil
        newPrivateKey = nil
        newAlias = nil
        newWallet = nil
        newBundle = nil
    }
}

let WCreator = WalletCreator.sharedInstance

class BundleCreator {
    private var items: [WalletBundleItem]
    
    init(items: [WalletBundleItem]) {
        self.items = items
    }
    
    func createBundle(newPassword: String, completion: @escaping (_ isSuccess: Bool, _ filePath: URL?) -> Void) {
        DispatchQueue.global(qos: .default).async {
            var exportList = [[String: WalletExportBundle]]()
            for item in self.items {
                if item.type == .icx {
                    
                    let wallet = ICXWallet(alias: item.name)
                    let origin = WManager.loadWalletBy(address: item.address, type: item.type)
                    wallet.tokens = origin?.tokens
                    wallet.createdDate = origin?.createdDate
                    do {
                        try wallet.generateICXKeyStore(privateKey: item.privKey, password: newPassword)
                        let export = wallet.exportBundle()
                        exportList.append([wallet.address!: export])
                    } catch {
                        Log.Debug("\(error)")
                        DispatchQueue.main.async {
                            completion(false, nil)
                        }
                        return
                    }
                    
                    
                } else if item.type == .eth {
                    
                    let wallet = ETHWallet(alias: item.name)
                    let origin = WManager.loadWalletBy(address: item.address, type: item.type)
                    wallet.tokens = origin?.tokens
                    wallet.createdDate = origin?.createdDate
                    do {
                        try wallet.generateETHKeyStore(privateKey: item.privKey, password: newPassword)
                        let export = wallet.exportBundle()
                        exportList.append([wallet.address!: export])
                    } catch {
                        Log.Debug("\(error)")
                        DispatchQueue.main.async {
                            completion(false, nil)
                        }
                        return
                    }
                }
            }
            
            let encoder = JSONEncoder()
            do {
                let encoded = try encoder.encode(exportList)
                
                let filename = "ICONex_" + Date.currentZuluTime
                
                let fm = FileManager.default
                
                var path = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
                path = path.appendingPathComponent("ICONex")
                var isDirectory = ObjCBool(false)
                if !fm.fileExists(atPath: path.path, isDirectory: &isDirectory) {
                    try fm.createDirectory(at: path, withIntermediateDirectories: false, attributes: nil)
                }
                
                let filePath = path.appendingPathComponent(filename)
                try encoded.write(to: filePath, options: .atomic)
                
                DispatchQueue.main.async {
                    completion(true, filePath)
                }
            } catch {
                Log.Debug("\(error)")
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }
        }
    }
}

struct WalletExportBundle: Codable {
    var name: String
    var type: String
    var priv: String
    var tokens: [TokenExportBundle]?
    var createdAt: String?
    var coinType: String?
    
    init(name: String, type: String, priv: String, tokens: [TokenExportBundle]?, createdAt: String?, coinType: String?) {
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
                tokens = try container.decode([TokenExportBundle].self, forKey: .tokens)
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

struct TokenExportBundle: Codable {
    var address: String
    var createdAt: String
    var decimals: Int
    var defaultDecimals: Int
    var defaultName: String
    var name: String
    var defaultSymbol: String
    var symbol: String
    
    init(address: String, createdAt: String, decimals: Int, defaultDecimals: Int, defaultName: String, name: String, defaultSymbol: String, symbol: String) {
        self.address = address
        self.createdAt = createdAt
        self.decimals = decimals
        self.defaultDecimals = defaultDecimals
        self.defaultName = defaultName
        self.name = name
        self.defaultSymbol = defaultSymbol
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
