//
//  ICXWallet.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import ICONKit

class ICXWallet: BaseWallet {
    var keystore: Keystore?
    
    override init() {
        super.init(type: .icx)
    }
    
    init(alias: String) {
        super.init(type: .icx)
        self.alias = alias
    }
    
    convenience init?(alias: String, from: Data) {
        do {
            let decoder = JSONDecoder()
            let keystore = try decoder.decode(Keystore.self, from: from)
            
            self.init()
            self.alias = alias
            self.__rawData = from
            self.type = .icx
            self.keystore = keystore
            self.address = keystore.address
        } catch {
            return nil
        }
    }
    
    convenience init(keystore: Keystore) {
        self.init()

        let encoder = JSONEncoder()
        __rawData = try? encoder.encode(keystore)
        self.address = keystore.address
        self.keystore = keystore
    }
    
    convenience init(privateKey: String, password: String) {
        self.init()
        
        do {
            try generateICXKeyStore(privateKey: privateKey, password: password)
        } catch {
            return
        }
    }
    
    func exportBundle() -> WalletExportBundle {
        let priv = String(data: __rawData!, encoding: .utf8)!.replacingOccurrences(of: "\\", with: "")
        
        var export = WalletExportBundle(name: self.alias!, type: "icx", priv: priv, tokens: nil, createdAt: self.createdDate!.millieTimestamp, coinType: "icx")
        
        var datas = [TokenExportBundle]()
        if let tokens = self.tokens {
            for token in tokens {
                let exportToken = TokenExportBundle(address: token.contractAddress, createdAt: token.createDate.timestampString, decimals: token.decimal, defaultDecimals: token.defaultDecimal, defaultName: token.name, name: token.name, defaultSymbol: token.symbol, symbol: token.symbol)
                datas.append(exportToken)
            }
        }
        export.tokens = datas
        
        return export
    }
    
    func canSaveToken(contractAddress: String) -> Bool {
        guard let tokenList = tokens else { return true }
        return tokenList.filter { $0.contractAddress == contractAddress }.count == 0
    }
    
    func generateICXKeyStore(privateKey: String, password: String) throws {
        
        let wallet = Wallet(privateKey: PrivateKey(hex: privateKey.hexToData()!))
        try wallet.generateKeystore(password: password)
        
        self.__rawData = try wallet.keystore!.jsonData()
        self.address = wallet.address
        
        let decoder = JSONDecoder()
        
        self.keystore = try decoder.decode(Keystore.self, from: __rawData!)
    }
    
    func changePassword(old: String, new: String) throws {
        guard let keystore = self.keystore else { throw IXError.emptyWallet }
        try keystore.isValid(password: old)
        
        let prvKey = try self.extractICXPrivateKey(password: old)
        let newKeystore = try Cipher.createKeystore(privateKey: prvKey, password: new)
        
        self.__rawData = newKeystore.data
        self.keystore = newKeystore
    }
    
    func saveICXWallet() throws {
        
        try DB.saveWallet(name: self.alias!, address: self.address!, type: "icx", rawData: self.__rawData)
        
        if let tokens = self.tokens {
            for tokenInfo in tokens {
                try DB.addToken(tokenInfo: tokenInfo)
            }
        }
    }
    
    func extractICXPrivateKey(password: String) throws -> String {
        guard let keystore = self.keystore else { throw IXError.emptyWallet }
        
        return try keystore.extractPrivateKey(password: password)
    }
    
    func getBackupKeystoreFilepath() throws -> URL {
        guard let rawData = __rawData else { throw IXError.emptyWallet }
        
        let filename = "UTC--" + Date.currentZuluTime + "--" + self.address!
        
        let fm = FileManager.default
        
        var path = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        path = path.appendingPathComponent("ICONex")
        var isDirectory = ObjCBool(false)
        if !fm.fileExists(atPath: path.path, isDirectory: &isDirectory) {
            try fm.createDirectory(at: path, withIntermediateDirectories: false, attributes: nil)
        }
        
        let filePath = path.appendingPathComponent(filename)
        try rawData.write(to: filePath, options: .atomic)
        
        return filePath
    }
}
