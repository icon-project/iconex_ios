//
//  Decimal+Extension.swift
//  iconex_ios
//
//  Created by a1ahn on 06/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation

extension Decimal {
    var floatValue: Float {
        return NSDecimalNumber(decimal: self).floatValue
    }
    
    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }
}
