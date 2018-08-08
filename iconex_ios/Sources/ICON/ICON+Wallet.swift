/*
 * Copyright 2018 ICON Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import Foundation


// MARK: Wallet

extension ICON.Wallet {
    
    convenience init(keystore: ICON.Keystore) {
        self.init()
        self.keystore = keystore
    }
    
    convenience init(privateKey: String?, password: String) {
        self.init()
        self.keystore = self.createKeystore(privateKey, password)
    }
    
    private func createKeystore(_ privateKey: String?, _ password: String) -> ICON.Keystore? {
        do {
            var key: String
            if let prvKey = privateKey {
                key = prvKey
            } else {
                key = ICONUtil.generatePrivateKey()
            }
            
            guard let publicKey = ICONUtil.createPublicKey(privateKey: key) else {
                return nil
            }
            
            let address = ICONUtil.makeAddress(privateKey, publicKey)
            
            let saltCount = 32
            var randomBytes = Array<UInt8>(repeating: 0, count: saltCount)
            let err = SecRandomCopyBytes(kSecRandomDefault, saltCount, &randomBytes)
            if err != errSecSuccess { return nil }
            let salt = Data(bytes: randomBytes)
            
            // HASH round
            let round = 16384
            
            guard let encKey = Cipher.pbkdf2SHA256(password: password, salt: salt, keyByteCount: ICONUtil.PBE_DKLEN, round: round) else {
                return nil
            }
            
            let result = try ICONUtil.encrypt(devKey: encKey, data: key.hexToData()!, salt: salt)
            let kdfParam = ICON.KDF(dklen: ICONUtil.PBE_DKLEN, salt: salt.toHexString(), c: 16384, prf: "hmac-sha256")
            let crypto = ICON.Crypto(ciphertext: result.cipherText, cipherparams: ICON.CipherParams(iv: result.iv), cipher: "aes-128-ctr", kdf: "pbkdf2", kdfparams: kdfParam, mac: result.mac)
            let keyStore = ICON.Keystore(address: address, crypto: crypto)
            
            return keyStore
        } catch {
            Log.Debug(error)
            return nil
        }
    }
    
    
    /// Re-generate keystore with new password
    ///
    /// - Parameters:
    ///   - current: Current password
    ///   - new: New password
    /// - Returns: success or fail
    func changePassword(current: String, new: String) -> Bool {
        guard let keyStore = self.keystore, let prvKey = self.extractPrivateKey(password: current) else { return false }
        
        let publicKey = ICONUtil.createPublicKey(privateKey: prvKey)
        let newAddress = ICONUtil.makeAddress(prvKey, publicKey!)
        
        if newAddress == keyStore.address {
            if let keystore = self.createKeystore(prvKey, new) {
                self.keystore = keystore
                return true
            }
        }
        
        return false
    }
    
    func verifyPassword(password: String) -> Bool {
        guard let keyStore = self.keystore, let extracted = self.extractPrivateKey(password: password) else { return false }
        
        guard let publicKey = ICONUtil.createPublicKey(privateKey: extracted) else { return false }
        
        let address = ICONUtil.makeAddress(extracted, publicKey)
        Log.Debug(address)
        
        return keyStore.address == address
    }
    
    func extractPrivateKey(password: String) -> String? {
        guard let keyStore = self.keystore else { return nil }
        let enc = keyStore.crypto.ciphertext.hexToData()!
        let iv = keyStore.crypto.cipherparams.iv.hexToData()!
        let salt = keyStore.crypto.kdfparams.salt.hexToData()!
        let count = keyStore.crypto.kdfparams.c
        
        // keystore 생성시 사용한 Password 를 이용하여 PrivateKey를 추출
        guard let devKey = Cipher.pbkdf2SHA256(password: password, salt: salt, keyByteCount: ICONUtil.PBE_DKLEN, round: count) else { return nil }
        
        let decrypted = try! ICONUtil.decrypt(devKey: devKey, enc: enc, dkLen: ICONUtil.PBE_DKLEN, iv: iv)
        
        return decrypted.decryptText
    }
    
    /// Signing
    ///
    /// - Parameters:
    ///   - password: Wallet's password
    ///   - data: Data
    /// - Returns: Signed.
    /// - Throws: exceptions
    func getSignature(password: String, data: Data) throws -> String {
        
        guard let privateKey = self.extractPrivateKey(password: password) else { throw IXError.invalidKeystore }
        
        let hash = data.sha3(.sha256)
        
        let sign = try ICONUtil.signECDSA(hashedMessage: hash, privateKey: privateKey)
        
        guard let ser_rsign = sign.signature, let recid = sign.recid else {
            throw IXError.sign
        }
        
        var rsign = ser_rsign.bytes
        rsign.removeLast()
        rsign.append(contentsOf: recid.hexToData()!.bytes)
        
        let signature = Data(bytes: rsign)
        
        return signature.base64EncodedString()
        
    }
    
    
    
    /// Convert keystore struct to JSON Object
    ///
    /// - Returns: JSON Object data
    func keystoreToJSON() -> Data? {
        guard let keystore = self.keystore else { return nil }
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(keystore)
            
            return data
        } catch {
            Log.Debug(error)
        }
        
        return nil
    }
    
    /// Keystore 파일로부터 지갑 객체
    func loadKeystore(jsonData: Data) {
        let decoder = JSONDecoder()
        do {
            let keystore = try decoder.decode(ICON.Keystore.self, from: jsonData)
            self.keystore = keystore
        } catch {
            Log.Debug(error)
        }
    }
}

