//
//  ETHWallet.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import Web3swift
import ICONKit

class ETHWallet: BaseWalletConvertible {
    var name: String
    var tokens: [Token]?
    var created: Date
    var keystore: ICONKeystore
    
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
    
    init(name: String, keystore: ICONKeystore, tokens: [Token]? = nil, created: Date = Date()) {
        self.name = name
        self.keystore = keystore
        self.tokens = tokens
        self.created = created
    }
    
    init(model: WalletModel) {
        self.name = model.name
        self.created = model.createdDate
        self.keystore = try! JSONDecoder().decode(ICONKeystore.self, from: model.rawData!)
    }
    
    func loadToken() {
        
    }
    
    func canSaveToken(contractAddress: String) -> Bool {
        guard let tokenList = tokens else { return true }
        return tokenList.filter { $0.contract.lowercased() == contractAddress.lowercased() }.count == 0
    }
    
    func generateETHKeyStore(password: String) throws {
        let generator = try EthereumKeystoreV3(password: password, aesMode: "aes-128-ctr")
        
        guard let params = generator?.keystoreParams else { throw CryptError.generateKey }
        
        let raw = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        let decoder = JSONDecoder()
        let keystore = try decoder.decode(ICONKeystore.self, from: raw)
        self.keystore = keystore
    }
    
    func generateETHKeyStore(privateKey: PrivateKey, password: String) throws {
        let generator = try EthereumKeystoreV3(privateKey: privateKey.data, password: password, aesMode: "aes-128-ctr")
        
        guard let params = generator?.keystoreParams else { throw CryptError.generateKey }
        
        let raw = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        let decoder = JSONDecoder()
        let keystore = try decoder.decode(ICONKeystore.self, from: raw)
        self.keystore = keystore
    }
    
    func changePassword(oldPassword: String, newPassword: String) throws {
        guard let generator = EthereumKeystoreV3(rawData) else {
            throw WalletError.invalidKeystore
        }
        
        try generator.regenerate(oldPassword: oldPassword, newPassword: newPassword)
        
        let params = generator.keystoreParams
        let encoder = JSONEncoder()
        
        let encoded = try encoder.encode(params)
        
        let decoder = JSONDecoder()
        let keystore = try decoder.decode(ICONKeystore.self, from: encoded)
        self.keystore = keystore
    }
    
    func saveETHWallet() throws {
        
        try DB.saveWallet(name: self.name, address: self.address.add0xPrefix().lowercased(), type: "eth", rawData: self.rawData)
        
        if let tokens = self.tokens {
            for tokenInfo in tokens {
                try DB.addToken(tokenInfo: tokenInfo)
            }
        }
    }
    
    func getBackupKeystoreFilepath() throws -> URL {
        let encoder = JSONEncoder()
        keystore.address = keystore.address.prefix0xRemoved()
        let encoded = try encoder.encode(keystore)
        Log("encoded: " + String(data: encoded, encoding: .utf8)!)
        
        let filename = "UTC--" + Date.currentZuluTime + "--" + self.address
        
        let fm = FileManager.default
        
        var path = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        path = path.appendingPathComponent("ICONex")
        var isDirectory = ObjCBool(false)
        if !fm.fileExists(atPath: path.path, isDirectory: &isDirectory) {
            try fm.createDirectory(at: path, withIntermediateDirectories: false, attributes: nil)
        }
        
        let filePath = path.appendingPathComponent(filename)
        try encoded.write(to: filePath, options: .atomic)
        
        return filePath
    }
    
    func extractETHPrivateKey(password: String) throws -> String {
        let encoder = JSONEncoder()
        let tempData = try encoder.encode(keystore)
        
        guard let generator = EthereumKeystoreV3(tempData) else { throw WalletError.invalidKeystore }
        
        guard let ethereum = EthereumAddress(keystore.address.add0xPrefix()) else { throw WalletError.invalidKeystore }
        let privateKeyData = try generator.UNSAFE_getPrivateKeyData(password: password, account: ethereum)
        
        return privateKeyData.toHexString()
    }
    
    func exportBundle() -> WalletBundle {
        let encoder = JSONEncoder()
        keystore.address = keystore.address.prefix0xRemoved()
        let encoded = try! encoder.encode(keystore)
        let priv = String(data: encoded, encoding: .utf8)!
        
        var export = WalletBundle(name: self.name, type: "eth", priv: priv, tokens: nil, createdAt: self.created.millieTimestamp, coinType: nil)
        
        var datas = [TokenBundle]()
        if let tokens = self.tokens {
            for token in tokens {
                let exportToken = TokenBundle(address: token.contract, createdAt: token.created.timestampString, decimals: token.decimal, name: token.name, symbol: token.symbol)
                datas.append(exportToken)
            }
        }
        export.tokens = datas
        
        return export
    }
}
