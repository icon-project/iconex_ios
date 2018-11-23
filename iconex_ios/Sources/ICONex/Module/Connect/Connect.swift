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
    case invalidJSON
    case walletEmpty
    case notFound(DetailError)
    case encode
    case decode
    case sign
    
    enum DetailError: String {
        case wallet
        case id
        case method
        case from
        case version
        case to
        case value
        case timestamp
        case nid
        case nonce
        case dataType
        case data
    }
}

extension ConnectError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        default:
            return "Unknown error"
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
            return -1003
            
        case .walletEmpty:
            return -2001
            
        case .notFound(let detail):
            switch detail {
            case .wallet:
                return -3001
                
            default:
                return -2002
            }
            
        case .sign:
            return -4001
            
        default:
            return 1
        }
    }
}

class Connect {
    var source: URL?
    
    var from: String?
    var received: ConnectFormat?
    
    init(source: URL) {
        self.source = source
    }
    
    public func translate() throws {
        guard let source = self.source else { return }
        
        guard let components = URLComponents(url: source, resolvingAgainstBaseURL: false), let queries = components.queryItems else {
            self.source = nil
            throw ConnectError.invalidRequest
        }
        
        guard let fromQuery = queries.filter({ $0.name == "from" }).first, let from = fromQuery.value else {
            self.source = nil
            throw ConnectError.notFound(.from)
        }
        self.from = from
        
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
        
        if received.method == "bind" {
            self.bind()
        } else if received.method == "sign" {
            
        } else if received.method == "sendICX" {
            
        } else if received.method == "sendToken" {
            
        } else {
            throw ConnectError.notFound(.method)
        }            
    }
    
    public func callback(response: ConnectResponse) {
        let encoder = JSONEncoder()
        
        guard let encoded = try? encoder.encode(response), let from = self.from, var component = URLComponents(string: from) else {
            
            return
        }
        
        component.queryItems = [URLQueryItem(name: "data", value: encoded.base64EncodedString())]
        
        guard let url = component.url else { return }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    private func bind() {
        let app = UIApplication.shared.delegate as! AppDelegate
        
        if let top = app.topViewController() {
            let bind = UIStoryboard(name: "Connect", bundle: nil).instantiateViewController(withIdentifier: "BindView")
            top.present(bind, animated: false, completion: nil)
        }
    }
}

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
