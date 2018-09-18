//
//  Cipher.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import Security
import CryptoSwift
import CommonCrypto
import secp256k1_ios

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
        let flag = UInt32(SECP256K1_CONTEXT_SIGN)
        guard let privData = privateKey.hexToData(), let ctx = secp256k1_context_create(flag) else { return nil }
        var rawPubkey = secp256k1_pubkey()
        
        guard secp256k1_ec_pubkey_create(ctx, &rawPubkey, privData.bytes) == 1 else { return nil }
        
        let serializedPubkey = UnsafeMutablePointer<UInt8>.allocate(capacity: 65)
        var pubLen = 65
        
        guard secp256k1_ec_pubkey_serialize(ctx, serializedPubkey, &pubLen, &rawPubkey, UInt32(SECP256K1_EC_UNCOMPRESSED)) == 1 else {
            secp256k1_context_destroy(ctx)
            return nil }
        
        secp256k1_context_destroy(ctx)
        
        let publicKey = Data(bytes: serializedPubkey, count: 65).toHexString()
        
        return String(publicKey.suffix(publicKey.length - 2))
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
        
        guard var rsign = ICONUtil.ecdsaRecoverSign(privateKey: privateKey, hashed: fixed) else { return false }
        
        guard let vPub = verifyPublickey(hashedMessage: fixed, signature: &rsign), let hexPub = vPub.hexToData() else { return false }
        
        let vaddr = makeAddress(nil, hexPub)
        
        return address == vaddr
    }
    
    static public func ecdsaRecoverSign(privateKey: String, hashed: Data) -> secp256k1_ecdsa_recoverable_signature? {
        let flag = UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)
        
        guard let ctx = secp256k1_context_create(flag), let privData = privateKey.hexToData() else { return nil }
        var rsig = secp256k1_ecdsa_recoverable_signature()
        
        guard secp256k1_ecdsa_sign_recoverable(ctx, &rsig, hashed.bytes, privData.bytes, nil, nil) == 1 else {
            secp256k1_context_destroy(ctx)
            return nil }
        
        return rsig
    }
    
    ///
    /// Reference from web3swift
    /// https://github.com/BANKEX/web3swift
    ///
    static public func verifyPublickey(hashedMessage: Data, signature: inout secp256k1_ecdsa_recoverable_signature) -> String? {
        let flag = UInt32(SECP256K1_CONTEXT_VERIFY)
        
        guard let ctx = secp256k1_context_create(flag) else { return nil }
        
        var pubkey = secp256k1_pubkey()
        
        let result = hashedMessage.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> Int32 in
            withUnsafePointer(to: &signature, { (sigPtr: UnsafePointer<secp256k1_ecdsa_recoverable_signature>) -> Int32 in
                withUnsafeMutablePointer(to: &pubkey, { (pubPtr: UnsafeMutablePointer<secp256k1_pubkey>) -> Int32 in
                    secp256k1_ecdsa_recover(ctx, pubPtr, sigPtr, ptr)
                })
            })
        }
        
        guard result == 1 else { return nil }
        
        let serializedPubkey = UnsafeMutablePointer<UInt8>.allocate(capacity: 65)
        var pubLen = 65
        
        guard secp256k1_ec_pubkey_serialize(ctx, serializedPubkey, &pubLen, &pubkey, UInt32(SECP256K1_EC_UNCOMPRESSED)) == 1 else {
            secp256k1_context_destroy(ctx)
            return nil }
        
        secp256k1_context_destroy(ctx)
        
        let publicKey = Data(bytes: serializedPubkey, count: 65).toHexString()
        
        return publicKey
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



