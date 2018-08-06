//
//  Cipher.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import Foundation
import Security
import CryptoSwift

struct Cipher {
    static func pbkdf2SHA1(password: String, salt: Data, keyByteCount: Int, round: Int) -> Data? {
        return pbkdf2(hash: CCPBKDFAlgorithm(kCCPRFHmacAlgSHA1), password: password, salt: salt, keyByteCount: keyByteCount, round: round)
    }

    static func pbkdf2SHA256(password: String, salt: Data, keyByteCount: Int, round: Int) -> Data? {
        return pbkdf2(hash: CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256), password: password, salt: salt, keyByteCount: keyByteCount, round: round)
    }

    static func pbkdf2SHA512(password: String, salt: Data, keyByteCount: Int, round: Int) -> Data? {
        return pbkdf2(hash: CCPBKDFAlgorithm(kCCPRFHmacAlgSHA512), password: password, salt: salt, keyByteCount: keyByteCount, round: round)
    }

    static func pbkdf2(hash: CCPBKDFAlgorithm, password: String, salt: Data, keyByteCount: Int, round: Int) -> Data? {
        let passwordData = password.data(using: .utf8)!
        var derivedKeyData = Data(count: keyByteCount)
        var localVariables = derivedKeyData
        let derivationStatus = localVariables.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2),
                                     password, passwordData.count, saltBytes, salt.count,
                                     hash, UInt32(round),
                                     derivedKeyBytes, derivedKeyData.count)
            }
        }

        if (derivationStatus != 0) {
            Log.Error("\(derivationStatus)")
            return nil;
        }

        return localVariables
    }
}

public struct ICONUtil {

    static let PBE_DKLEN = 32
    static let PBE_MAC_KECCAK = "Keccak-256"
    static let PBE_MAC_SHA3 = "SHA3-256"
    
    static func generatePrivateKey() -> String {
        
        var key = ""
        
        for _ in 0..<64 {
            let code = arc4random() % 16
            
            key += String(format: "%x", code)
        }
        
        return key.sha3(.sha256)
    }
    
    static func createPublicKey(privateKey: String) -> String? {
        guard let pubKey = SECPWrapper.ecdsa_create_publicKey(privateKey) else {
            return nil
        }
        
        Log.Info("seialized publickey : \(pubKey)")
        
        return String(pubKey.suffix(pubKey.length - 2))
    }
    
    static func makeAddress(_ privateKey: String?, _ publicKey: String) -> String {
        return ICONUtil.makeAddress(privateKey, publicKey.hexToData()!)
    }
    
    static func makeAddress(_ privateKey: String?, _ publicKey: Data) -> String {
        var hash: Data
        if publicKey.count > 64 {
            hash = publicKey.subdata(in: 1...64)
            hash = hash.sha3(.sha256)
        } else {
            hash = publicKey.sha3(.sha256)
        }
        
        let sub = hash.suffix(20)
        let address = "hx" + String(sub.toHexString())
        
        if let privKey = privateKey {
            if checkAddress(privateKey: privKey, address: address) {
                return address
            } else {
                return makeAddress(privKey, publicKey)
            }
        }
        
        return address
    }
    
    static func checkAddress(privateKey: String, address: String) -> Bool {
        let fixed = Date.timestampString.sha3(.sha256).hexToData()!
        
        var rsig: NSData?
        var ser_rsig: NSData?
        var recid: NSString?
        
        SECPWrapper.ecdsa_recoverable_sign(privateKey, hashedMessage: fixed, rsign: &rsig, ser_rsign: &ser_rsig, recid: &recid)
        
        guard case let rsign as Data = rsig else {
            return false
        }
        
        let vPub = SECPWrapper.ecdsa_verify_publickey(fixed, rsign: rsign.toHexString())
        
        let vaddr = ICONUtil.makeAddress(nil, vPub!)
        
        return address == vaddr
    }
    
    static func signECDSA(hashedMessage: Data, privateKey: String) throws -> (signature: Data?, recid: String?) {
        
        var rsig: NSData?
        var ser_rsig: NSData?
        var recid: NSString?
        SECPWrapper.ecdsa_recoverable_sign(privateKey, hashedMessage: hashedMessage, rsign: &rsig, ser_rsign: &ser_rsig, recid: &recid)
        
        guard let ser_rsign = ser_rsig, let recoveryID = recid else {
            throw IXError.sign
        }
        
        return (ser_rsign as Data, recoveryID as String)
    }
    
    static func encrypt(devKey:Data, data: Data, salt: Data) throws -> (cipherText: String, mac: String, iv: String) {
        let eKey: [UInt8] = Array(devKey.bytes[0..<PBE_DKLEN/2])
        let mKey: [UInt8] = Array(devKey.bytes[PBE_DKLEN/2..<PBE_DKLEN])
        
        let iv = AES.randomIV(AES.blockSize)
        
        let encrypted: [UInt8] = try AES(key: eKey, blockMode: CTR(iv: iv), padding: .noPadding).encrypt(data.bytes)
        
        let mac = mKey + encrypted
        let digest = mac.sha3(.keccak256)
        
        return (Data(bytes: encrypted).toHexString(), Data(bytes: digest).toHexString(), Data(iv).toHexString())
    }
    
    static func decrypt(devKey: Data, enc: Data, dkLen: Int, iv: Data) throws -> (decryptText: String, mac: String) {
        let eKey: [UInt8] = Array(devKey.bytes[0..<PBE_DKLEN/2])
        let mKey: [UInt8] = Array(devKey.bytes[PBE_DKLEN/2..<PBE_DKLEN])
        
        let decrypted: [UInt8] = try AES(key: eKey, blockMode: CTR(iv: iv.bytes), padding: .noPadding).decrypt(enc.bytes)
        
        let mac: [UInt8] = mKey + enc.bytes
        let digest = mac.sha3(.keccak256)
        
        return (Data(bytes: decrypted).toHexString(), Data(bytes: digest).toHexString())
    }
}



