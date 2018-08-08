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
import Alamofire


enum METHOD: String {
    case sendTransaction = "icx_sendTransaction"
    case getBalance = "icx_getBalance"
    case getTransactionResult = "icx_getTransactionResult"
    case getLastBlock = "icx_getLastBlock"
    case getBlockByHash = "icx_getBlockByHash"
    case getBlockByHeight = "icx_getBlockBytHeight"
    case getTransactionByAddress = "wallet/walletDetailTxList"
    case getTotalSupply = "icx_getTotalSupply"
    case getExchangeList = "exchange/currentExchangeList"
    case callMethod = "icx_call"
    case getScoreAPI = "icx_getScoreApi"
}


@available(*, deprecated)
public enum RequestHost {
    case engine
    case tracker
}

@available(*, deprecated)
protocol IXRequestConvertible: URLRequestConvertible {
    func asURLRequest() throws -> URLRequest
    var method: METHOD { get set }
    var params: [String: Any] { get set }
    var id: String { get set }
    var requestOrigin: RequestHost { get set }
}

extension ICON {
    @available(*, deprecated)
    public struct V2 {}
}

extension ICON.V2 {
    static let TRACKER_VERSION: String = "v0"
    static let EXCHANGE_HEADER: String = "exchange"
    static let GET_VERSION_PATH: String = "app/ios.json"
    
    static var TRUSTED_HOST: String {
        if Config.isTestnet {
            return "https://testwallet.icon.foundation"
        } else {
            return "https://wallet.icon.foundation"
        }
    }
    
    static var TRACKER_HOST: String {
        if Config.isTestnet {
            return "https://trackerdev.icon.foundation"
        } else {
            return "https://tracker.icon.foundation"
        }
    }
    
    class TransactionRequest: IXRequestConvertible {
        let API_VERSION = "v2"
        let jsonrpc = "2.0"
        var method: METHOD
        var params: [String: Any]
        var id: String
        var requestOrigin: RequestHost = .engine
        
        func asURLRequest() throws -> URLRequest {
            
            switch requestOrigin {
            case .engine:
                var url = URL(string: TRUSTED_HOST)!
                url = url.appendingPathComponent("api").appendingPathComponent(API_VERSION)
                var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
                request.httpMethod = "POST"
                let req = ["jsonrpc": jsonrpc, "method": method.rawValue, "params": params, "id": id] as [String : Any]
                let data = try JSONSerialization.data(withJSONObject: req, options: [])
                
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
                
                request.httpBody = data
                
                return request
                
            case .tracker:
                var url = URL(string: TRACKER_HOST)!
                url = url.appendingPathComponent(TRACKER_VERSION)
                url = url.appendingPathComponent(method.rawValue)
                
                var urlComponent = URLComponents(string: url.absoluteString)
                var queries = [URLQueryItem]()
                for item in params {
                    queries.append(URLQueryItem(name: item.key, value: String("\(item.value)")))
                }
                urlComponent!.queryItems = queries
                
                var request = URLRequest(url: urlComponent!.url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
                request.httpMethod = "GET"
                
                return request
            }
        }
        
        init(method: METHOD, params: [String: Any], id: String) {
            self.method = method
            self.params = params
            self.id = id
        }
        
        var timestamp: String {
            return Date.timestampString
        }
    }
    
    class TransactionSigner {
        private let _method: METHOD = .sendTransaction
        private var _tbs: Data = Data()
        
        init(fee: String, from: String, to: String, timestamp: String, value: String, nonce: String) {
            _tbs = makeTBS(fee: fee, from: from, timestamp: timestamp, to: to, value: value, nonce: nonce)
        }
        
        init(fee: String, from: String, to: String, timestamp: String, value: String) {
            _tbs = makeTBS(fee: fee, from: from, timestamp: timestamp, to: to, value: value, nonce: nil)
        }
        
        func makeTBS(fee: String, from: String, timestamp: String, to: String, value: String, nonce: String?) -> Data {
            var tbs: String = _method.rawValue + ".fee." + fee + ".from." + from
            if let _nonce = nonce {
                tbs = tbs + ".nonce." + _nonce
            }
            tbs = tbs + ".timestamp." + timestamp + ".to." + to + ".value." + value
            Log.Debug("tbs: \(tbs)")
            return tbs.data(using: .utf8)!
        }
        
        func getTxHash() -> String {
            let hash = _tbs.sha3(.sha256)
            
            return hash.toHexString()
        }
        
        func getSignature(hexPrivateKey: String) throws -> String {
            
            let hash = _tbs.sha3(.sha256)
            
            do {
                let sign = try ICONUtil.signECDSA(hashedMessage: hash, privateKey: hexPrivateKey)
                
                guard let ser_rsign = sign.signature else {
                    throw IXError.sign
                }
                
                guard let recid = sign.recid else {
                    throw IXError.sign
                }
                
                var rsign = ser_rsign.bytes
                rsign.removeLast()
                rsign.append(contentsOf: recid.hexToData()!.bytes)
                
                let signature = Data(bytes: rsign)
                
                Log.Debug("rsign\n\(rsign)\nsignature\n\(signature)")
                
                return signature.base64EncodedString()
            } catch {
                throw IXError.sign
            }
        }
    }
    
    class BalanceRequest: TransactionRequest {
        init(id: String, address: String) {
            super.init(method: .getBalance, params: ["address": address], id: id)
        }
    }
    
    class TransactionResultRequest: TransactionRequest {
        init(id: String, txHash: String) {
            super.init(method: .getTransactionResult, params: ["tx_hash": txHash], id: id)
        }
    }
    
    class SendTransactionRequest: TransactionRequest {
        private let FEE: String = "0x2386f26fc10000"
        
        var txHash: String?
        
        init(id: String, from: String, to: String, value: String, nonce: String?, hexPrivateKey: String) {
            var signer: TransactionSigner
            
            let timestamp = Date.microTimestamp
            
            if let non = nonce {
                signer = TransactionSigner(fee: FEE, from: from, to: to, timestamp: timestamp, value: value, nonce: non)
            } else {
                signer = TransactionSigner(fee: FEE, from: from, to: to, timestamp: timestamp, value: value)
            }
            
            let txHash = signer.getTxHash()
            self.txHash = txHash
            
            let signature = try! signer.getSignature(hexPrivateKey: hexPrivateKey)
            
            var params = [String: Any]()
            params["from"] = from
            params["to"] = to
            params["value"] = value
            params["fee"] = FEE
            params["timestamp"] = timestamp
            if let non = nonce {
                params["nonce"] = non
            }
            params["tx_hash"] = txHash
            params["signature"] = signature
            
            super.init(method: .sendTransaction, params: params, id: id)
        }
    }
    
    class TransactionHistoryRequest: TransactionRequest {
        init(address: String, next: Int = 0) {
            super.init(method: .getTransactionByAddress, params: ["address": address, "page": next], id: "")
            Log.Debug("transaction\n\(self.params)")
            self.requestOrigin = .tracker
        }
    }
    
    class ExchangeRequest: TransactionRequest {
        init(list: String) {
            super.init(method: .getExchangeList, params: ["codeList": list], id: "")
            self.requestOrigin = .tracker
        }
    }
}





extension ICON {
    static let version = "0x3"
    
    static var ICON_HOST: String {
        if Config.isTestnet {
            return "https://testwallet.icon.foundation"
        } else {
            return "https://wallet.icon.foundation"
        }
    }
    static var TRACKER_HOST: String {
        if Config.isTestnet {
            return "https://trackerdev.icon.foundation"
        } else {
            return "https://tracker.icon.foundation"
        }
    }
    
    static let TRACKER_VERSION: String = "v0"
    static let EXCHANGE_PATH: String = "exchange"
    static let VERSION_PATH: String = "app/ios.json"
}

protocol ICONRequestConvertible: URLRequestConvertible {
    var method: METHOD { get set }
    var id: String { get set }
    var params: [String: Any] { get set }
    var jsonrpc: String { get }
    var timestamp: String { get }
}

extension ICONRequestConvertible {
    var jsonrpc: String { return "2.0" }
    var timestamp: String { return Date.timestampString }
    
}

extension ICON {
    
    class TransactionRequest: ICONRequestConvertible {
        let API_VERSION_PATH = "v3"
        var method: METHOD
        var params: [String: Any]
        var id: String
        
        func asURLRequest() throws -> URLRequest {
            var url = URL(string: ICON.ICON_HOST)!
            url = url.appendingPathComponent("api").appendingPathComponent(API_VERSION_PATH)
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            request.httpMethod = "POST"
            let req = ["jsonrpc": jsonrpc, "method": method.rawValue, "params": params, "id": id] as [String : Any]
            let data = try JSONSerialization.data(withJSONObject: req, options: [])
            
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            request.httpBody = data
            
            return request
        }
        
        init(method: METHOD, params: [String: Any], id: String) {
            self.method = method
            self.params = params
            self.id = id
        }
    }
    
    class TrackerRequest: ICONRequestConvertible {
        var method: METHOD
        var id: String
        var params: [String : Any]
        
        func asURLRequest() throws -> URLRequest {
            var url = URL(string: TRACKER_HOST)!
            url = url.appendingPathComponent(TRACKER_VERSION)
            url = url.appendingPathComponent(method.rawValue)
            
            var urlComponent = URLComponents(string: url.absoluteString)
            var queries = [URLQueryItem]()
            for item in params {
                queries.append(URLQueryItem(name: item.key, value: String("\(item.value)")))
            }
            urlComponent!.queryItems = queries
            
            var request = URLRequest(url: urlComponent!.url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            request.httpMethod = "GET"
            
            return request
        }
        
        init(method: METHOD, params: [String: Any], id: String) {
            self.method = method
            self.params = params
            self.id = id
        }
    }
}

// Requests for ICON network
extension ICON {
    // MARK: Queries
    
    class StepPriceRequest: TransactionRequest {
        init(id: String, to: String) {
            let params: [String: Any] = ["version": ICON.version, "to": to, "dataType": "call", "data": ["method": "getStepPrice"]]
            
            super.init(method: .callMethod, params: params, id: id)
        }
    }
    
    class ScoreAPIRequest: TransactionRequest {
        init(id: String, contractAddress: String) {
            let params: [String: Any] = ["address": contractAddress]
            
            super.init(method: .getScoreAPI, params: params, id: id)
        }
    }
    
    class BalanceRequest: TransactionRequest {
        init(id: String, address: String) {
            super.init(method: .getBalance, params: ["address": address], id: id)
        }
    }
}

extension ICON {
    // MARK: Transactions
    class SendTransactionRequest: TransactionRequest {
        init(id: String, from: String, to: String, privateKey: String, nonce: String?, value: String?, dataString: String?, stepLimit: String, nid: String) {
            
            var signerParams = [String: String]()
            
            signerParams["version"] = ICON.version
            signerParams["from"] = from
            signerParams["to"] = to
            if let hexNonce = nonce {
                signerParams["nonce"] = hexNonce
            }
            if let hexValue = value {
                signerParams["value"] = hexValue
            }
            if let hexData = dataString {
                signerParams["dataType"] = "message"
                signerParams["data"] = hexData.add0xPrefix()
            }
            signerParams["stepLimit"] = stepLimit
            signerParams["timestamp"] = Date.microTimestamp
            
            super.init(method: .sendTransaction, params: signerParams, id: id)
        }
    }
}

extension ICON {
    // MARK: Tracker
    
    class TransactionHistoryRequest: TrackerRequest {
        init(address: String, page: Int = 0) {
            let params: [String: Any] = ["address": address, "page": page]
            super.init(method: .getTransactionByAddress, params: params, id: "")
        }
    }
    
    class ExchangeRequest: TrackerRequest {
        init(list: String) {
            super.init(method: .getExchangeList, params: ["codeList": list], id: "")
        }
    }
}
