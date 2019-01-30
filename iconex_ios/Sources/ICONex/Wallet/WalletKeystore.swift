//
//  WalletKeystore.swift
//  iconex_ios
//
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import ICONKit
import CryptoSwift
import scrypt

public class Keystore: Codable {
    public var version: Int = 3
    public var id: String = UUID().uuidString
    public var address: String
    public var crypto: Crypto
    public var coinType: String?
    
    public var data: Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
    
    enum KeystoreCodingKey: String, CodingKey {
        case version
        case id
        case address
        case crypto
        case Crypto
        case coinType
    }
    
    init(address: String, crypto: Crypto) {
        self.address = address
        self.crypto = crypto
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: KeystoreCodingKey.self)
        
        self.version = try container.decode(Int.self, forKey: .version)
        self.id = try container.decode(String.self, forKey: .id)
        self.address = try container.decode(String.self, forKey: .address)
        if container.contains(.crypto) {
            self.crypto = try container.decode(Crypto.self, forKey: .crypto)
        } else {
            self.crypto = try container.decode(Crypto.self, forKey: .Crypto)
        }
        if container.contains(.coinType) {
            self.coinType = try container.decode(String.self, forKey: .coinType)
        }
    }
    
    public struct Crypto: Codable {
        public var ciphertext: String
        public var cipherparams: CipherParams
        public var cipher: String
        public var kdf: String
        public var kdfparams: KDF
        public var mac: String
    }
    
    public struct CipherParams: Codable {
        public var iv: String
    }
    
    public struct KDF: Codable {
        public let dklen: Int
        public var salt: String
        public var c: Int?
        public var n: Int?
        public var p: Int?
        public var r: Int?
        public let prf: String?
        
        init(dklen: Int, salt: String, c: Int, prf: String) {
            self.dklen = dklen
            self.salt = salt
            self.c = c
            self.prf = prf
        }
    }
}

extension Keystore {
    
    @discardableResult
    func isValid(password: String) throws -> Bool {
        if self.crypto.kdf == "pbkdf2" {
            guard let enc = self.crypto.ciphertext.hexToData(),
                let iv = self.crypto.cipherparams.iv.hexToData(),
                let salt = self.crypto.kdfparams.salt.hexToData(),
                let count = self.crypto.kdfparams.c else { throw IXError.invalidKeystore }
            
            guard let devKey = Cipher.pbkdf2SHA256(password: password, salt: salt, keyByteCount: PBE_DKLEN, round: count) else { throw IXError.decrypt }
            
            let decrypted = try Cipher.decrypt(devKey: devKey, enc: enc, dkLen: PBE_DKLEN, iv: iv)
            let prvKeyStr = decrypted.decryptText
            let privateKey = PrivateKey(hexData: prvKeyStr.hexToData()!)
            
            let wallet = Wallet(privateKey: privateKey)
            let newAddress = wallet.address
            
            if newAddress == self.address {
                return true
            }
            
            throw IXError.decrypt
            
        } else if self.crypto.kdf == "scrypt" {
            guard let n = self.crypto.kdfparams.n,
                let p = self.crypto.kdfparams.p,
                let r = self.crypto.kdfparams.r,
                let iv = self.crypto.cipherparams.iv.hexToData(),
                let cipherText = self.crypto.ciphertext.hexToData(),
                let salt = self.crypto.kdfparams.salt.hexToData()
                else { throw IXError.keyMalformed }
            
            guard let devKey = Cipher.scrypt(password: password, saltData: salt, dkLen: self.crypto.kdfparams.dklen, N: n, R: r, P: p) else { throw IXError.decrypt }
            let decryptionKey = devKey[0...15]
            guard let aesCipher = try? AES(key: decryptionKey.bytes, blockMode: CTR(iv: iv.bytes), padding: .noPadding) else { throw IXError.decrypt }
            guard let decryptedBytes = try? aesCipher.decrypt(cipherText.bytes) else { throw IXError.decrypt }
            let decrypted = Data(bytes: decryptedBytes)
            let prvKey = PrivateKey(hexData: decrypted)
            let wallet = Wallet(privateKey: prvKey)
            let newAddress = wallet.address
            
            if newAddress == self.address {
                return true
            }
            
            throw IXError.invalidPassword
        }
        
        throw IXError.invalidKeystore
    }
    
    func toString() -> String {
        let encoder = JSONEncoder()
        
        let data = try! encoder.encode(self)
        
        return String(data: data, encoding: .utf8)!.replacingOccurrences(of: "\\", with: "")
    }
    
    func extractPrivateKey(password: String) throws -> String {
        
        if crypto.kdf == "pbkdf2" {
            guard let enc = crypto.ciphertext.hexToData(),
                let iv = crypto.cipherparams.iv.hexToData(),
                let salt = crypto.kdfparams.salt.hexToData(),
                let count = crypto.kdfparams.c else { throw IXError.keyMalformed }
            
            guard let devKey = Cipher.pbkdf2SHA256(password: password, salt: salt, keyByteCount: PBE_DKLEN, round: count) else { throw IXError.decrypt }
            
            let decrypted = try Cipher.decrypt(devKey: devKey, enc: enc, dkLen: PBE_DKLEN, iv: iv)
            let publicKey = Cipher.createPublicKey(privateKey: decrypted.decryptText)!
            let newAddress = Cipher.makeAddress(decrypted.decryptText, publicKey)
            
            if newAddress == self.address {
                return decrypted.decryptText
            }
            
            throw ICError.invalid(.privateKey)
            
        } else if crypto.kdf == "scrypt" {
            guard let n = crypto.kdfparams.n,
                let p = crypto.kdfparams.p,
                let r = crypto.kdfparams.r,
                let iv = crypto.cipherparams.iv.hexToData(),
                let cipherText = crypto.ciphertext.hexToData(),
                let salt = crypto.kdfparams.salt.hexToData()
                else { throw ICError.malformed }
            
            guard let devKey = Cipher.scrypt(password: password, saltData: salt, dkLen: crypto.kdfparams.dklen, N: n, R: r, P: p) else { throw IXError.decrypt }
            let decryptionKey = devKey[0...15]
            guard let aesCipher = try? AES(key: decryptionKey.bytes, blockMode: CTR(iv: iv.bytes), padding: .noPadding) else { throw IXError.decrypt }
            guard let decryptedBytes = try? aesCipher.decrypt(cipherText.bytes) else { throw IXError.decrypt }
            let decrypted = Data(bytes: decryptedBytes).toHexString()
            
            let publicKey = Cipher.createPublicKey(privateKey: decrypted)
            let newAddress = Cipher.makeAddress(decrypted, publicKey!)
            
            if newAddress == self.address {
                return decrypted
            }
            
            throw ICError.invalid(.privateKey)
        }
        
        throw ICError.invalid(.notSupported)
    }
}
