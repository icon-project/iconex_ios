//
//  ICXWallet.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import ICONKit

class ICXWallet: BaseWalletConvertible {
    var name: String
    var created: Date
    var keystore: ICONKeystore
    
    var tokens: [Token]? {
        return try? DB.tokenList(dependedAddress: address)
    }
    
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
        self.created = created
        
        if let list = tokens {
            for token in list {
                if canSaveToken(contractAddress: token.contract) {
                    try? addToken(token: token)
                }
            }
        }
    }
    
    init(model: WalletModel) {
        self.name = model.name
        self.created = model.createdDate
        self.keystore = try! JSONDecoder().decode(ICONKeystore.self, from: model.rawData!)
    }
    
    static func new(name: String, password: String) throws -> ICXWallet {
        let keystore = try generateICXKeystore(password: password)
        let icx = ICXWallet(name: name, keystore: keystore)
        return icx
    }
    
    static fileprivate func generateICXKeystore(_ privateKey: PrivateKey? = nil, password: String) throws -> ICONKeystore {
        let wallet = Wallet(privateKey: privateKey)
        try wallet.generateKeystore(password: password)
        
        return try wallet.keystore!.convert()
    }
    
    func changePassword(oldPassword: String, newPassword: String) throws {
        let prv = try extractICXPrivateKey(password: oldPassword)
        let wallet = Wallet(privateKey: prv)
        try wallet.generateKeystore(password: newPassword)
        self.keystore = try wallet.keystore!.convert()
    }
    
    func extractICXPrivateKey(password: String) throws -> PrivateKey {
        return try keystore.extractPrivateKey(password: password)
    }
    
    func getBackupKeystoreFilepath() throws -> URL {
        let filename = "UTC--" + Date.currentZuluTime + "--" + self.address
        
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
    
    func exportBundle() -> WalletBundle {
        let priv = String(data: rawData, encoding: .utf8)!.replacingOccurrences(of: "\\", with: "")
        
        var export = WalletBundle(name: self.name, type: "icx", priv: priv, tokens: nil, createdAt: self.created.millieTimestamp, coinType: "icx")
        
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

extension Keystore {
    func convert() throws -> ICONKeystore {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        
        let decoder = JSONDecoder()
        return try decoder.decode(ICONKeystore.self, from: data)
    }
}
