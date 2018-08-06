//
//  ICON+Signer.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import Foundation

extension ICON {
    
    class TransactionSigner {
        var params: [String: String]?
        
        private func makeSingingData() -> Data? {
            guard let params = self.params else { return nil }
            
            var tbs = METHOD.sendTransaction.rawValue
            
            for key in params.keys.sorted() {
                guard let value = params[key] else { continue }
                tbs += "." + key + "." + value
            }
            
            return tbs.data(using: .utf8)
        }
        
        func getTxHash() -> String? {
            guard let tbs = self.makeSingingData() else { return nil }
            
            let hashed = tbs.sha3(.sha256)
            
            return hashed.toHexString()
        }
        
        func getSignature(key: String) -> String? {
            guard let tbs = self.makeSingingData() else { return nil }
            let hashed = tbs.sha3(.sha256)
            do {
                let sign = try ICONUtil.signECDSA(hashedMessage: hashed, privateKey: key)
                
                guard let ser_rsign = sign.signature, let recid = sign.recid else {
                    return nil
                }
                
                var rsign = ser_rsign.bytes
                rsign.removeLast()
                rsign.append(contentsOf: recid.hexToData()!.bytes)
                
                let signature = Data(bytes: rsign)
                
                return signature.base64EncodedString()
            } catch {
                return nil
            }
        }
    }
}
