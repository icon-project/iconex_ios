//
//  Exchange.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import ICONKit

class ExchangeManager {
    static let sharedInstance = ExchangeManager()
    private init() {}
    
    var exchangeList = "icxeth,icxbtc,icxusd,ethusd,ethbtc,etheth,btcicx,ethicx,icxicx"
    
    var exchangeInfoList = [String: ExchangeInfo]()
    var currentExchange: String = "usd"
    
    func getExchangeList() {
        var tracker: Tracker {
            switch Config.host {
            case .main:
                return Tracker.main()
                
            case .dev:
                return Tracker.dev()
                
            case .yeouido:
                return Tracker.local()
            }
        }
        
        guard let data = tracker.exchangeData(list: exchangeList) else { return }
        
        do {
            let decoder = JSONDecoder()
            let list = try decoder.decode([ExchangeInfo].self, from: data)
            
            for info in list {
                self.exchangeInfoList[info.tradeName] = info
            }
        } catch {
            
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("kNotificationExchangeListDidChanged"), object: nil)
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
