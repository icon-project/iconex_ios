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
        
        var under = wei as NSString
        while under.length > below {
            under = under.substring(to: under.length - 1) as NSString
        }
        while remove && under.hasSuffix("0") {
            under = under.substring(to: under.length - 1) as NSString
        }
        
        wei = under as String
        
        return wei == "" ? icx : icx + Tool.decimalSeparator + wei
    }
}
