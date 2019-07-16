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
import secp256k1_swift
import ICONKit

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
    
    static func encrypt(devKey:Data, data: Data, salt: Data) throws -> (cipherText: String, mac: String, iv: String) {
        let eKey: [UInt8] = Array(devKey.bytes[0..<PBE_DKLEN/2])
        let mKey: [UInt8] = Array(devKey.bytes[PBE_DKLEN/2..<PBE_DKLEN])
        
        let iv = AES.randomIV(AES.blockSize)
        
        let encrypted: [UInt8] = try AES(key: eKey, blockMode: CTR(iv: iv), padding: .noPadding).encrypt(data.bytes)
        
        let mac = mKey + encrypted
        let digest = mac.sha3(.keccak256)
        
        return (Data(encrypted).toHexString(), Data(digest).toHexString(), Data(iv).toHexString())
    }
    
    static func decrypt(devKey: Data, enc: Data, dkLen: Int, iv: Data) throws -> (decryptText: String, mac: String) {
        let eKey: [UInt8] = Array(devKey.bytes[0..<PBE_DKLEN/2])
        let mKey: [UInt8] = Array(devKey.bytes[PBE_DKLEN/2..<PBE_DKLEN])
        
        let decrypted: [UInt8] = try AES(key: eKey, blockMode: CTR(iv: iv.bytes), padding: .noPadding).decrypt(enc.bytes)
        
        let mac: [UInt8] = mKey + enc.bytes
        let digest = mac.sha3(.keccak256)
        
        return (Data(decrypted).toHexString(), Data(digest).toHexString())
    }
    
    static func scrypt(password: String, saltData: Data? = nil, dkLen: Int = 32, N: Int = 4096, R: Int = 6, P: Int = 1) -> Data? {
        let passwordData = password.data(using: .utf8)!
        var salt = Data()
        if let saltValue = saltData {
            salt = saltValue
        } else {
            let saltCount = 32
            var randomBytes = Array<UInt8>(repeating: 0, count: saltCount)
            let err = SecRandomCopyBytes(kSecRandomDefault, saltCount, &randomBytes)
            if err != errSecSuccess { return nil }
            salt = Data(randomBytes)
        }
        
        guard let scrypt = try? Scrypt(password: passwordData.bytes, salt: salt.bytes, dkLen: dkLen, N: N, r: R, p: P) else { return nil }
        guard let result = try? scrypt.calculate() else { return nil }
        
        return Data(result)
    }
    
    static func getHash(_ value: String) -> String {
        return value.sha3(.sha256)
    }
    
    static func getHash(_ value: Data) -> Data {
        return value.sha3(.sha256)
    }
    
    static func createKeystore(privateKey: String, password: String) throws -> Keystore {
        let hexKey = privateKey.hexToData()!
        Log.Debug("hex: \(hexKey.hexEncodedString())")
        let prvKey = PrivateKey(hex: hexKey)
        Log.Debug("privateKey: \(prvKey.hexEncoded)")
        let iconWallet = Wallet(privateKey: prvKey)
        Log.Debug("address: \(iconWallet.address)")
        
        let saltCount = 32
        var randomBytes = Array<UInt8>(repeating: 0, count: saltCount)
        let err = SecRandomCopyBytes(kSecRandomDefault, saltCount, &randomBytes)
        if err != errSecSuccess { throw IXError.convertKey }
        let salt = Data(randomBytes)
        
        // HASH round
        let round = 16384
        
        guard let encKey = pbkdf2SHA256(password: password, salt: salt, keyByteCount: PBE_DKLEN, round: round) else {
            throw IXError.convertKey
        }
        let result = try encrypt(devKey: encKey, data: privateKey.hexToData()!, salt: salt)
        let kdfParam = Keystore.KDF(dklen: PBE_DKLEN, salt: salt.toHexString(), c: round, prf: "hmac-sha256")
        let crypto = Keystore.Crypto(ciphertext: result.cipherText, cipherparams: Keystore.CipherParams(iv: result.iv), cipher: "aes-128-ctr", kdf: "pbkdf2", kdfparams: kdfParam, mac: result.mac)
        let keystore = Keystore(address: iconWallet.address, crypto: crypto)
        return keystore
    }
    
    static func createPublicKey(privateKey: PrivateKey) -> String? {
        let flag = UInt32(SECP256K1_CONTEXT_SIGN)
        guard let ctx = secp256k1_context_create(flag) else { return nil }
        var rawPubkey = secp256k1_pubkey()
        
        guard secp256k1_ec_pubkey_create(ctx, &rawPubkey, privateKey.data.bytes) == 1 else { return nil }
        
        let serializedPubkey = UnsafeMutablePointer<UInt8>.allocate(capacity: 65)
        var pubLen = 65
        
        guard secp256k1_ec_pubkey_serialize(ctx, serializedPubkey, &pubLen, &rawPubkey, UInt32(SECP256K1_EC_UNCOMPRESSED)) == 1 else {
            secp256k1_context_destroy(ctx)
            return nil }
        
        secp256k1_context_destroy(ctx)
        
        let publicKey = Data(bytes: serializedPubkey, count: 65).toHexString()
        
        return String(publicKey.suffix(publicKey.length - 2))
    }
    
    static func makeAddress(_ prvKey: PrivateKey?, _ pubKey: PublicKey) -> String {
        var hash: Data
        if pubKey.data.count > 64 {
            hash = pubKey.data.subdata(in: 1...64)
            hash = hash.sha3(.sha256)
        } else {
            hash = pubKey.data.sha3(.sha256)
        }
        
        let sub = hash.suffix(20)
        let address = "hx" + String(sub.toHexString())
        
        if let privKey = prvKey {
            if checkAddress(privateKey: privKey, address: address) {
                return address
            } else {
                return makeAddress(privKey, pubKey)
            }
        }
        
        return address
    }
    
    static func checkAddress(privateKey: PrivateKey, address: String) -> Bool {
        let fixed = Date.timestampString.sha3(.sha256).hexToData()!
        
        guard var rsign = Cipher.ecdsaRecoverSign(privateKey: privateKey, hashed: fixed) else { return false }
        
        guard let vPub = verifyPublickey(hashedMessage: fixed, signature: &rsign), let hexPub = vPub.hexToData() else { return false }
        
        let vaddr = makeAddress(nil, PublicKey(hex: hexPub))
        
        return address == vaddr
    }
    
    static public func ecdsaRecoverSign(privateKey: PrivateKey, hashed: Data) -> secp256k1_ecdsa_recoverable_signature? {
        let flag = UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)
        
        guard let ctx = secp256k1_context_create(flag) else { return nil }
        var rsig = secp256k1_ecdsa_recoverable_signature()
        
        guard secp256k1_ecdsa_sign_recoverable(ctx, &rsig, hashed.bytes, privateKey.data.bytes, nil, nil) == 1 else {
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
}

let PBE_DKLEN = 32

public struct ICONUtil {

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
    
}



