//
//  Tracker.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import Result

open class Tracker {
    public struct TxList: Hashable {
        var contractAddr: String
        var symbol: String
        var txHash: String
        var height: String
        var createDate: String
        var fromAddr: String
        var toAddr: String
        var txType: String?
        var dataType: String
        var amount: String
        var fee: String
        var state: Int
        var targetContractAddr: String
        var quantity: String
        var age: String
        var id: String
        
        init(dic: [String: Any]) {
            self.txHash = dic["txHash"] as? String ?? ""
            self.height = dic["height"] as? String ?? ""
            self.createDate = dic["createDate"] as? String ?? ""
            self.fromAddr = dic["fromAddr"] as? String ?? ""
            self.toAddr = dic["toAddr"] as? String ?? ""
            self.txType = dic["txType"] as? String
            self.dataType = dic["dataType"] as? String ?? ""
            self.amount = dic["amount"] as? String ?? ""
            self.fee = dic["fee"] as? String ?? ""
            self.state = dic["state"] as? Int ?? 0
            self.targetContractAddr = dic["targetContractAddr"] as? String ?? ""
            self.contractAddr = dic["contractAddr"] as? String ?? ""
            self.symbol = dic["symbol"] as? String ?? ""
            self.quantity = dic["quantity"] as? String ?? ""
            self.age = dic["age"] as? String ?? ""
            self.id = dic["id"] as? String ?? ""
        }
        
        public static func == (lhs: TxList, rhs: TxList) -> Bool {
            return lhs.txHash == rhs.txHash
        }
    }
    
    public enum TrackerHost: String {
        case main = "https://tracker.icon.foundation"
        case dev = "https://trackerdev.icon.foundation"
        case local = "http://trackerlocaldev.icon.foundation"
    }
    
    enum Method: String {
        case getTransactionByAddress = "address/txListForWallet"
        case getExchangeList = "exchange/currentExchangeList"
        case getTokenTransactionList = "token/txList"
    }
    
    enum TXType: Int {
        case icxTransfer = 0
        case tokenTransfer = 1
    }
    
    public var provider: String
    
    init(_ provider: TrackerHost) {
        self.provider = provider.rawValue
    }
    
    public static func main() -> Tracker {
        return Tracker(.main)
    }
    
    public static func dev() -> Tracker {
        return Tracker(.dev)
    }
    
    public static func local() -> Tracker {
        return Tracker(.local)
    }
    
    func exchangeData(list: String) -> Data? {
        let result = send(method: .getExchangeList, params: ["codeList": list])
        
        switch result {
        case .success(let response):
            guard let data = response["data"] as? [[String: String?]] else { return nil }
            return try? JSONSerialization.data(withJSONObject: data, options: [])
            
        case .failure(let error):
            Log.Debug("exchange error - \(error)")
            
        }
        return nil
    }
    
    func transactionList(address: String, page: Int, txType: TXType) -> [String: Any]? {
        let result = send(method: .getTransactionByAddress, params: ["address": address, "page": page, "type": txType.rawValue])
        
        switch result {
        case .success(let response):
            return response
            
        case .failure(let error):
            Log.Debug("Error - \(error)")
        }
        
        return nil
    }
    
    func tokenTxList(address: String, contractAddress: String, page: Int) -> [String: Any]? {
        let result = send(method: .getTokenTransactionList, params: ["tokenAddr": address, "contractAddr": contractAddress, "page": page])
        
        switch result {
        case .success(let resopnse):
            return resopnse
            
        case .failure(let error):
            Log.Debug("Error - \(error)")
        }
        
        return nil
    }
    
    private func send(method: Tracker.Method, params: [String: Any]) -> Result<[String: Any], TrackerResult> {
        guard let provider = URL(string: self.provider) else { return .failure(.provider) }
        
        let request = TrackerRequest(provider: provider, method: method, params: params)
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        var data: Data?
        var response: HTTPURLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = session.dataTask(with: request.asURLRequest()) {
            data = $0
            response = $1 as? HTTPURLResponse
            error = $2
            
            semaphore.signal()
        }
        task.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        guard error == nil, response?.statusCode == 200, let value = data else { return .failure(TrackerResult.httpError) }
        
        guard let parsed = try? JSONSerialization.jsonObject(with: value, options: []) as! [String: Any] else { return .failure(TrackerResult.parsing) }
        
        return .success(parsed)
    }
}

open class TrackerRequest {
    var provider: URL
    var method: Tracker.Method
    var params: [String: Any]
    
    public func asURLRequest() -> URLRequest {
        var url = provider.appendingPathComponent(self.method == .getExchangeList ? "v0" : "v3")
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
    
    init(provider: URL, method: Tracker.Method, params: [String: Any]) {
        self.provider = provider
        self.method = method
        self.params = params
    }
    
    var timestamp: String {
        return Date.timestampString
    }

}

open class TrackerResponse {
    var value: [String: Any]?
}

enum TrackerResult: Error {
    case httpError
    case noSuchKey(String)
    case provider
    case parsing
    case unknown
}
