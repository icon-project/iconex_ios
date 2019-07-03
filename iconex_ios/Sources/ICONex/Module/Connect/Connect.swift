//
//  Connect.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import UIKit
import ICONKit
import BigInt

enum ConnectError: Error {
    case userCancel
    case invalidRequest
    case invalidJSON
    case decode
    case invalidBase64
    case invalidMethod
    case invalidParameter(ParameterKey)
    case walletEmpty
    case tokenEmpty
    case notFound(ParameterKey)
    case sameAddress
    case sign
    case insufficient(InsufficientError)
    case network(Any)
    case activateDeveloper
    
    enum ParameterKey {
        case command
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
            
        case .invalidRequest :
            return "Invalid request. Could not find data."
            
        case .invalidJSON, .decode:
            return "Parse error. (Invalid JSON type)"
            
        case .invalidBase64:
            return "Invalid base64 encoded string."
        
        case .invalidMethod:
            return "Invalid method."
            
        case .walletEmpty:
            return "ICONex has no ICX wallet."
            
        case .tokenEmpty:
            return "Could not find token in wallet"
            
        case .notFound(let key):
            switch key {
            case .command:
                return "Could not find command."
                
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
            return -1
            
        case .invalidMethod:
            return -1000
            
        case .invalidRequest:
            return -1001
            
        case .invalidBase64:
            return -1002
            
        case .invalidJSON, .decode:
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
            return -2000
        
        case .tokenEmpty:
            return -2003
            
        case .notFound(let detail):
            switch detail {
            case .command:
                return -1004
                
            case .wallet:
                return -3000
                
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
    var isConnect: Bool = false
    var auth: Bool = false
    
    var source: URL? = nil
    
    var action: String?
    
    var received: ConnectFormat?
    
    var isTranslated: Bool = false
    
    var needTranslate: Bool {
        return source != nil && !isTranslated
    }
    
    var tokenDecimal: Int?
    var tokenSymbol: String?
    
    public func setMessage(source: URL) {
        Log.Debug("Source - \(source)")
        self.reset()
        self.source = source
    }
    
    public func translate() throws {
        guard let source = self.source else { return }
        guard isTranslated == false else { return }
        isTranslated = true
        
        guard let components = URLComponents(url: source, resolvingAgainstBaseURL: false) else {
            self.source = nil
            throw ConnectError.invalidRequest
        }
        
        guard let host = components.host else { throw ConnectError.notFound(.command) }
        
        switch host {
        case "developer":
            UserDefaults.standard.set(true, forKey: "Developer")
            UserDefaults.standard.synchronize()
            
            self.source = nil
            self.sendError(error: .activateDeveloper)
            return
            
        case "bind":
            self.action = host
            
        case "JSON-RPC":
            self.action = host
            
        default:
            self.source = nil
            throw ConnectError.invalidParameter(.command)
        }
        
        guard let queries = components.queryItems else {
            self.source = nil
            throw ConnectError.invalidRequest

        }
        
        guard let dataQuery = queries.filter({ $0.name == "data" }).first, let dataParam = dataQuery.value else {
            self.source = nil
            throw ConnectError.invalidRequest

        }
        
        guard let data = Data(base64Encoded: dataParam) else {
            self.source = nil
            throw ConnectError.invalidBase64
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let received = try decoder.decode(ConnectFormat.self, from: data)
            self.received = received
        } catch {
            self.source = nil
            throw ConnectError.invalidJSON
        }

        if Conn.action == "JSON-RPC" {
            guard let from = Conn.received?.payload?.from else {
                self.source = nil
                throw ConnectError.notFound(.from)
            }
            guard let to = Conn.received?.payload?.to else {
                self.source = nil
                throw ConnectError.notFound(.to)
            }
            guard from != to else {
                self.source = nil
                throw ConnectError.sameAddress
            }
            
            guard Validator.validateICXAddress(address: from) else {
                self.source = nil
                throw ConnectError.invalidParameter(.from)
            }
            
            if Balance.tokenBalanceList.isEmpty {
                Balance.getWalletsBalance()
            }
            
            guard Validator.validateIRCAddress(address: to) else { return }
            
            let tokenSymbolCall = Call<String>(from: from, to: to, method: "symbol", params: nil)
            let tokenDecimalCall = Call<BigUInt>(from: from, to: to, method: "decimals", params: nil)
            
            let requestSymbol = WManager.service.call(tokenSymbolCall).execute()
            switch requestSymbol {
            case .success(let symbol):
                Conn.tokenSymbol = symbol
                
            case .failure:
                return
            }
            
            guard Balance.tokenBalanceList[from]?[to] != nil else {
                self.source = nil
                throw ConnectError.tokenEmpty
            }
            let requestDecimal = WManager.service.call(tokenDecimalCall).execute()
            switch requestDecimal {
            case .success(let decimal):
                Conn.tokenDecimal = Int(decimal)
            case .failure(let error):
                self.source = nil
                throw ConnectError.network(error)
            }
        }
    }
    
    public func sendBind(address: String) {
        let response = ConnectResponse(code: 0, message: "Success", result: address)
        
        self.callback(response: response)
        let app = UIApplication.shared.delegate as! AppDelegate
        app.toMain()
    }
    
    private func callback(response: ConnectResponse) {
        let encoder = JSONEncoder()
        
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        guard let encoded = try? encoder.encode(response), let redirect = self.received?.redirect, var component = URLComponents(string: redirect) else {
            self.reset()
            return
        }
        
        component.queryItems = [URLQueryItem(name: "data", value: encoded.base64EncodedString())]
        
        guard let url = component.url else { return }
        self.reset()
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    public func reset() {
        self.source = nil
        self.action = nil
        self.received = nil
        self.tokenDecimal = nil
        self.tokenSymbol = nil
        isTranslated = false
    }
    
    public func sendICXHash(txHash: String) {
        let response = ConnectResponse(code: 0, message: "Success", result: txHash)

        self.callback(response: response)

        let app = UIApplication.shared.delegate as! AppDelegate
        app.toMain()
    }
    
    public func sendError(error: ConnectError) {
        guard self.received?.redirect != nil else {
            let app = UIApplication.shared.delegate as! AppDelegate
            app.toMain()
            Tools.toast(message: error.errorDescription ?? "Unknown Error")
            return
        }
        let response = ConnectResponse(code: error.code, message: error.errorDescription ?? "Unknown Error", result: nil)
        
        self.callback(response: response)
        let app = UIApplication.shared.delegate as! AppDelegate
        app.toMain()
    }
}

let Conn = Connect.shared

struct ConnectFormat: Decodable {
    var redirect: String
    var payload: ConnectTransaction?
}

struct ConnectResponse: Encodable {
    var code: Int
    var message: String
    var result: String?
}

struct ConnectTransaction: Decodable {
    // required
    var from: String
    var to: String
    
    // optional
    var value: String?
    var nonce: String?
    var dataType: String?
    var data: DataValue?
    
    struct CallData: Decodable {
        public var method: String
        public var params: [String: Any]?
        
        enum CodingKeys: CodingKey {
            case method, params
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            self.method = try values.decode(String.self, forKey: .method)
            self.params = try values.decode(Dictionary<String, Any>.self, forKey: .params)
        }
    }
    
    enum DataValue: Decodable {
        case call(CallData)
        case message(String)
        
        public init(from decoder: Decoder) throws {
            if let call = try? decoder.singleValueContainer().decode(CallData.self) {
                self = .call(call)
                return
            }
            else if let message = try? decoder.singleValueContainer().decode(String.self) {
                self = .message(message)
                return
            }
            throw ConnectError.invalidParameter(.data)
        }
    }
}

class ConnectManager {
    static let shared = ConnectManager()
    var provider: ICONService = WManager.service
}

let ConnManager = ConnectManager.shared
