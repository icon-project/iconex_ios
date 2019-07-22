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
        
        
    }
    
    init(model: WalletModel) {
        self.name = model.name
        self.created = model.createdDate
        self.keystore = try! JSONDecoder().decode(ICONKeystore.self, from: model.rawData!)
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
    
    @available(*, unavailable)
    func generateICXKeyStore(privateKey: String, password: String) throws {
    }
    
    #warning("TODO: Implement saveICXWallet")
    func saveICXWallet() throws {
        try DB.saveWallet(name: self.name, address: self.address, type: "icx", rawData: self.rawData)
        
        if let tokens = self.tokens {
            for tokenInfo in tokens {
//                try DB.addToken(tokenInfo: tokenInfo)
            }
        }
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
}
