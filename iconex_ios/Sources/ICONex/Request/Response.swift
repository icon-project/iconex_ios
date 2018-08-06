//
//  Response.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import Foundation

protocol IXResponseConvertible {
    var response: HTTPURLResponse? { get set }
    var request: IXRequestConvertible? { get set }
    var error: Error? { get set }
    var value: [String: Any]? { get set }
    var data: Data? { get set }
}

class IXJSONResponse: IXResponseConvertible {
    var response: HTTPURLResponse?
    var request: IXRequestConvertible?
    var error: Error?
    var value: [String: Any]?
    var data: Data?
}

class TxHistoryResponse: Codable {
    var txHash: String
    var createDate: String
    var from: String
    var to: String
    var amount: String
    var fee: String
    
    enum CodingKeys: String, CodingKey {
        case txHash
        case createDate
        case from = "fromAddr"
        case to = "toAddr"
        case amount
        case fee
    }
}


// For Exchange Informations
struct ExchangeResponse: Codable {
    var result: String
    var description: String
    var data: [ExchangeInfo]
}

struct ExchangeInfo: Codable {
    var marketName: String?
    var tradeName: String
    var createDate: String?
    var price: String
    var prePrice: String?
    var dailyRate: String?
}
