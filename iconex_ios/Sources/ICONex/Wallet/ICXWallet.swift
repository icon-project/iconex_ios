//
//  ICXWallet.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import ICONKit

class ICXWallet: BaseWallet {
    
    init?(name: String, from: Data) {
        do {
            let decoder = JSONDecoder()
            let keystore = try decoder.decode(ICONKeystore.self, from: from)
            super.init(name: name, keystore: keystore)
        } catch {
            return nil
        }
    }
    
    init(name: String, keystore: ICONKeystore, tokens: [Token]? = nil) {
        super.init(name: name, keystore: keystore)
        self.tokens = tokens
    }
    
    #warning("TODO: Implement exportBunlde")
    func exportBundle() -> WalletExportBundle {
//        let priv = String(data: __rawData!, encoding: .utf8)!.replacingOccurrences(of: "\\", with: "")
//
//        var export = WalletExportBundle(name: self.alias!, type: "icx", priv: priv, tokens: nil, createdAt: self.createdDate!.millieTimestamp, coinType: "icx")
//
//        var datas = [TokenExportBundle]()
//        if let tokens = self.tokens {
//            for token in tokens {
//                let exportToken = TokenExportBundle(address: token.contractAddress, createdAt: token.createDate.timestampString, decimals: token.decimal, defaultDecimals: token.defaultDecimal, defaultName: token.name, name: token.name, defaultSymbol: token.symbol, symbol: token.symbol)
//                datas.append(exportToken)
//            }
//        }
//        export.tokens = datas
//
//        return export
    }
    
    func canSaveToken(contractAddress: String) -> Bool {
        guard let tokenList = tokens else { return true }
        return tokenList.filter { $0.contract == contractAddress }.count == 0
    }
    
    @available(*, unavailable)
    func generateICXKeyStore(privateKey: String, password: String) throws {
    }
    
    #warning("TODO: Implement changePassword")
    func changePassword(old: String, new: String) throws {
//        guard let keystore = self.keystore else { throw IXError.emptyWallet }
//        try keystore.isValid(password: old)
//
//        let prvKey = try self.extractICXPrivateKey(password: old)
//        let newKeystore = try Cipher.createKeystore(privateKey: prvKey, password: new)
//
//        self.__rawData = newKeystore.data
//        self.keystore = newKeystore
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
