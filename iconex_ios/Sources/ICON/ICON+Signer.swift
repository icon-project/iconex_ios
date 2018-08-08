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
