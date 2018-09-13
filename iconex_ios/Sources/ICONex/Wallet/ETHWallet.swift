//
//  ETHWallet.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import web3swift

struct ETH {
    struct KeyStore: Codable {
        let version: Int = 3
        let id: String = UUID().uuidString
        var address: String
        var Crypto: Crypto
        
        enum CodingKeys: String, CodingKey {
            case version
            case id
            case address
            case Crypto = "crypto"
        }
    }
    
    struct Crypto: Codable {
        var ciphertext: String
        var cipherparams: CipherParams
        var cipher: String
        var kdf: String
        var kdfparams: KDF
        var mac: String
    }
    
    struct CipherParams: Codable {
        var iv: String
    }
    
    struct KDF: Codable {
        let dklen: Int
        var salt: String
        let n: Int
        let r: Int
        let p: Int
    }
}

class ETHWallet: BaseWallet {
    var keystore: ETH.KeyStore?
    
    override init() {
        super.init(type: .eth)
    }
    
    init(alias: String) {
        super.init(type: .eth)
        self.alias = alias
    }
    
    convenience init(alias: String, from: Data) {
        self.init()
        self.alias = alias
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            var keystore = try decoder.decode(ETH.KeyStore.self, from: from)
            keystore.address = keystore.address.add0xPrefix().lowercased()
            self.keystore = keystore
            self.address = keystore.address
            
            let encoded = try encoder.encode(keystore)
            self.__rawData = encoded
        } catch {
            
        }
    }
    
    convenience init(keystore: ETH.KeyStore) {
        self.init()
        
        let encoder = JSONEncoder()
        __rawData = try! encoder.encode(keystore)
        
        self.address = keystore.address
    }
    
    convenience init(keystoreData: Data) {
        self.init()
        
        do {
            let decoder = JSONDecoder()
            let encoder = JSONEncoder()
            
            var keystore = try decoder.decode(ETH.KeyStore.self, from: keystoreData)
            keystore.address = keystore.address.add0xPrefix().lowercased()
            
            self.keystore = keystore
            let rawData = try encoder.encode(keystore)
            self.__rawData = rawData
            self.address = keystore.address
        } catch {
            
        }
    }
    
    func loadToken() {
        
    }
    
    func canSaveToken(contractAddress: String) -> Bool {
        guard let tokenList = tokens else { return true }
        return tokenList.filter { $0.contractAddress == contractAddress }.count == 0
    }
    
    func generateETHKeyStore(password: String) throws {
        let generator = try EthereumKeystoreV3(password: password)
        
        self.address = generator?.getAddress()?.address.add0xPrefix().lowercased()
        let params = generator?.keystoreParams
        
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(params)
        self.__rawData = encoded
        
        let decoder = JSONDecoder()
        let keystore = try decoder.decode(ETH.KeyStore.self, from: encoded)
        self.keystore = keystore
    }
    
    func generateETHKeyStore(privateKey: String, password: String) throws {
        guard let privateKeyData = privateKey.hexToData() else {
            throw IXError.convertKey
        }
        
        let generator = try EthereumKeystoreV3(privateKey: privateKeyData, password: password)
        
        self.address = generator?.getAddress()?.address
        let params = generator?.keystoreParams
        
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(params)
        self.__rawData = encoded
        
        let decoder = JSONDecoder()
        let keystore = try decoder.decode(ETH.KeyStore.self, from: encoded)
        self.keystore = keystore
    }
    
    func changePassword(oldPassword: String, newPassword: String) throws {
        guard let rawData = self.__rawData else {
            throw IXError.invalidKeystore
        }
        
        guard let generator = EthereumKeystoreV3(rawData) else {
            throw IXError.invalidKeystore
        }
        
        try generator.regenerate(oldPassword: oldPassword, newPassword: newPassword)
        
        let params = generator.keystoreParams
        let encoder = JSONEncoder()
        
        let encoded = try encoder.encode(params)
        self.__rawData = encoded
        
        let decoder = JSONDecoder()
        let keystore = try decoder.decode(ETH.KeyStore.self, from: encoded)
        self.keystore = keystore
    }
    
    func saveETHWallet() throws {
        
        try DB.saveWallet(name: self.alias!, address: self.address!, type: "eth", rawData: self.__rawData)
        
        if let tokens = self.tokens {
            for tokenInfo in tokens {
                
                if tokenInfo.symbol.lowercased() == "icx" {
                    if let privateKey = WCreator.newPrivateKey {
                        if let publicKey = ICONUtil.createPublicKey(privateKey: privateKey) {
                            let address = ICONUtil.makeAddress(privateKey, publicKey)
                            tokenInfo.swapAddress = address
                        }
                    }
                }
                
                try DB.addToken(tokenInfo: tokenInfo)
            }
        }
        
        var contract: String {
            switch Config.host {
            case .main:
                return "0xb5A5F22694352C15B00323844aD545ABb2B11028"
                
            default:
                return "0x55116b9cf269E3f7E9183D35D65D6C310fcAcF05"
            }
        }
        
        if canSaveToken(contractAddress: contract) {
            let icxInfo = TokenInfo(name: "ICON", defaultName: "ICON", symbol: "ICX", decimal: 18, defaultDecimal: 18, dependedAddress: self.address!, contractAddress: contract, parentType: "eth")
            
            if let privateKey = WCreator.newPrivateKey {
                if let publicKey = ICONUtil.createPublicKey(privateKey: privateKey) {
                    let address = ICONUtil.makeAddress(privateKey, publicKey)
                    icxInfo.swapAddress = address
                }
            }
            
            EManager.addToken(icxInfo.symbol)
            try DB.addToken(tokenInfo: icxInfo)
        }
    }
    
    func getBackupKeystoreFilepath() throws -> URL {
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(keystore)
        Log.Debug("encoded: " + String(data: encoded, encoding: .utf8)!)
        
        let filename = "UTC--" + Date.currentZuluTime + "--" + self.address!
        
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
        guard let generator = EthereumKeystoreV3(__rawData!) else {
            throw IXError.invalidKeystore
        }
        
        guard let ethereum = EthereumAddress(self.address!) else { throw IXError.invalidKeystore }
        let privateKeyData = try generator.UNSAFE_getPrivateKeyData(password: password, account: ethereum)
        
        return privateKeyData.toHexString()
    }
    
    func exportBundle() -> WalletExportBundle {
        let priv = String(data: __rawData!, encoding: .utf8)!.replacingOccurrences(of: "\\", with: "")
        
        var export = WalletExportBundle(name: self.alias!, type: "eth", priv: priv, tokens: nil)
        
        if let tokens = self.tokens {
            var datas = [TokenExportBundle]()
            for token in tokens {
                let exportToken = TokenExportBundle(address: token.contractAddress, createdAt: token.createDate.timestampString, decimals: token.decimal, defaultDecimals: token.defaultDecimal, defaultName: token.name, name: token.name, defaultSymbol: token.symbol, symbol: token.symbol)
                datas.append(exportToken)
            }
            export.tokens = datas
        }
        
        return export
    }
}
