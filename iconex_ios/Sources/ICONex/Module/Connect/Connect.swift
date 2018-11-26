//
//  Connect.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import UIKit

enum ConnectError: Error {
    case userCancel
    case invalidRequest
    case invalidMethod
    case invalidJSON
    case invalidParameter(ParameterKey)
    case walletEmpty
    case notFound(ParameterKey)
    case sameAddress
    case decode
    case sign
    case insufficient(InsufficientError)
    case network(Any)
    case activateDeveloper
    
    enum ParameterKey {
        case caller
        case wallet(String)
        case id
        case method
        case from
        case version
        case to
        case value
        case timestamp
        case stepLimit
        case nid
        case nonce
        case dataType
        case data
        case address
        case contractAddress
    }
    
    enum InsufficientError: String {
        case balance
        case fee
    }
}

extension ConnectError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .userCancel:
            return "Operation canceled by user."
            
        case .decode:
            return "Parse error. (Invalid JSON type)"
            
        case .invalidRequest, .invalidJSON:
            return "Invalid request."
            
        case .invalidMethod:
            return "Invalid method."
            
        case .walletEmpty:
            return "ICONex has no ICX wallet."
            
        case .notFound(let key):
            switch key {
            case .caller:
                return "Could not find caller."
                
            case .wallet(let address):
                return "Could not find matched wallet. ('\(address)')"
                
            default:
                return "Not found parameter. ('\(key)')"
            }
            
        case .sameAddress:
            return "Sending and receiving address are same"
            
        case .insufficient(let state):
            switch state {
            case .balance:
                return "Insufficient balance."
                
            case .fee:
                return "Insufficient balance for fee."
            }
            
        case .invalidParameter(let param):
            return "Invalid parameter ('\(param)')"
            
        case .sign:
            return "Failed to sign."
            
        case .network(let message):
            return "Somethings wrong with network. ('\(message)')"
            
        case .activateDeveloper:
            return "Developer mode activated."
        }
    }
}

extension ConnectError {
    public var code: Int {
        switch self {
        case .userCancel:
            return -1000
            
        case .invalidJSON, .decode:
            return -1001
            
        case .invalidRequest:
            return -1002
            
        case .invalidMethod:
            return -1003
            
        case .sameAddress:
            return -3002
            
        case .invalidParameter:
            return -3005
            
        case .insufficient(let insufficient):
            switch insufficient {
            case .balance:
                return -3003
                
            case .fee:
                return -3004
            }
            
        case .walletEmpty:
            return -2001
            
        case .notFound(let detail):
            switch detail {
            case .caller:
                return -1004
                
            case .wallet:
                return -3001
                
            default:
                return -2002
            }
            
        case .sign:
            return -4001
            
        case .network:
            return -9999
            
        case .activateDeveloper:
            return 9
        }
    }
}

class Connect {
    static let shared = Connect()
    
    var source: URL? = nil
    
    var caller: String!
    var received: ConnectFormat?
    
    var isTranslated: Bool = false
    var needTranslate: Bool {
        return source != nil && !isTranslated
    }
    
    var action: String? {
        return received?.method
    }
    
    private init() {}
    
    public func setMessage(source: URL) {
        Log.Debug("Source - \(source)")
        self.source = source
    }
    
    public func translate() throws {
        guard let source = self.source else { return }
        guard isTranslated == false else { return }
        isTranslated = true
        
        // Check request for developer mode
        guard let components = URLComponents(url: source, resolvingAgainstBaseURL: false) else {
            self.source = nil
            throw ConnectError.invalidRequest }
        
        if let host = components.host, host.lowercased() == "developer" {
            // Activating developer mode
            UserDefaults.standard.set(true, forKey: "Developer")
            UserDefaults.standard.synchronize()
            
            
            self.reset()
            throw ConnectError.activateDeveloper
        }
        
        
        guard let queries = components.queryItems else {
            self.source = nil
            throw ConnectError.invalidRequest
        }
        
        guard let fromQuery = queries.filter({ $0.name == "caller" }).first, let from = fromQuery.value else {
            self.source = nil
            throw ConnectError.notFound(.caller)
        }
        self.caller = from
        
        guard let dataQuery = queries.filter({ $0.name == "data" }).first, let dataParam = dataQuery.value else {
            self.source = nil
            throw ConnectError.notFound(.data)
        }
        
        guard let data = Data(base64Encoded: dataParam) else {
            self.source = nil
            throw ConnectError.decode
        }
        
        let decoder = JSONDecoder()
        
        let received = try decoder.decode(ConnectFormat.self, from: data)
        self.received = received
        
        if Conn.action == "bind" {
            
        } else {
            guard Conn.received?.params?["from"] != nil else { throw ConnectError.notFound(.from) }
            guard Conn.received?.params?["to"] != nil else { throw ConnectError.notFound(.to) }
            guard Conn.received?.params?["value"] != nil else { throw ConnectError.notFound(.value) }
            
            switch Conn.action {
            case "sign":
                guard Conn.received?.params?["stepLimit"] != nil else { throw ConnectError.notFound(.stepLimit) }
                guard Conn.received?.params?["timestamp"] != nil else { throw ConnectError.notFound(.timestamp) }
                guard Conn.received?.params?["nid"] != nil else { throw ConnectError.notFound(.nid) }
                guard Conn.received?.params?["nonce"] != nil else { throw ConnectError.notFound(.nonce) }
                
            case "sendICX":
                break
                
            case "sendToken":
                guard Conn.received?.params?["contractAddress"] != nil else { throw ConnectError.notFound(.contractAddress) }
                break
                
            default:
                throw ConnectError.notFound(.method)
            }
        }
    }
    
    public func sendBind(address: String) {
        let response = ConnectResponse(id: self.received!.id, code: 1, result: address)
        
        self.callback(response: response)
        let app = UIApplication.shared.delegate as! AppDelegate
        app.toMain()
    }
    
    public func sendSignature(sign: String) {
        let response = ConnectResponse(id: self.received!.id, code: 1, result: sign)
        
        self.callback(response: response)
        let app = UIApplication.shared.delegate as! AppDelegate
        app.toMain()
    }
    
    public func sendICXHash(txHash: String) {
        let response = ConnectResponse(id: self.received!.id, code: 1, result: txHash)
        
        self.callback(response: response)
        
        let app = UIApplication.shared.delegate as! AppDelegate
        app.toMain()
    }
    
    public func sendTokenHash(txHash: String) {
        let response = ConnectResponse(id: self.received!.id, code: 1, result: txHash)
        
        self.callback(response: response)
        let app = UIApplication.shared.delegate as! AppDelegate
        app.toMain()
    }
    
    public func sendError(error: ConnectError) {
        let response = ConnectResponse(id: self.received!.id, code: error.code, result: error.errorDescription)
        
        self.callback(response: response)
        let app = UIApplication.shared.delegate as! AppDelegate
        app.toMain()
    }
    
    private func callback(response: ConnectResponse) {
        let encoder = JSONEncoder()
        
        guard let encoded = try? encoder.encode(response), let caller = self.caller, var component = URLComponents(string: caller) else {
            return
        }
        
        component.queryItems = [URLQueryItem(name: "data", value: encoded.base64EncodedString())]
        
        guard let url = component.url else { return }
        self.reset()
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    public func reset() {
        self.source = nil
        self.caller = nil
        self.received = nil
        isTranslated = false
    }
}

let Conn = Connect.shared

struct ConnectFormat: Decodable {
    var id: Int
    var method: String
    var params: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id, method, origin, params
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.id) {
            self.id = try container.decode(Int.self, forKey: .id)
        } else {
            throw ConnectError.notFound(.id)
        }
        if container.contains(.method) {
            self.method = try container.decode(String.self, forKey: .method)
        } else {
            throw ConnectError.notFound(.method)
        }
        if container.contains(.params) {
            self.params = try container.decode([String: Any].self, forKey: .params)
        }
    }
}

struct ConnectResponse: Encodable {
    var id: Int
    var code: Int
    var result: String?
    
    enum CodingKeys: String, CodingKey {
        case id, code, result
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(code, forKey: .code)
        if let result = self.result {
            try container.encode(result, forKey: .result)
        }
    }
}
