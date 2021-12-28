//
//  BigInt+Extension.swift
//  iconex_ios
//
//  Created by a1ahn on 19/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import BigInt

extension BigUInt {
    func toString(decimal: Int, _ under: Int = 0, _ remove: Bool = false) -> String {
        let total = self.quotientAndRemainder(dividingBy: BigUInt(10).power(decimal))
        let icx = String(total.quotient, radix: 10)
        var wei = String(total.remainder, radix: 10)
        
        while wei.count < decimal {
            wei = "0" + wei
        }
        
        var below = wei as NSString
        while below.length > under {
            below = below.substring(to: below.length - 1) as NSString
        }
        while remove && below.hasSuffix("0") {
            below = below.substring(to: below.length - 1) as NSString
        }
        
        wei = below as String
        
        return wei == "" ? icx : icx + Tool.decimalSeparator + wei
    }
    
    func exchange(from: String, to: String, decimal: Int = 18) -> BigUInt? {
        guard let rateString = Manager.exchange.exchangeInfoList[from+to],
            rateString.createDate != nil,
            let rate = rateString.price.bigUInt(decimal: decimal, fixed: true) else { return nil }
        
        return self * rate / BigUInt(10).power(decimal)
    }
}

extension BigUInt {
    var decimalNumber: Decimal? {
        return Decimal(string: self.toString(decimal: 0))
    }
}
