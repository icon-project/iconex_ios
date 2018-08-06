//
//  ICXWallet.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import Foundation

class ICXWallet: BaseWallet {
    
    var keyStore: ICON.Keystore?
    
    override init() {
        super.init(type: .icx)
    }
    
    init(alias: String) {
        super.init(type: .icx)
        self.alias = alias
    }
    
    convenience init(alias: String, from: Data) {
        self.init()
        self.alias = alias
        __rawData = from
        
        let decoder = JSONDecoder()
        self.keyStore = try! decoder.decode(ICON.Keystore.self, from: from)
        self.address = keyStore?.address
    }
    
    convenience init(keystore: ICON.Keystore) {
        self.init()
        
        self.keyStore = keystore
        
        let encoder = JSONEncoder()
        __rawData = try! encoder.encode(keystore)
        self.address = keystore.address
    }
    
    func exportBundle() -> WalletExportBundle {
        let priv = String(data: __rawData!, encoding: .utf8)!.replacingOccurrences(of: "\\", with: "")
        
        let export = WalletExportBundle(name: self.alias!, type: "icx", priv: priv, tokens: nil)
        
        return export
    }
    
    @discardableResult
    func generateICXKeyStore(privateKey: String, password: String) throws -> Bool {
        
        let iconWallet = ICON.Wallet(privateKey: privateKey, password: password)
        
        guard let keystore = iconWallet.keystore else { throw IXError.generateKey }
        
        self.keyStore = keystore
        
        let encoder = JSONEncoder()
        
        let encoded = try encoder.encode(keystore)
        self.__rawData = encoded
        
        return true
    }
    
    func changePassword(old: String, new: String) throws {
        guard let keystore = self.keyStore else { throw IXError.emptyWallet }
        
        let iconWallet = ICON.Wallet(keystore: keystore)
        
        guard iconWallet.changePassword(current: old, new: new) else { throw IXError.keyMalformed }
        
        let encoder = JSONEncoder()
        
        let encoded = try encoder.encode(iconWallet.keystore!)
        self.__rawData = encoded
    }
    
    func saveICXWallet() throws {
        
        try DB.saveWallet(name: self.alias!, address: self.keyStore!.address, type: "icx", rawData: self.__rawData)
        
    }
    
    func extractICXPrivateKey(password: String) throws -> String {
        guard let keyStore = self.keyStore else {
            throw IXError.emptyWallet
        }
        
        let iconWallet = ICON.Wallet(keystore: keyStore)
        
        guard let privateKey = iconWallet.extractPrivateKey(password: password) else { throw IXError.keyMalformed }
        
        return privateKey
    }
    
    func getBackupKeystoreFilepath() throws -> URL {
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(keyStore)
        Log.Debug("encoded: " + String(data: encoded, encoding: .utf8)!)
        
        let filename = "UTC--" + Date.currentZuluTime + "--" + keyStore!.address
        
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
}
