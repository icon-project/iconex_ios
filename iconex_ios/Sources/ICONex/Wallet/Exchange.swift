//
//  Exchange.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import Foundation
import Alamofire

class ExchangeManager {
    static let sharedInstance = ExchangeManager()
    private init() {}
    
    var exchangeList = "icxeth,icxbtc,icxusd,ethusd,ethbtc,etheth"
    
    var exchangeInfoList = [String: ExchangeInfo]()
    var currentExchange: String = "usd"
    
    func getExchangeList() {
        
        
        
        
        
        
        let request = ICON.V2.ExchangeRequest(list: exchangeList)
        
        Alamofire.request(request).responseData { (response) in
            switch response.result {
            case .success:
                guard let value = response.value else { return }
                
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(ExchangeResponse.self, from: value)
                    
                    for info in result.data {
                        self.exchangeInfoList[info.tradeName] = info
                    }
//                    Log.Debug("exchange info : \(self.exchangeInfoList)")
                } catch {
                    Log.Debug("\(error)")
                }
                NotificationCenter.default.post(name: NSNotification.Name("kNotificationExchangeListDidChanged"), object: nil)
                
            default:
                return
            }
        }
    }
    
    func addToken(_ item: String) {
        let lowerCased = item.lowercased()
        var expected = "\(lowerCased)eth"
        if !exchangeList.contains(expected) {
            exchangeList.append("," + expected)
        }
        expected = "\(lowerCased)btc"
        if !exchangeList.contains(expected) {
            exchangeList.append("," + expected)
        }
        expected = "\(lowerCased)usd"
        if !exchangeList.contains(expected) {
            exchangeList.append("," + expected)
        }
    }
}

let EManager = ExchangeManager.sharedInstance
