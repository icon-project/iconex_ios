//
//  Variables.swift
//  iconex_ios
//
//  Created by a1ahn on 18/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation

struct CONST {
    static let governance = "hx0000000000000000000000000000000000000000"
    static let scoreGovernance = "cx0000000000000000000000000000000000000001"
    
    enum METHOD: String {
        case getStepCosts
        case getMaxStepLimit
        case getMinStepLimit
        case getStepPrice
    }
}
